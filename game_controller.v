module game_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        active_pixels,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [3:0]  KEY,
    input  wire [9:0]  SW,
    output wire [23:0] color_out,
    output wire [5:0]  reveal_count,
    output reg         endgame,
    output reg         win
);

    // -------------------------------------------------------
    // Parameters (FIXED)
    // -------------------------------------------------------
    parameter NUM_TILES          = 5;
    parameter TOTAL_SQUARES      = NUM_TILES * NUM_TILES;
    parameter NUM_MINES          = 6;

    // -------------------------------------------------------
    // Mine map (25 bits for a 5×5 grid)
    // -------------------------------------------------------
    wire [TOTAL_SQUARES-1:0] mine_map = {
        5'b01000,
        5'b00011,
        5'b10000,
        5'b01100,
        5'b00000
    };

    // -------------------------------------------------------
    // Adjacency calculation via adj_fsm
    // -------------------------------------------------------
    wire [TOTAL_SQUARES*4-1:0] adj;
    wire adj_done;

    adj_fsm #(
        .GRID_SIZE(NUM_TILES)
    ) nums (
        .clk(clk),
        .rst(rst),
        .mine_map(mine_map),
        .adj(adj),
        .done(adj_done)
    );

    // -------------------------------------------------------
    // Rendering + tile reveal logic
    // -------------------------------------------------------
    wire mine_found;

    render #(
        .GRID_SIZE(NUM_TILES)
    ) board (
        .clk(clk),
        .rst(rst),
        .active_pixels(active_pixels),
        .x(x),
        .y(y),
        .keys(KEY),
        .mine_map(mine_map),
        .switches(SW),
        .adj(adj),
        .color_out(color_out),
        .reveal_count(reveal_count),
        .mine_found(mine_found)
    );

    // -------------------------------------------------------
    // Main game FSM (START → PLAYING → DONE)
    // -------------------------------------------------------
    localparam START   = 2'd0,
               PLAYING = 2'd1,
               DONE    = 2'd2;

    reg [1:0] S, NS;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            S <= START;
        else
            S <= NS;
    end

    always @(*) begin
        case (S)
            START:
                NS = start ? PLAYING : START;

            PLAYING:
                NS = (mine_found || (reveal_count == TOTAL_SQUARES - NUM_MINES))
                     ? DONE : PLAYING;

            DONE:
                NS = DONE;

            default:
                NS = START;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            endgame <= 0;
            win     <= 0;
        end
        else begin
            case (S)
                START, PLAYING: begin
                    endgame <= 0;
                    win     <= 0;
                end

                DONE: begin
                    endgame <= 1;
                    win     <= (reveal_count == TOTAL_SQUARES - NUM_MINES) &&
                               !mine_found;
                end
            endcase
        end
    end

endmodule
