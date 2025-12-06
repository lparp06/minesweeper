module adj_fsm(
	input wire clk,
	input wire rst,
	input wire [63:0] mine_map,
	output reg [255:0]adj,
	output reg done);
	
reg [1:0]S;
reg [1:0]NS;

parameter IDLE = 2'd0,
			 NEXT_TILE = 2'd1,
			 DONE = 2'd2;
			 
reg [5:0] tile_index;
wire [3:0] tile_count;

neighbor_check nc (
						 .tile_index(tile_index),
						 .mine_map(mine_map),
						 .count(tile_count));

always @ (posedge clk or negedge rst) begin
	if (rst == 1'b0)
		S <= IDLE;
	else 
		S <= NS;
end

always @ (*) begin
	case (S)
		IDLE: NS = NEXT_TILE;
		NEXT_TILE: NS = (tile_index == 63) ? DONE : NEXT_TILE;
		DONE: NS = DONE;
		default: NS = DONE;
	endcase

end


always @ (posedge clk or negedge rst) begin
	if (rst == 1'b0) begin
		tile_index <= 0;
		done <= 0;
		adj <= 256'b0;
	end else begin
	case (S)
		IDLE: begin
			tile_index <= 0;
			done <= 0;
		end
		
		NEXT_TILE: begin
			adj[tile_index * 4+: 4] <= tile_count;
			if (tile_index == 63) 
				done <= 1;
		   else 
				tile_index = tile_index + 1'd1;
		end
		DONE: done <= 1;
	endcase
	end
end

endmodule