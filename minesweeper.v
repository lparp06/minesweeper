// -----------------------------------------------------------
// minesweeper.v - Top-level Minesweeper with start and end screens
// -----------------------------------------------------------
module minesweeper (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [9:0]  SW,
    output wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output wire        VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS,
    output reg  [7:0]  VGA_R, VGA_G, VGA_B
);

    // -----------------------------
    // Clock & resets
    // -----------------------------
    wire clk       = CLOCK_50;
    wire hard_rst  = SW[0];       // global hard reset, active-high
    wire start_btn = ~KEY[3];     // start button
    wire rst_n     = ~hard_rst;   // global active-low reset

    // -----------------------------
    // FSM: START, PLAYING, DONE
    // -----------------------------
    localparam START   = 2'd0,
               PLAYING = 2'd1,
               DONE    = 2'd2;

    reg [1:0] S, NS;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            S <= START;
        else
            S <= NS;
    end

    always @(*) begin
        case (S)
            START:   NS = start_btn ? PLAYING : START;
            PLAYING: NS = (endgame) ? DONE : PLAYING;
            DONE:    NS = (done_reset) ? START : DONE;
            default: NS = START;
        endcase
    end

    // -----------------------------
    // Conditional reset at DONE
    // -----------------------------
    wire done_reset = (S == DONE) & ~KEY[3];  // KEY[3] active-low
    wire game_rst_n = ~hard_rst & ~done_reset; // combine with SW0 reset

    // -----------------------------
    // VGA signals
    // -----------------------------
    wire active_pixels;
    wire [9:0] x, y;

    vga_driver the_vga(
        .clk(clk),
        .rst(rst_n),
        .vga_clk(VGA_CLK),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .active_pixels(active_pixels),
        .xPixel(x),
        .yPixel(y),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N)
    );

    // -----------------------------
    // Game signals
    // -----------------------------
    wire [23:0] color_out_game;
    wire [5:0]  reveal_count, flag_count;
    wire        endgame, win;

    game_controller game (
        .clk(clk),
        .rst(game_rst_n),       // active-low reset
        .start(start_btn),
        .active_pixels(active_pixels),
        .x(x),
        .y(y),
        .KEY(KEY),
        .SW(SW),
        .color_out(color_out_game),
        .reveal_count(reveal_count),
        .flag_count(flag_count),
        .endgame(endgame),
        .win(win)
    );

    // -----------------------------
    // Start screen renderer
    // -----------------------------
    wire [23:0] color_out_start;
    start_screen_renderer start_screen (
        .clk(clk),
        .rst(rst_n),
        .active_pixels(active_pixels),
        .x(x),
        .y(y),
        .color_out(color_out_start)
    );

    // -----------------------------
    // End screen renderer (YOU WIN/LOSE)
    // -----------------------------
    wire [23:0] color_out_end;
    end_screen_renderer end_screen (
        .clk(clk),
        .rst(rst_n),
        .active_pixels(active_pixels),
        .x(x),
        .y(y),
        .win(win),
        .color_out(color_out_end)
    );

    // -----------------------------
    // Screen output mux
    // -----------------------------
    reg [23:0] screen_out;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            screen_out <= 24'h000000;
        else case (S)
            START:   screen_out <= color_out_start;
            PLAYING: screen_out <= color_out_game;
            DONE:    screen_out <= color_out_end;
            default: screen_out <= 24'h000000;
        endcase
    end

    always @(*) begin
        {VGA_R, VGA_G, VGA_B} = screen_out;
    end

    // -----------------------------
    // Seven-segment displays
    // -----------------------------
    wire [6:0] tens_dig, ones_dig, flag_t_dig, flag_o_dig;

    seven_segment ones (reveal_count % 10, ones_dig);
    seven_segment tens (reveal_count / 10, tens_dig);

    seven_segment flag_ones (flag_count % 10, flag_o_dig);
    seven_segment flag_tens (flag_count / 10, flag_t_dig);

    assign HEX0 = ones_dig;
    assign HEX1 = tens_dig;
    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;
    assign HEX4 = flag_o_dig;
    assign HEX5 = flag_t_dig;

endmodule
