module neighbor_check(
	input wire [5:0] tile_index,
	input wire [63:0] mine_map,
	output reg [3:0] count
	
);
reg [2:0] row, col;

always @ (*) begin
	row = tile_index / 8;
	col = tile_index % 8;
	count = 0;
	
	        // Top-left
        if (row>0 && col>0 && mine_map[(row-1)*8 + (col-1)]) count = count + 1;
        // Top
        if (row>0 && mine_map[(row-1)*8 + col]) count = count + 1;
        // Top-right
        if (row>0 && col<7 && mine_map[(row-1)*8 + (col+1)]) count = count + 1;
        // Left
        if (col>0 && mine_map[row*8 + (col-1)]) count = count + 1;
        // Right
        if (col<7 && mine_map[row*8 + (col+1)]) count = count + 1;
        // Bottom-left
        if (row<7 && col>0 && mine_map[(row+1)*8 + (col-1)]) count = count + 1;
        // Bottom
        if (row<7 && mine_map[(row+1)*8 + col]) count = count + 1;
        // Bottom-right
        if (row<7 && col<7 && mine_map[(row+1)*8 + (col+1)]) count = count + 1;
    
end
endmodule