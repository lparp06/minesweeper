module tile_color(
	input wire [3:0] count,
	output reg [23:0] color
);

	always @ (*) begin
		case (count) 
			4'd0: color = 24'hFFFFFF; // white
			4'd1: color = 24'hFF0000; // red
			4'd2: color = 24'hFF6F00; // orange
			4'd3: color = 24'h2FFF00; // lime green
			4'd4: color = 24'h00FFE1; // cyan
			4'd5: color = 24'h00B3FF; // blue
			4'd6: color = 24'h9382C2; // purple
			4'd7: color = 24'hFF00EE; // pink
			4'd8: color = 24'hDEFF00;
			default: color = 24'hA6A6A6;
		endcase
	end

endmodule
	