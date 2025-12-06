module minesweeper(
    input           CLOCK_50,
    input   [3:0]   KEY,
    input   [9:0]   SW,
    output  [6:0]   HEX0,
    output  [6:0]   HEX1,
    output  [6:0]   HEX2,
    output  [6:0]   HEX3,
    output          VGA_BLANK_N,
    output reg [7:0]VGA_B,
    output          VGA_CLK,
    output reg [7:0]VGA_G,
    output          VGA_HS,
    output reg [7:0]VGA_R,
    output          VGA_SYNC_N,
    output          VGA_VS
);

    // ------------------------------------------------------
    // Turn off HEX displays
    // ------------------------------------------------------
    assign HEX0 = 7'h00;
    assign HEX1 = 7'h00;
    assign HEX2 = 7'h00;
    assign HEX3 = 7'h00;

    // ------------------------------------------------------
    // Clock and reset
    // ------------------------------------------------------
    wire clk;
    wire rst;
    assign clk = CLOCK_50;
    assign rst = SW[0];

    // ------------------------------------------------------
    // VGA signals
    // ------------------------------------------------------
    wire active_pixels;
    wire [9:0] x;
    wire [9:0] y;

    // ------------------------------------------------------
    // VGA driver
    // ------------------------------------------------------
    vga_driver the_vga(
        .clk(clk),
        .rst(rst),
        .vga_clk(VGA_CLK),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .active_pixels(active_pixels),
        .xPixel(x),
        .yPixel(y),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N)
    );
	 
	 wire [63:0] mine_map = 64'b001100000000111000010000000000100000000010000000000010000000100;

    // ------------------------------------------------------
    // Tile highlight with mines
    // ------------------------------------------------------
    wire [23:0] tile_color_out;
	 wire [255:0]adj;
	 wire done; 
	 adj_fsm nums (.clk(clk),
					  .rst(rst),
	              .mine_map(mine_map),
					  .adj(adj),
					  .done(done));

   render board (
        .clk(clk),
        .rst(rst),
        .active_pixels(active_pixels),
        .x(x),
        .y(y),
        .keys(KEY),
		  .mine_map(mine_map),
		  .switches(SW[9:8]),
		  .adj(adj),
        .color_out(tile_color_out)
    );


    // ------------------------------------------------------
    // Assign VGA color
    // ------------------------------------------------------
    always @(*) begin
        {VGA_R, VGA_G, VGA_B} = tile_color_out;
    end

endmodule
