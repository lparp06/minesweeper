// -----------------------------------------------------------
// end_screen_renderer.v
// Synthesizable end screen for win/lose states
// -----------------------------------------------------------
module end_screen_renderer #(
    parameter SCALE = 2
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       active_pixels,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       win,          // 1 = win, 0 = lose
    output reg  [23:0] color_out
);

    localparam SCREEN_W    = 640;
    localparam CHAR_WIDTH  = 8 * SCALE;
    localparam CHAR_HEIGHT = 8 * SCALE;

    // -----------------------------
    // Messages
    // -----------------------------
    // Line 0: "YOU WIN" or "YOU LOSE"
    localparam WIN_LEN  = 7;
    localparam LOSE_LEN = 8;

    // ASCII codes for "YOU WIN"
    localparam WIN_0 = 8'd89; // Y
    localparam WIN_1 = 8'd79; // O
    localparam WIN_2 = 8'd85; // U
    localparam WIN_3 = 8'd32; // space
    localparam WIN_4 = 8'd87; // W
    localparam WIN_5 = 8'd73; // I
    localparam WIN_6 = 8'd78; // N

    // ASCII codes for "YOU LOSE"
    localparam LOSE_0 = 8'd89; // Y
    localparam LOSE_1 = 8'd79; // O
    localparam LOSE_2 = 8'd85; // U
    localparam LOSE_3 = 8'd32; // space
    localparam LOSE_4 = 8'd76; // L
    localparam LOSE_5 = 8'd79; // O
    localparam LOSE_6 = 8'd83; // S
    localparam LOSE_7 = 8'd69; // E

    // Line 1: "KEY3: RESET"
    localparam RESET_LEN = 11;
    localparam R0  = 8'd75; // K
    localparam R1  = 8'd69; // E
    localparam R2  = 8'd89; // Y
    localparam R3  = 8'd51; // '2'
    localparam R4  = 8'd58; // ':'
    localparam R5  = 8'd32; // space
    localparam R6  = 8'd82; // R
    localparam R7  = 8'd69; // E
    localparam R8  = 8'd83; // S
    localparam R9  = 8'd69; // E
    localparam R10 = 8'd84; // T

    // -----------------------------
    // Rendering
    // -----------------------------
    wire [11:0] msg_width  = (win ? WIN_LEN : LOSE_LEN) * CHAR_WIDTH;
    wire [11:0] reset_width = RESET_LEN * CHAR_WIDTH;

    wire [11:0] msg_x0   = SCREEN_W/2 - msg_width/2;
    wire [11:0] reset_x0 = SCREEN_W/2 - reset_width/2;

    wire [11:0] msg_y0   = 12'd150;
    wire [11:0] reset_y0 = msg_y0 + CHAR_HEIGHT + 12'd20;

    // Bounds
    wire signed [12:0] dx_msg   = $signed({1'b0,x}) - $signed(msg_x0);
    wire signed [12:0] dy_msg   = $signed({1'b0,y}) - $signed(msg_y0);
    wire in_msg = (dx_msg >= 0) && (dx_msg < $signed(msg_width)) &&
                  (dy_msg >= 0) && (dy_msg < $signed(CHAR_HEIGHT));

    wire signed [12:0] dx_reset = $signed({1'b0,x}) - $signed(reset_x0);
    wire signed [12:0] dy_reset = $signed({1'b0,y}) - $signed(reset_y0);
    wire in_reset = (dx_reset >= 0) && (dx_reset < $signed(reset_width)) &&
                    (dy_reset >= 0) && (dy_reset < $signed(CHAR_HEIGHT));

    reg [7:0] char_code;
    wire [2:0] font_row = in_msg   ? (dy_msg / SCALE) :
                          in_reset ? (dy_reset / SCALE) : 3'd0;
    wire [2:0] font_col = in_msg   ? ((dx_msg % CHAR_WIDTH) / SCALE) :
                          in_reset ? ((dx_reset % CHAR_WIDTH) / SCALE) : 3'd0;

    always @(*) begin
        char_code = 8'd32;
        if (in_msg) begin
            case (dx_msg / CHAR_WIDTH)
                0: char_code = win ? WIN_0 : LOSE_0;
                1: char_code = win ? WIN_1 : LOSE_1;
                2: char_code = win ? WIN_2 : LOSE_2;
                3: char_code = win ? WIN_3 : LOSE_3;
                4: char_code = win ? WIN_4 : LOSE_4;
                5: char_code = win ? WIN_5 : LOSE_5;
                6: char_code = win ? WIN_6 : LOSE_6;
                7: if (!win) char_code = LOSE_7;
                default: char_code = 8'd32;
            endcase
        end else if (in_reset) begin
            case (dx_reset / CHAR_WIDTH)
                0: char_code = R0;  1: char_code = R1;  2: char_code = R2;
                3: char_code = R3;  4: char_code = R4;  5: char_code = R5;
                6: char_code = R6;  7: char_code = R7;  8: char_code = R8;
                9: char_code = R9;  10: char_code = R10;
                default: char_code = 8'd32;
            endcase
        end
    end

    wire [7:0] font_bits;
    font font_i(
        .char_code(char_code),
        .row(font_row),
        .bits(font_bits)
    );

    wire pixel_on = (in_msg || in_reset) ? font_bits[7 - font_col] : 1'b0;

    // -----------------------------
    // Output
    // -----------------------------
    always @(*) begin
        if (!active_pixels)
            color_out = 24'h000000;
        else if (pixel_on)
            color_out = win ? 24'h00FF00 : 24'hFF0000; // green for win, red for lose
        else
            color_out = 24'h000000; // background black
    end

endmodule
