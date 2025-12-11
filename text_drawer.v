module text_drawer #(
    parameter TEXT = "",
    parameter X_CENTER = 320,
    parameter Y_TOP = 200
)(
    input [9:0] x, y,
    output reg pixel_on
);

    localparam CHAR_W = 8;
    localparam CHAR_H = 8;
    localparam LEN = $size(TEXT);

    wire [9:0] total_width = LEN * CHAR_W;
    wire [9:0] x0 = X_CENTER - (total_width >> 1);

    integer idx;
    reg [7:0] charcode;
    wire [7:0] font_row;

    // Pixel within text block
    wire inside =
        x >= x0 &&
        x <  x0 + total_width &&
        y >= Y_TOP &&
        y <  Y_TOP + CHAR_H;

    assign row = y - Y_TOP;
    assign col = x - x0;

    always @(*) begin
        pixel_on = 0;
        if (!inside) begin
            pixel_on = 0;
        end else begin
            idx = col / CHAR_W;
            charcode = TEXT[idx*8 +: 8];
        end
    end

    font8x8 font (
        .char(charcode),
        .row(row[2:0]),
        .bits(font_row)
    );

    always @(*) begin
        if (inside)
            pixel_on = font_row[7 - (col % CHAR_W)];
    end

endmodule
