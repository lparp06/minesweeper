// -----------------------------------------------------------
// start_screen_renderer.v
// Synthesizable start screen with title and clean instructions
// -----------------------------------------------------------
module start_screen_renderer #(
    parameter SCALE       = 2,  // title scale
    parameter INSTR_SCALE = 1   // instruction scale
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        active_pixels,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    output reg  [23:0] color_out
);

    localparam SCREEN_W      = 640;
    localparam CHAR_WIDTH    = 8 * SCALE;
    localparam CHAR_HEIGHT   = 8 * SCALE;
    localparam CHAR_WIDTH_I  = 8 * INSTR_SCALE;
    localparam CHAR_HEIGHT_I = 8 * INSTR_SCALE;
    localparam LINE_SPACING  = 12;

    // -----------------------------
    // Title "MINESWEEPER"
    // -----------------------------
    localparam TITLE_LEN = 11;
    localparam TITLE_0  = 8'd77;  // M
    localparam TITLE_1  = 8'd73;  // I
    localparam TITLE_2  = 8'd78;  // N
    localparam TITLE_3  = 8'd69;  // E
    localparam TITLE_4  = 8'd83;  // S
    localparam TITLE_5  = 8'd87;  // W
    localparam TITLE_6  = 8'd69;  // E
    localparam TITLE_7  = 8'd69;  // E
    localparam TITLE_8  = 8'd80;  // P
    localparam TITLE_9  = 8'd69;  // E
    localparam TITLE_10 = 8'd82;  // R

    // -----------------------------
    // Instructions
    // -----------------------------
    // Line 0: KEY3: START
    localparam L0_LEN = 11;
    localparam L0_0  = 8'd75; localparam L0_1  = 8'd69; localparam L0_2  = 8'd89;
    localparam L0_3  = 8'd51; localparam L0_4  = 8'd58; localparam L0_5  = 8'd32;
    localparam L0_6  = 8'd83; localparam L0_7  = 8'd84; localparam L0_8  = 8'd65;
    localparam L0_9  = 8'd82; localparam L0_10 = 8'd84;

    // Line 1: LEFT UP DOWN RIGHT
    localparam L1_LEN = 18;
    localparam L1_0  = 8'd76; localparam L1_1  = 8'd69; localparam L1_2  = 8'd70;
    localparam L1_3  = 8'd84; localparam L1_4  = 8'd32; localparam L1_5  = 8'd85;
    localparam L1_6  = 8'd80; localparam L1_7  = 8'd32; localparam L1_8  = 8'd68;
    localparam L1_9  = 8'd79; localparam L1_10 = 8'd87; localparam L1_11 = 8'd78;
    localparam L1_12 = 8'd32; localparam L1_13 = 8'd82; localparam L1_14 = 8'd73;
    localparam L1_15 = 8'd71; localparam L1_16 = 8'd72; localparam L1_17 = 8'd84;

    // Line 2: FLAG SW9 REVEAL SW8
    localparam L2_LEN = 19;
    localparam L2_0  = 8'd70; localparam L2_1  = 8'd76; localparam L2_2  = 8'd65;
    localparam L2_3  = 8'd71; localparam L2_4  = 8'd32; localparam L2_5  = 8'd83;
    localparam L2_6  = 8'd87; localparam L2_7  = 8'd55; localparam L2_8  = 8'd32;
    localparam L2_9  = 8'd82; localparam L2_10 = 8'd69; localparam L2_11 = 8'd86;
    localparam L2_12 = 8'd69; localparam L2_13 = 8'd65; localparam L2_14 = 8'd76;
    localparam L2_15 = 8'd32; localparam L2_16 = 8'd83; localparam L2_17 = 8'd87;
    localparam L2_18 = 8'd56;

    // -----------------------------
    // Title rendering
    // -----------------------------
    wire [11:0] title_width = CHAR_WIDTH * TITLE_LEN;
    wire [11:0] title_x0    = SCREEN_W/2 - title_width/2;
    wire [11:0] title_y0    = 12'd50;

    wire signed [12:0] dx_title = $signed({1'b0,x}) - $signed(title_x0);
    wire signed [12:0] dy_title = $signed({1'b0,y}) - $signed(title_y0);

    wire title_in_rect = (dx_title >= 0) && (dx_title < $signed(title_width)) &&
                         (dy_title >= 0) && (dy_title < $signed(CHAR_HEIGHT));

    wire [11:0] title_x_local = title_in_rect ? dx_title[11:0] : 12'd0;
    wire [11:0] title_y_local = title_in_rect ? dy_title[11:0] : 12'd0;

    wire [3:0] title_char_index = title_x_local / CHAR_WIDTH;
    wire [2:0] font_row_title   = title_y_local / SCALE;
    wire [2:0] font_col_title   = (title_x_local % CHAR_WIDTH) / SCALE;

    reg [7:0] title_char_code;
    always @(*) begin
        case(title_char_index)
            0:  title_char_code = TITLE_0;  1:  title_char_code = TITLE_1;  2:  title_char_code = TITLE_2;
            3:  title_char_code = TITLE_3;  4:  title_char_code = TITLE_4;  5:  title_char_code = TITLE_5;
            6:  title_char_code = TITLE_6;  7:  title_char_code = TITLE_7;  8:  title_char_code = TITLE_8;
            9:  title_char_code = TITLE_9;  10: title_char_code = TITLE_10;
            default: title_char_code = 8'd32;
        endcase
    end

    wire [7:0] font_bits_title;
    font font_title(.char_code(title_char_code), .row(font_row_title), .bits(font_bits_title));
    wire title_pixel_on = title_in_rect ? font_bits_title[7 - font_col_title] : 1'b0;

    // -----------------------------
    // Instructions rendering
    // -----------------------------
    wire [11:0] instr0_x0 = SCREEN_W/2 - (L0_LEN*CHAR_WIDTH_I)/2;
    wire [11:0] instr1_x0 = SCREEN_W/2 - (L1_LEN*CHAR_WIDTH_I)/2;
    wire [11:0] instr2_x0 = SCREEN_W/2 - (L2_LEN*CHAR_WIDTH_I)/2;

    wire [11:0] instr0_y0 = 12'd120;
    wire [11:0] instr1_y0 = instr0_y0 + CHAR_HEIGHT_I + LINE_SPACING;
    wire [11:0] instr2_y0 = instr1_y0 + CHAR_HEIGHT_I + LINE_SPACING;

    wire signed [12:0] dx0 = $signed({1'b0,x}) - $signed(instr0_x0);
    wire signed [12:0] dy0 = $signed({1'b0,y}) - $signed(instr0_y0);
    wire in_line0 = (dx0 >= 0) && (dx0 < $signed(L0_LEN*CHAR_WIDTH_I)) &&
                    (dy0 >= 0) && (dy0 < $signed(CHAR_HEIGHT_I));

    wire signed [12:0] dx1 = $signed({1'b0,x}) - $signed(instr1_x0);
    wire signed [12:0] dy1 = $signed({1'b0,y}) - $signed(instr1_y0);
    wire in_line1 = (dx1 >= 0) && (dx1 < $signed(L1_LEN*CHAR_WIDTH_I)) &&
                    (dy1 >= 0) && (dy1 < $signed(CHAR_HEIGHT_I));

    wire signed [12:0] dx2 = $signed({1'b0,x}) - $signed(instr2_x0);
    wire signed [12:0] dy2 = $signed({1'b0,y}) - $signed(instr2_y0);
    wire in_line2 = (dx2 >= 0) && (dx2 < $signed(L2_LEN*CHAR_WIDTH_I)) &&
                    (dy2 >= 0) && (dy2 < $signed(CHAR_HEIGHT_I));

    wire [2:0] font_row_instr = in_line0 ? (dy0/INSTR_SCALE) :
                                in_line1 ? (dy1/INSTR_SCALE) :
                                in_line2 ? (dy2/INSTR_SCALE) : 3'd0;
    wire [2:0] font_col_instr = in_line0 ? ((dx0%CHAR_WIDTH_I)/INSTR_SCALE) :
                                in_line1 ? ((dx1%CHAR_WIDTH_I)/INSTR_SCALE) :
                                in_line2 ? ((dx2%CHAR_WIDTH_I)/INSTR_SCALE) : 3'd0;

    reg [7:0] instr_char_code;
    always @(*) begin
        instr_char_code = 8'd32;
        if (in_line0) begin
            case (dx0 / CHAR_WIDTH_I)
                0: instr_char_code = L0_0;  1: instr_char_code = L0_1;  2: instr_char_code = L0_2;
                3: instr_char_code = L0_3;  4: instr_char_code = L0_4;  5: instr_char_code = L0_5;
                6: instr_char_code = L0_6;  7: instr_char_code = L0_7;  8: instr_char_code = L0_8;
                9: instr_char_code = L0_9; 10: instr_char_code = L0_10;
                default: instr_char_code = 8'd32;
            endcase
        end else if (in_line1) begin
            case (dx1 / CHAR_WIDTH_I)
                0: instr_char_code = L1_0;  1: instr_char_code = L1_1;  2: instr_char_code = L1_2;
                3: instr_char_code = L1_3;  4: instr_char_code = L1_4;  5: instr_char_code = L1_5;
                6: instr_char_code = L1_6;  7: instr_char_code = L1_7;  8: instr_char_code = L1_8;
                9: instr_char_code = L1_9; 10: instr_char_code = L1_10; 11: instr_char_code = L1_11;
                12: instr_char_code = L1_12; 13: instr_char_code = L1_13; 14: instr_char_code = L1_14;
                15: instr_char_code = L1_15; 16: instr_char_code = L1_16; 17: instr_char_code = L1_17;
                default: instr_char_code = 8'd32;
            endcase
        end else if (in_line2) begin
            case (dx2 / CHAR_WIDTH_I)
                0: instr_char_code = L2_0;   1: instr_char_code = L2_1;   2: instr_char_code = L2_2;
                3: instr_char_code = L2_3;   4: instr_char_code = L2_4;   5: instr_char_code = L2_5;
                6: instr_char_code = L2_6;   7: instr_char_code = L2_7;   8: instr_char_code = L2_8;
                9: instr_char_code = L2_9;  10: instr_char_code = L2_10; 11: instr_char_code = L2_11;
                12: instr_char_code = L2_12; 13: instr_char_code = L2_13; 14: instr_char_code = L2_14;
                15: instr_char_code = L2_15; 16: instr_char_code = L2_16; 17: instr_char_code = L2_17;
                18: instr_char_code = L2_18;
                default: instr_char_code = 8'd32;
            endcase
        end
    end

    wire [7:0] font_bits_instr;
    font font_instr(.char_code(instr_char_code), .row(font_row_instr), .bits(font_bits_instr));
    wire instr_pixel_on = (in_line0 || in_line1 || in_line2) ? font_bits_instr[7 - font_col_instr] : 1'b0;

    // -----------------------------
    // Output
    // -----------------------------
    always @(*) begin
        if (!active_pixels)
            color_out = 24'h000000;
        else if (title_pixel_on)
            color_out = 24'hFFFFFF;
        else if (instr_pixel_on)
            color_out = 24'hE5E9E5;
        else
            color_out = 24'h78B97F; // background
    end

endmodule
