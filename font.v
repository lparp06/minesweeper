// -----------------------------------------------------------
// 8×8 FONT: 0–9, A–Z, FLAG
// -----------------------------------------------------------
module font (
    input  wire [7:0] char_code,
    input  wire [2:0] row,
    output reg  [7:0] bits
);

always @(*) begin
    case(char_code)

    // =======================================================
    // DIGITS 0–9 (ASCII 48–57)
    // =======================================================
    8'd48: case(row) // '0'
        0: bits=8'b00111100;
        1: bits=8'b01100110;
        2: bits=8'b01101110;
        3: bits=8'b01110110;
        4: bits=8'b01100110;
        5: bits=8'b01100110;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

    8'd49: case(row) // '1'
        0: bits=8'b00011000;
        1: bits=8'b00111000;
        2: bits=8'b00011000;
        3: bits=8'b00011000;
        4: bits=8'b00011000;
        5: bits=8'b00011000;
        6: bits=8'b01111110;
        7: bits=8'b00000000;
    endcase

    8'd50: case(row) // '2'
        0: bits=8'b00111100;
        1: bits=8'b01100110;
        2: bits=8'b00000110;
        3: bits=8'b00011100;
        4: bits=8'b00110000;
        5: bits=8'b01100000;
        6: bits=8'b01111110;
        7: bits=8'b00000000;
    endcase

    8'd51: case(row) // '3'
        0: bits=8'b00111100;
        1: bits=8'b01100110;
        2: bits=8'b00000110;
        3: bits=8'b00011100;
        4: bits=8'b00000110;
        5: bits=8'b01100110;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

    8'd52: case(row) // '4'
        0: bits=8'b00001100;
        1: bits=8'b00011100;
        2: bits=8'b00101100;
        3: bits=8'b01001100;
        4: bits=8'b01111110;
        5: bits=8'b00001100;
        6: bits=8'b00001100;
        7: bits=8'b00000000;
    endcase

    8'd53: case(row) // '5'
        0: bits=8'b01111110;
        1: bits=8'b01100000;
        2: bits=8'b01111100;
        3: bits=8'b00000110;
        4: bits=8'b00000110;
        5: bits=8'b01100110;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

    8'd54: case(row) // '6'
        0: bits=8'b00111100;
        1: bits=8'b01100110;
        2: bits=8'b01100000;
        3: bits=8'b01111100;
        4: bits=8'b01100110;
        5: bits=8'b01100110;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

    8'd55: case(row) // '7'
        0: bits=8'b01111110;
        1: bits=8'b01100110;
        2: bits=8'b00001100;
        3: bits=8'b00011000;
        4: bits=8'b00011000;
        5: bits=8'b00011000;
        6: bits=8'b00011000;
        7: bits=8'b00000000;
    endcase

    8'd56: case(row) // '8'
        0: bits=8'b00111100;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b00111100;
        4: bits=8'b01100110;
        5: bits=8'b01100110;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

    8'd57: case(row) // '9'
        0: bits=8'b00111100;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b00111110;
        4: bits=8'b00000110;
        5: bits=8'b01100110;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

	 8'd58: case(row) // :
		0: bits=8'b00000000;
      1: bits=8'b00000000;
      2: bits=8'b00010000;
      3: bits=8'b00010000;
      4: bits=8'b00000000;
      5: bits=8'b00010000;
      6: bits=8'b00010000;
      7: bits=8'b00000000;
   endcase
    // =======================================================
    // UPPERCASE A–Z (ASCII 65–90)
    // 8×8 block font (consistent with digits above)
    // =======================================================

    8'd65: case(row) // A
        0: bits=8'b00011000;
        1: bits=8'b00111100;
        2: bits=8'b01100110;
        3: bits=8'b01100110;
        4: bits=8'b01111110;
        5: bits=8'b01100110;
        6: bits=8'b01100110;
        7: bits=8'b00000000;
    endcase

    8'd66: case(row) // B
        0: bits=8'b01111100;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b01111100;
        4: bits=8'b01100110;
        5: bits=8'b01100110;
        6: bits=8'b01111100;
        7: bits=8'b00000000;
    endcase

    8'd67: case(row) // C
        0: bits=8'b00111100;
        1: bits=8'b01100110;
        2: bits=8'b01100000;
        3: bits=8'b01100000;
        4: bits=8'b01100000;
        5: bits=8'b01100110;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

    8'd68: case(row) // D
        0: bits=8'b01111000;
        1: bits=8'b01101100;
        2: bits=8'b01100110;
        3: bits=8'b01100110;
        4: bits=8'b01100110;
        5: bits=8'b01101100;
        6: bits=8'b01111000;
        7: bits=8'b00000000;
    endcase

    8'd69: case(row) // E
        0: bits=8'b01111110;
        1: bits=8'b01100000;
        2: bits=8'b01100000;
        3: bits=8'b01111100;
        4: bits=8'b01100000;
        5: bits=8'b01100000;
        6: bits=8'b01111110;
        7: bits=8'b00000000;
    endcase

    8'd70: case(row) // F
        0: bits=8'b01111110;
        1: bits=8'b01100000;
        2: bits=8'b01100000;
        3: bits=8'b01111100;
        4: bits=8'b01100000;
        5: bits=8'b01100000;
        6: bits=8'b01100000;
        7: bits=8'b00000000;
    endcase

    8'd71: case(row) // G
        0: bits=8'b00111100;
        1: bits=8'b01100110;
        2: bits=8'b01100000;
        3: bits=8'b01101110;
        4: bits=8'b01100110;
        5: bits=8'b01100110;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

    8'd72: case(row) // H
        0: bits=8'b01100110;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b01111110;
        4: bits=8'b01100110;
        5: bits=8'b01100110;
        6: bits=8'b01100110;
        7: bits=8'b00000000;
    endcase

    8'd73: case(row) // I
        0: bits=8'b00111100;
        1: bits=8'b00011000;
        2: bits=8'b00011000;
        3: bits=8'b00011000;
        4: bits=8'b00011000;
        5: bits=8'b00011000;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

    8'd74: case(row) // J
        0: bits=8'b00011110;
        1: bits=8'b00001100;
        2: bits=8'b00001100;
        3: bits=8'b00001100;
        4: bits=8'b01101100;
        5: bits=8'b01101100;
        6: bits=8'b00111000;
        7: bits=8'b00000000;
    endcase

    8'd75: case(row) // K
        0: bits=8'b01100110;
        1: bits=8'b01101100;
        2: bits=8'b01111000;
        3: bits=8'b01110000;
        4: bits=8'b01111000;
        5: bits=8'b01101100;
        6: bits=8'b01100110;
        7: bits=8'b00000000;
    endcase

    8'd76: case(row) // L
        0: bits=8'b01100000;
        1: bits=8'b01100000;
        2: bits=8'b01100000;
        3: bits=8'b01100000;
        4: bits=8'b01100000;
        5: bits=8'b01100000;
        6: bits=8'b01111110;
        7: bits=8'b00000000;
    endcase

    8'd77: case(row) // M
        0: bits=8'b01100110;
        1: bits=8'b01111110;
        2: bits=8'b01111110;
        3: bits=8'b01100110;
        4: bits=8'b01100110;
        5: bits=8'b01100110;
        6: bits=8'b01100110;
        7: bits=8'b00000000;
    endcase

    8'd78: case(row) // N
        0: bits=8'b01100110;
        1: bits=8'b01110110;
        2: bits=8'b01111110;
        3: bits=8'b01101110;
        4: bits=8'b01100110;
        5: bits=8'b01100110;
        6: bits=8'b01100110;
        7: bits=8'b00000000;
    endcase

    8'd79: case(row) // O
        0: bits=8'b00111100;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b01100110;
        4: bits=8'b01100110;
        5: bits=8'b01100110;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

    8'd80: case(row) // P
        0: bits=8'b01111100;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b01111100;
        4: bits=8'b01100000;
        5: bits=8'b01100000;
        6: bits=8'b01100000;
        7: bits=8'b00000000;
    endcase

    8'd81: case(row) // Q
        0: bits=8'b00111100;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b01100110;
        4: bits=8'b01110110;
        5: bits=8'b01101100;
        6: bits=8'b00111110;
        7: bits=8'b00000000;
    endcase

    8'd82: case(row) // R
        0: bits=8'b01111100;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b01111100;
        4: bits=8'b01111000;
        5: bits=8'b01101100;
        6: bits=8'b01100110;
        7: bits=8'b00000000;
    endcase

    8'd83: case(row) // S
        0: bits=8'b00111110;
        1: bits=8'b01100000;
        2: bits=8'b01100000;
        3: bits=8'b00111100;
        4: bits=8'b00000110;
        5: bits=8'b00000110;
        6: bits=8'b01111100;
        7: bits=8'b00000000;
    endcase

    8'd84: case(row) // T
        0: bits=8'b01111110;
        1: bits=8'b00011000;
        2: bits=8'b00011000;
        3: bits=8'b00011000;
        4: bits=8'b00011000;
        5: bits=8'b00011000;
        6: bits=8'b00011000;
        7: bits=8'b00000000;
    endcase

    8'd85: case(row) // U
        0: bits=8'b01100110;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b01100110;
        4: bits=8'b01100110;
        5: bits=8'b01100110;
        6: bits=8'b00111100;
        7: bits=8'b00000000;
    endcase

    8'd86: case(row) // V
        0: bits=8'b01100110;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b00111100;
        4: bits=8'b00011000;
        5: bits=8'b00011000;
        6: bits=8'b00011000;
        7: bits=8'b00000000;
    endcase

    8'd87: case(row) // W
        0: bits=8'b01100110;
        1: bits=8'b01100110;
        2: bits=8'b01100110;
        3: bits=8'b01111110;
        4: bits=8'b01111110;
        5: bits=8'b01100110;
        6: bits=8'b01100110;
        7: bits=8'b00000000;
    endcase

    8'd88: case(row) // X
        0: bits=8'b01100110;
        1: bits=8'b00111100;
        2: bits=8'b00011000;
        3: bits=8'b00011000;
        4: bits=8'b00011000;
        5: bits=8'b00111100;
        6: bits=8'b01100110;
        7: bits=8'b00000000;
    endcase

    8'd89: case(row) // Y
        0: bits=8'b01100110;
        1: bits=8'b00111100;
        2: bits=8'b00011000;
        3: bits=8'b00011000;
        4: bits=8'b00011000;
        5: bits=8'b00011000;
        6: bits=8'b00011000;
        7: bits=8'b00000000;
    endcase

    8'd90: case(row) // Z
        0: bits=8'b01111110;
        1: bits=8'b00000110;
        2: bits=8'b00001100;
        3: bits=8'b00011000;
        4: bits=8'b00110000;
        5: bits=8'b01100000;
        6: bits=8'b01111110;
        7: bits=8'b00000000;
    endcase


    // =======================================================
    // FLAG GLYPH (Custom code 200)
    // =======================================================
    8'd200: case(row)
        0: bits=8'b00011100;
        1: bits=8'b00111110;
        2: bits=8'b00111110;
        3: bits=8'b00011100;
        4: bits=8'b00011100;
        5: bits=8'b00011100;
        6: bits=8'b00011100;
        7: bits=8'b00000000;
    endcase


    // =======================================================
    // DEFAULT
    // =======================================================
    default: bits = 8'b00000000;

    endcase

end

endmodule
