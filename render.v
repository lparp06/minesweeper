module render (
    input  wire        clk,
    input  wire        rst,
    input  wire        active_pixels,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [3:0]  keys,
    input  wire [63:0] mine_map,
    input  wire [9:0]  switches,
    input  wire [255:0] adj,
    output reg  [23:0] color_out,
    output wire [5:0]  reveal_count,
    output reg         mine_found
);

parameter TILE_SIZE = 60,
          BORDER    = 4,
          GRID_SIZE = 8;

//------------------------------------------------------
// Cursor tile position
//------------------------------------------------------
reg [2:0] sel_x = 0;
reg [2:0] sel_y = 0;

wire [9:0] x_adj = (x < 10'd80) ? 10'd0 : (x - 10'd80);
wire [3:0] tile_x = x_adj / TILE_SIZE;
wire [3:0] tile_y = y / TILE_SIZE;
wire [5:0] tile_index = tile_y * GRID_SIZE + tile_x;

//------------------------------------------------------
// Movement key edge detection
//------------------------------------------------------
wire [3:0] key_i = ~keys;
reg  [3:0] key_prev;
wire [3:0] key_edge = key_i & ~key_prev;

always @(posedge clk or negedge rst) begin
    if (!rst)
        key_prev <= 4'b0000;
    else
        key_prev <= key_i;
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        sel_x <= 0;
        sel_y <= 0;
    end else begin
        if (key_edge[0] && sel_x < GRID_SIZE-1) sel_x <= sel_x + 1; // right
        if (key_edge[3] && sel_x > 0)           sel_x <= sel_x - 1; // left
        if (key_edge[2] && sel_y > 0)           sel_y <= sel_y - 1; // up
        if (key_edge[1] && sel_y < GRID_SIZE-1) sel_y <= sel_y + 1; // down
    end
end

//------------------------------------------------------
// Border detection for cursor highlight
//------------------------------------------------------
wire [9:0] sel_x0 = sel_x * TILE_SIZE;
wire [9:0] sel_x1 = sel_x0 + TILE_SIZE;
wire [9:0] sel_y0 = sel_y * TILE_SIZE;
wire [9:0] sel_y1 = sel_y0 + TILE_SIZE;

wire inside_tile =
    (x_adj >= sel_x0) && (x_adj < sel_x1) &&
    (y     >= sel_y0) && (y     < sel_y1);

wire on_border =
    inside_tile &&
    ((x_adj - sel_x0 < BORDER) ||
     (sel_x1 - x_adj <= BORDER) ||
     (y - sel_y0 < BORDER) ||
     (sel_y1 - y <= BORDER));

//------------------------------------------------------
// Adjacency number & color
//------------------------------------------------------
wire [3:0] adj_here = adj[tile_index*4 +: 4];
wire [23:0] adj_color;
tile_color tc (.count(adj_here), .color(adj_color));

//------------------------------------------------------
// Flag / reveal switch edge detection (SW9 flag, SW8 reveal)
//------------------------------------------------------
reg sw9_prev, sw8_prev;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        sw9_prev <= 0;
        sw8_prev <= 0;
    end else begin
        sw9_prev <= switches[9];
        sw8_prev <= switches[8];
    end
end

wire flag_edge   = switches[9] & ~sw9_prev;   // one-shot flag toggle
wire reveal_edge = switches[8] & ~sw8_prev;   // one-shot reveal

//------------------------------------------------------
// Tile state (flag + reveal storage)
//------------------------------------------------------
wire [63:0] flagged_w;
wire [63:0] revealed_w;

tile_state state (
    .clk(clk),
    .rst(rst),
    .tile_index(sel_y * GRID_SIZE + sel_x),  // cursor tile
    .flag(flag_edge),
    .reveal(reveal_edge),
    .flagged(flagged_w),
    .revealed(revealed_w),
);


pop_count counter(
	.input_number(revealed_w),	
	.out(reveal_count),
);

wire mine_here     = mine_map[tile_index];
wire flagged_here  = flagged_w[tile_index];
wire revealed_here = revealed_w[tile_index];

//------------------------------------------------------
// Mine found latch
//------------------------------------------------------
always @(posedge clk or negedge rst) begin
    if (!rst)
        mine_found <= 1'b0;
    else if (revealed_here && mine_here)
        mine_found <= 1'b1;
end

//------------------------------------------------------
// Output color logic
//------------------------------------------------------
wire checker = (tile_x + tile_y) & 1;

always @(*) begin
    if (!active_pixels)
        color_out = 24'h000000;
    else if (on_border)
        color_out = 24'hFFFF00; // cursor highlight
    else if (!revealed_here && flagged_here)
        color_out = 24'hFF00FF; // flag (magenta)
    else if (!revealed_here)
        color_out = checker ? 24'h5E8F54 : 24'h8CC783; // hidden tile
    else if (revealed_here && mine_here)
        color_out = 24'hFF0000; // revealed mine
    else if (adj_here != 0)
        color_out = adj_color; // number tile
    else
        color_out = 24'hFFFFFF; // revealed empty tile
end

endmodule