module minesweeper(
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    output [6:0] HEX0, HEX1, HEX2, HEX3,
    output VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS,
    output reg [7:0] VGA_R, VGA_G, VGA_B
);

   wire clk   = CLOCK_50;
   wire rst   = SW[0];
   wire start = ~KEY[3];

   wire active_pixels;
   wire [9:0] x, y;
	
	
   vga_driver the_vga(
        .clk(clk), .rst(rst),
        .vga_clk(VGA_CLK),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .active_pixels(active_pixels),
        .xPixel(x), .yPixel(y),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N)
    );

   wire [23:0] color_out;
	wire [5:0] reveal_count;
   wire endgame, win;

   game_controller game (
      .clk(clk),
      .rst(rst),
      .start(start),
      .active_pixels(active_pixels),
      .x(x), .y(y),
      .KEY(KEY),
      .SW(SW),
      .color_out(color_out),
		.reveal_count(reveal_count),
      .endgame(endgame),
      .win(win)
   );

   // Top-level FSM for screen control
   localparam START=0, PLAYING=1, DONE=2;
   reg [1:0] S, NS;
   always @(posedge clk or negedge rst) 
		S <= !rst ? START : NS;
   always @(*) begin
       case(S)
           START:   NS = start ? PLAYING : START;
           PLAYING: NS = endgame ? DONE : PLAYING;
           DONE:    NS = DONE;
           default: NS = START;
       endcase
   end

   reg [23:0] screen_out;
   always @(posedge clk or negedge rst) begin
       if (!rst) screen_out <= 24'h000000;
       else case(S)
           START:   screen_out <= 24'h0000FF; // blue start
           PLAYING: screen_out <= color_out;  // game rendering
           DONE:    screen_out <= win ? 24'h00FF00 : 24'hFF0000; // green win / red loss
           default: screen_out <= 24'hFF0000;
       endcase
   end

   always @(*) {VGA_R, VGA_G, VGA_B} = screen_out;

	wire [6:0] tens_dig;
	wire [6:0] ones_dig;
	
	seven_segment ones (reveal_count % 10, ones_dig);
	seven_segment tens (reveal_count / 10, tens_dig);
	
   assign HEX0 = ones_dig;
   assign HEX1 = tens_dig;
   assign HEX2 = 7'b1111111;
   assign HEX3 = 7'b1111111;

endmodule