// -----------------------------------------------------------
// game_controller.v - Minesweeper top-level controller
// -----------------------------------------------------------
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
    output wire [5:0]  flag_count,      // for 8x8, 64 -> needs 6 bits
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
    wire                       adj_done_pulse;

    wire                       render_first_click;
    wire [INDEX_BITS-1:0]      render_start_index;
    wire                       render_mine_found;

    reg  [INDEX_BITS-1:0]      first_click_index;
    reg                        first_click_seen;

    // -------------------------------------------------------
    // FSM states
    // -------------------------------------------------------
    localparam START        = 3'd0,
               WAIT_CLICK   = 3'd1,
               GENERATE_MAP = 3'd2,
               GENERATE_ADJ = 3'd3,
               PLAY         = 3'd4,
               DONE         = 3'd5;

    reg [2:0] S, NS;

    // State register
    always @(posedge clk or negedge rst) begin
        if (!rst) S <= START;
        else      S <= NS;
    end

    // Next-state logic
    always @(*) begin
        NS = S;
        case (S)
            START:       NS = start ? WAIT_CLICK : START;
            WAIT_CLICK:  NS = render_first_click ? GENERATE_MAP : WAIT_CLICK;
            GENERATE_MAP: NS = mines_done ? GENERATE_ADJ : GENERATE_MAP;
            GENERATE_ADJ: NS = adj_done_pulse ? PLAY : GENERATE_ADJ;
            PLAY:        NS = (render_mine_found || (reveal_count == TOTAL_SQUARES - NUM_MINES)) ? DONE : PLAY;
            DONE:        NS = DONE;
            default:     NS = START;
        endcase
    end

    // -------------------------------------------------------
    // State-entry pulses
    // -------------------------------------------------------
    wire enter_GENERATE_MAP = (S != GENERATE_MAP) && (NS == GENERATE_MAP);
    wire enter_GENERATE_ADJ = (S != GENERATE_ADJ) && (NS == GENERATE_ADJ);

    // -------------------------------------------------------
    // Latch first click for safe mine placement
    // -------------------------------------------------------
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            first_click_seen  <= 1'b0;
            first_click_index <= {INDEX_BITS{1'b0}};
        end else if (S == WAIT_CLICK && render_first_click) begin
            first_click_seen  <= 1'b1;
            first_click_index <= render_start_index;
        end
    end

    // -------------------------------------------------------
    // Random mine generator
    // -------------------------------------------------------
    random_mine_generator #(
        .GRID_SIZE(NUM_TILES),
        .TOTAL_TILES(TOTAL_SQUARES),
        .INDEX_BITS(INDEX_BITS),
        .NUM_MINES(NUM_MINES)
    ) mine_gen (
        .clk(clk),
        .rst(rst),
        .first_click(enter_GENERATE_MAP), // one-cycle pulse
        .root_index(first_click_index),   // safe tile
        .mine_map(mine_map),
        .done(mines_done)
    );

    // -------------------------------------------------------
    // Adjacency generator FSM
    // -------------------------------------------------------
    reg adj_start_pulse;
    always @(posedge clk or negedge rst) begin
        if (!rst) adj_start_pulse <= 1'b0;
        else      adj_start_pulse <= enter_GENERATE_ADJ;
    end

    adj_fsm #(
        .GRID_SIZE(NUM_TILES)
    ) adj_gen (
        .clk(clk),
        .rst(rst),
        .start(adj_start_pulse),
        .mine_map(mine_map),
        .adj(adj),
        .done(adj_done_pulse)
    );

    // -------------------------------------------------------
    // Render module
    // -------------------------------------------------------
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
        .game_ready(S == PLAY),
        .color_out(color_out),
        .start(render_first_click),
        .start_index(render_start_index),
        .reveal_count(reveal_count),
        .flag_count(flag_count),
        .mine_found(render_mine_found)
    );

    // -------------------------------------------------------
    // Endgame & win outputs
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
