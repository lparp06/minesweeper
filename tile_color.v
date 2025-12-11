// -----------------------------------------------------------
// tile_color.v - maps adjacency count to ASCII and RGB color
// -----------------------------------------------------------
module tile_color(
    input  wire [3:0] count,
    output reg  [7:0] char_code,   // ASCII code for '1'..'8' or ' ' for 0
    output reg  [23:0] color       // RGB color for drawing the digit
);

    always @(*) begin
        case (count)
            4'd0: begin char_code = 8'd32; color = 24'hFFFFFF; end // space
            4'd1: begin char_code = 8'd49; color = 24'h0000FF; end // blue
            4'd2: begin char_code = 8'd50; color = 24'h008000; end // green
            4'd3: begin char_code = 8'd51; color = 24'hFF0000; end // red
            4'd4: begin char_code = 8'd52; color = 24'h000080; end // dark blue
            4'd5: begin char_code = 8'd53; color = 24'h800000; end // dark red
            4'd6: begin char_code = 8'd54; color = 24'h008080; end // teal
            4'd7: begin char_code = 8'd55; color = 24'h000000; end // black
            4'd8: begin char_code = 8'd56; color = 24'h808080; end // gray
            default: begin char_code = 8'd32; color = 24'hFFFFFF; end
        endcase
    end

endmodule
