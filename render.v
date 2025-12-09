module render (
    input  wire        clk,
    input  wire        rst,
    input  wire        active_pixels,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [3:0]  keys,
    input  wire [9:0]  switches,
    input  wire [24:0] mine_map,   // FIXED width
    input  wire [99:0] adj,        // 25 tiles × 4 bits

    output reg  [23:0] color_out,
    output wire [4:0]  reveal_count,
    output reg         mine_found
);

parameter GRID_SIZE = 5;                   // 5×5 grid
parameter TOTAL_TILES = GRID_SIZE * GRID_SIZE;
parameter TILE_SIZE = 480 / GRID_SIZE;
parameter BORDER = 4;

localparam ROWCOL_BITS = $clog2(GRID_SIZE);
localparam INDEX_BITS  = $clog2(TOTAL_TILES);

//
// ------------------------------------------------------------------
// TILE LOCATION UNDER THE PIXEL
// ------------------------------------------------------------------
wire [9:0] x_adj = (x < 80) ? 0 : (x - 80);

wire [ROWCOL_BITS-1:0] tile_x = x_adj / TILE_SIZE;
wire [ROWCOL_BITS-1:0] tile_y = y     / TILE_SIZE;

// CORRECT ROW-MAJOR INDEX
wire [INDEX_BITS-1:0] tile_index = tile_y * GRID_SIZE + tile_x;

//
// ------------------------------------------------------------------
// CURSOR MOVEMENT
// ------------------------------------------------------------------
reg [ROWCOL_BITS-1:0] sel_x = 0;
reg [ROWCOL_BITS-1:0] sel_y = 0;

wire [3:0] key_i = ~keys;
reg  [3:0] key_prev;
wire [3:0] key_edge = key_i & ~key_prev;

always @(posedge clk or negedge rst) begin
    if (!rst)
        key_prev <= 0;
    else
        key_prev <= key_i;
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        sel_x <= 0;
        sel_y <= 0;
    end else begin
        if (key_edge[0] && sel_x < GRID_SIZE - 1) sel_x <= sel_x + 1; // RIGHT
        if (key_edge[3] && sel_x > 0)             sel_x <= sel_x - 1; // LEFT
        if (key_edge[2] && sel_y > 0)             sel_y <= sel_y - 1; // UP
        if (key_edge[1] && sel_y < GRID_SIZE - 1) sel_y <= sel_y + 1; // DOWN
    end
end

// CORRECT CURSOR INDEX
wire [INDEX_BITS-1:0] cursor_index = sel_y * GRID_SIZE + sel_x;

//
// ------------------------------------------------------------------
// CURSOR BORDER DRAWING
// ------------------------------------------------------------------
wire [9:0] sel_x0 = sel_x * TILE_SIZE;
wire [9:0] sel_x1 = sel_x0 + TILE_SIZE;
wire [9:0] sel_y0 = sel_y * TILE_SIZE;
wire [9:0] sel_y1 = sel_y0 + TILE_SIZE;

wire inside_cursor =
    (x_adj >= sel_x0) && (x_adj < sel_x1) &&
    (y     >= sel_y0) && (y     < sel_y1);

wire on_border =
    inside_cursor &&
   ((x_adj - sel_x0 < BORDER) ||
    (sel_x1 - x_adj <= BORDER) ||
    (y - sel_y0 < BORDER) ||
    (sel_y1 - y <= BORDER));

//
// ------------------------------------------------------------------
// SWITCH EDGE DETECT (flag = SW9, reveal = SW8)
// ------------------------------------------------------------------
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

wire flag_edge   = switches[9] & ~sw9_prev;
wire reveal_edge = switches[8] & ~sw8_prev;

//
// ------------------------------------------------------------------
// TILE STATE (flagged + revealed arrays)
// ------------------------------------------------------------------
wire [TOTAL_TILES-1:0] flagged_w;
wire [TOTAL_TILES-1:0] revealed_w;

tile_state #(.GRID_SIZE(GRID_SIZE)) tile_state_i (
    .clk(clk),
    .rst(rst),
    .tile_index(cursor_index),
    .flag(flag_edge),
    .reveal(reveal_edge),
    .flagged(flagged_w),
    .revealed(revealed_w)
);

//
// ------------------------------------------------------------------
// POP COUNT (count revealed tiles)
// ------------------------------------------------------------------
pop_count #(.GRID_SIZE(GRID_SIZE)) popc (
    .input_number(revealed_w),
    .out(reveal_count)
);

//
// ------------------------------------------------------------------
// LOCAL TILE VALUES
// ------------------------------------------------------------------
wire mine_here     = mine_map[tile_index];
wire flagged_here  = flagged_w[tile_index];
wire revealed_here = revealed_w[tile_index];

wire [3:0] adj_here = adj[tile_index*4 +: 4];

//
// ------------------------------------------------------------------
// MINE FOUND LATCH
// ------------------------------------------------------------------
always @(posedge clk or negedge rst) begin
    if (!rst)
        mine_found <= 0;
    else if (revealed_here && mine_here)
        mine_found <= 1;
end

//
// ------------------------------------------------------------------
// COLOR OUTPUT
// ------------------------------------------------------------------
wire checker = tile_x[0] ^ tile_y[0];

wire [23:0] adj_color;
tile_color tc(.count(adj_here), .color(adj_color));

always @(*) begin
    if (!active_pixels)
        color_out = 24'h000000;

    else if (on_border)
        color_out = 24'hFFFF00;   // cursor yellow outline

    else if (!revealed_here && flagged_here)
        color_out = 24'hFF00FF;   // magenta flag

    else if (!revealed_here)
        color_out = checker ? 24'h5E8F54 : 24'h8CC783;

    else if (revealed_here && mine_here)
        color_out = 24'hFF0000;   // red mine

    else if (adj_here != 0)
        color_out = adj_color;

    else
        color_out = 24'hFFFFFF;   // empty tile
end

endmodule
