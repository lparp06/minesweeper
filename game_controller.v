module game_controller (
    input  wire        clk,
    input  wire        rst,             // active-low
    input  wire        start,           // begin a new game (go to WAIT_CLICK)
    input  wire        active_pixels,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [3:0]  KEY,
    input  wire [9:0]  SW,
    output wire [23:0] color_out,
    output wire [5:0]  reveal_count,    // for 8x8, 64 -> needs 6 bits
    output reg         endgame,
    output reg         win
);

    // -------------------------------------------------------
    // Parameters
    // -------------------------------------------------------
    parameter NUM_TILES     = 8;
    parameter TOTAL_SQUARES = NUM_TILES * NUM_TILES;
    parameter NUM_MINES     = 10;
    localparam INDEX_BITS   = $clog2(TOTAL_SQUARES);

    // -------------------------------------------------------
    // Internal wires between submodules
    // -------------------------------------------------------
    wire [TOTAL_SQUARES-1:0] mine_map;
    wire                     mines_done;

    wire [TOTAL_SQUARES*4-1:0] adj;
    wire                      adj_done_pulse; // one-cycle done pulse from adj_fsm

    wire                      render_first_click; // pulse from render on first reveal
    wire [INDEX_BITS-1:0]     render_start_index;
    wire                      render_mine_found;
    // reveal_count and color_out are outputs from render
    // (already declared as outputs of top-level)

    // single-cycle pulse from controller to adj_fsm to start adjacency calculation
    reg adj_start_pulse;

    // -------------------------------------------------------
    // Instantiate random mine generator
    // (it latches the first_click and root index)
    // -------------------------------------------------------
    random_mine_generator #(
        .GRID_SIZE(NUM_TILES),
        .TOTAL_TILES(TOTAL_SQUARES),
        .INDEX_BITS(INDEX_BITS),
        .NUM_MINES(NUM_MINES)
    ) mine_gen (
        .clk(clk),
        .rst(rst),
        .first_click(render_first_click),    // pulse from render when player reveals first tile
        .root_index(render_start_index),
        .mine_map(mine_map),
        .done(mines_done)
    );
    // adj_fsm instance (starts on adj_start_pulse, returns a one-cycle done_pulse)
		adj_fsm #(
		 .GRID_SIZE(NUM_TILES)
	) adj_gen (
		 .clk(clk),
		 .rst(rst),
		 .start(adj_start_pulse),   // <-- NEW start pulse
		 .mine_map(mine_map),
		 .adj(adj),
		 .done(adj_done_pulse)      // <-- same name as your controller FSM uses
	);

    // render instance (uses .start and .start_index outputs for first-click)
    render #(
        .GRID_SIZE(NUM_TILES)
    ) board (
        .clk(clk),
        .rst(rst),
        .active_pixels(active_pixels),
        .x(x),
        .y(y),
        .keys(KEY),
        .switches(SW),
        .mine_map(mine_map),
        .adj(adj),
        .color_out(color_out),
        .start(render_first_click),         // pulse for first click (was 'first_click' in older code)
        .start_index(render_start_index),   // index of first clicked tile
        .reveal_count(reveal_count),
        .mine_found(render_mine_found)
    );

    // -------------------------------------------------------
    // Top-level FSM
    // -------------------------------------------------------
    localparam START            = 3'd0,
               WAIT_CLICK       = 3'd1,
               GENERATE_MAP     = 3'd2,
               GENERATE_ADJ     = 3'd3,
               PLAY             = 3'd4,
               DONE             = 3'd5;

    reg [2:0] S, NS;

    // State register
    always @(posedge clk or negedge rst) begin
        if (!rst) S <= START;
        else      S <= NS;
    end

    // Next-state combinational
    always @(*) begin
        // default
        NS = S;

        case (S)
            START: NS = start ? WAIT_CLICK : START;

            WAIT_CLICK: begin
                // wait for player to reveal first tile (render asserts first_click)
                if (render_first_click) NS = GENERATE_MAP;
                else NS = WAIT_CLICK;
            end

            GENERATE_MAP: begin
                // wait for mine placement to finish
                if (mines_done) NS = GENERATE_ADJ;
                else NS = GENERATE_MAP;
            end

            GENERATE_ADJ: begin
                // wait for adjacency generator to complete
                if (adj_done_pulse) NS = PLAY;
                else NS = GENERATE_ADJ;
            end

            PLAY: begin
                if (render_mine_found || (reveal_count == TOTAL_SQUARES - NUM_MINES)) NS = DONE;
                else NS = PLAY;
            end

            DONE: NS = DONE; // sticky; can add restart logic later

            default: NS = START;
        endcase
    end

    // -------------------------------------------------------
    // Control signals and pulses
    // -------------------------------------------------------
    // adj_start_pulse should be asserted for one clock when entering GENERATE_ADJ
    reg adj_start_q;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            adj_start_pulse <= 1'b0;
            adj_start_q <= 1'b0;
        end else begin
            // detect entry to GENERATE_ADJ
            adj_start_pulse <= (S == GENERATE_MAP) && (NS == GENERATE_ADJ);
            adj_start_q <= adj_start_pulse;
        end
    end

    // -------------------------------------------------------
    // Outputs: endgame & win
    // -------------------------------------------------------
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            endgame <= 1'b0;
            win     <= 1'b0;
        end else begin
            case (S)
                DONE: begin
                    endgame <= 1'b1;
                    win     <= (reveal_count == TOTAL_SQUARES - NUM_MINES) && !render_mine_found;
                end
                default: begin
                    endgame <= 1'b0;
                    win     <= 1'b0;
                end
            endcase
        end
    end

endmodule
