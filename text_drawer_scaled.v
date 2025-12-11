// -----------------------------------------------------------
// text_drawer_scaled.v
// Synthesizable 8x8 font drawer with scaling
// -----------------------------------------------------------
module text_drawer_scaled #(
    parameter SCALE     = 2,
    parameter TITLE_LEN = 11
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire       active_pixels,
    output reg [23:0] color_out
);

    // -----------------------------------------
    // Title as packed vector (synthesizable)
    // -----------------------------------------
    localparam [8*TITLE_LEN-1:0] TITLE_VEC = {
        8'd77, // M
        8'd73, // I
        8'd78, // N
        8'd69, // E
        8'd83, // S
        8'd87, // W
        8'd69, // E
        8'd69, // E
        8'd80, // P
		  8'd69, // E
        8'd82  // R
    };

    localparam CHAR_WIDTH  = 8 * SCALE;
    localparam CHAR_HEIGHT = 8 * SCALE;
    localparam TITLE_WIDTH = CHAR_WIDTH * TITLE_LEN;

    // Center horizontally
    wire [9:0] x_in_title = x - (640/2 - TITLE_WIDTH/2);
    wire [9:0] y_in_title = y - 50; // vertical offset

    wire [3:0] char_index = x_in_title / CHAR_WIDTH;
    wire [2:0] font_row   = y_in_title / SCALE;
    wire [2:0] font_col   = (x_in_title % CHAR_WIDTH) / SCALE;

    // Get current character code
    wire [7:0] char_code;
    assign char_code = TITLE_VEC[8*(TITLE_LEN-1-char_index) +: 8];

    // Font lookup
    wire [7:0] font_bits;
    font font_i(
        .char_code(char_code),
        .row(font_row),
        .bits(font_bits)
    );

    wire pixel_on = font_bits[7 - font_col];

    always @(*) begin
        if (!active_pixels)
            color_out = 24'h000000;
        else if (x_in_title < TITLE_WIDTH && y_in_title < CHAR_HEIGHT)
            color_out = pixel_on ? 24'hFFFFFF : 24'h5E8F54; // white text on green
        else
            color_out = 24'h5E8F54; // background
    end

endmodule
