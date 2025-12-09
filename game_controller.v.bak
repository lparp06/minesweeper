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
    output reg         endgame,
    output reg         win
);


    // *** Mine map lives here ***
    // Example: 1 = mine, 0 = safe
    wire [63:0] mine_map = {
    8'b00110000,
    8'b00001110,
    8'b00010000,
    8'b00000010,
    8'b00000000,
    8'b10000000,
    8'b00001000,
    8'b00000100
	};

    // *** Adjacency counts live here too ***
    wire [255:0] adj;
    adj_fsm nums (
        .clk(clk),
        .rst(rst),
        .mine_map(mine_map),
        .adj(adj)
    );

    wire [5:0] reveal_count;
    wire       mine_found;

    render board (
        .clk(clk), .rst(rst),
        .active_pixels(active_pixels),
        .x(x), .y(y),
        .keys(KEY),
        .mine_map(mine_map),
        .switches(SW),
        .adj(adj),
        .color_out(color_out),
        .reveal_count(reveal_count),
        .mine_found(mine_found)
    );

    // FSM for win/lose
    localparam START=0, PLAYING=1, DONE=2;
    reg [1:0] S, NS;
    always @(posedge clk or negedge rst) S <= !rst ? START : NS;
    always @(*) begin
        case(S)
            START:   NS = start ? PLAYING : START;
            PLAYING: NS = (mine_found || (reveal_count==6'd54)) ? DONE : PLAYING;
            DONE:    NS = DONE;
            default: NS = START;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin endgame<=0; win<=0; end
        else case(S)
            START,PLAYING: begin endgame<=0; win<=0; end
            DONE: begin
                endgame<=1;
                win <= (reveal_count==6'd54) && !mine_found;
            end
        endcase
    end
endmodule
