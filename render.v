module render #(
    parameter GRID_SIZE   = 8,
    parameter TOTAL_TILES = GRID_SIZE * GRID_SIZE,
    parameter TILE_SIZE   = 480 / GRID_SIZE,
    parameter BORDER      = 4
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        active_pixels,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [3:0]  keys,
    input  wire [9:0]  switches,
    input  wire [TOTAL_TILES-1:0] mine_map,
    input  wire [TOTAL_TILES*4-1:0] adj,

    output reg  [23:0] color_out,
    output wire [$clog2(TOTAL_TILES+1)-1:0] reveal_count,
    output reg         mine_found
);

localparam ROWCOL_BITS = $clog2(GRID_SIZE);
localparam INDEX_BITS  = $clog2(TOTAL_TILES);

//
// ----------------------
// PIXEL → TILE INDEX
// ----------------------
wire [9:0] x_adj = (x < 80) ? 0 : (x - 80);
wire [ROWCOL_BITS-1:0] tile_x = x_adj / TILE_SIZE;
wire [ROWCOL_BITS-1:0] tile_y = y / TILE_SIZE;
wire [INDEX_BITS-1:0] tile_index = tile_y * GRID_SIZE + tile_x;

//
// ----------------------
// CURSOR MOVEMENT
// ----------------------
reg [ROWCOL_BITS-1:0] sel_x = 0;
reg [ROWCOL_BITS-1:0] sel_y = 0;

wire [3:0] key_i = ~keys;
reg  [3:0] key_prev;
wire [3:0] key_edge = key_i & ~key_prev;

always @(posedge clk or negedge rst)
    if (!rst) key_prev <= 0;
    else key_prev <= key_i;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        sel_x <= 0;
        sel_y <= 0;
    end else begin
        if (key_edge[0] && sel_x < GRID_SIZE-1) sel_x <= sel_x + 1;
        if (key_edge[3] && sel_x > 0) sel_x <= sel_x - 1;
        if (key_edge[2] && sel_y > 0) sel_y <= sel_y - 1;
        if (key_edge[1] && sel_y < GRID_SIZE-1) sel_y <= sel_y + 1;
    end
end

wire [INDEX_BITS-1:0] cursor_index = sel_y * GRID_SIZE + sel_x;

//
// ----------------------
// CURSOR BORDER DETECTION
// ----------------------
wire [9:0] sel_x0 = sel_x * TILE_SIZE;
wire [9:0] sel_x1 = sel_x0 + TILE_SIZE;
wire [9:0] sel_y0 = sel_y * TILE_SIZE;
wire [9:0] sel_y1 = sel_y0 + TILE_SIZE;

wire inside_cursor =
    (x_adj >= sel_x0) && (x_adj < sel_x1) &&
    (y >= sel_y0) && (y < sel_y1);

wire on_border =
    inside_cursor &&
   ((x_adj - sel_x0 < BORDER) || (sel_x1 - x_adj <= BORDER) ||
    (y - sel_y0 < BORDER) || (sel_y1 - y <= BORDER));

//
// ----------------------
// SWITCH EDGE DETECTION
// ----------------------
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
// ----------------------
// FLOOD-FILL TRIGGER
// ----------------------
wire empty_tile = (adj[cursor_index*4 +:4] == 4'd0);
reg start_flood_d;
always @(posedge clk or negedge rst) begin
    if (!rst)
        start_flood_d <= 0;
    else
        start_flood_d <= reveal_edge & empty_tile;
end

wire [TOTAL_TILES-1:0] flood_mask;
wire flood_done;

flood_fill #(.GRID_SIZE(GRID_SIZE)) flood_i (
    .clk(clk),
    .rst(rst),
    .start(start_flood_d),
    .root_index(cursor_index),
    .flagged(flagged_w),
    .revealed(revealed_w),
    .adj(adj),
    .result_mask(flood_mask),
    .done(flood_done)
);

//
// ----------------------
// Latch flood mask
// ----------------------
reg [TOTAL_TILES-1:0] flood_mask_lat;
reg flood_apply_lat;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        flood_mask_lat  <= {TOTAL_TILES{1'b0}};
        flood_apply_lat <= 0;
    end else begin
        flood_apply_lat <= flood_done;
        if (flood_done)
            flood_mask_lat <= flood_mask;
    end
end

//
// ----------------------
// SINGLE TILE REVEAL MASK (numbered tiles only)
// ----------------------
wire [TOTAL_TILES-1:0] single_reveal_mask =
    (reveal_edge & ~empty_tile) ? (1'b1 << cursor_index) : {TOTAL_TILES{1'b0}};

//
// ----------------------
// TILE STATE
// ----------------------
wire [TOTAL_TILES-1:0] flagged_w;
wire [TOTAL_TILES-1:0] revealed_w;

tile_state #(.GRID_SIZE(GRID_SIZE)) tile_state_i (
    .clk(clk),
    .rst(rst),
    .tile_index(cursor_index),
    .flag(flag_edge),
    .reveal(1'b0), // handled via masks
    .flood_update(flood_mask_lat | single_reveal_mask),
    .flood_apply(flood_apply_lat | (reveal_edge & ~empty_tile)),
    .flagged(flagged_w),
    .revealed(revealed_w)
);

//
// ----------------------
// POPCOUNT
// ----------------------
pop_count #(.NUM_BITS(TOTAL_TILES)) pc_i (
    .input_number(revealed_w),
    .out(reveal_count)
);

//
// ----------------------
// LOCAL TILE DATA
// ----------------------
wire mine_here     = mine_map[tile_index];
wire flagged_here  = flagged_w[tile_index];
wire revealed_here = revealed_w[tile_index];

wire [3:0] adj_here = adj[tile_index*4 +: 4];

//
// ----------------------
// MINE FOUND LATCH
// ----------------------
always @(posedge clk or negedge rst) begin
    if (!rst)
        mine_found <= 0;
    else if (revealed_here && mine_here)
        mine_found <= 1;
end

//
// ----------------------
// COLOR OUTPUT
// ----------------------
wire checker = tile_x[0] ^ tile_y[0];

wire [23:0] adj_color;
tile_color tc_i(.count(adj_here), .color(adj_color));

always @(*) begin
    if (!active_pixels)
        color_out = 24'h000000;
    else if (on_border)
        color_out = 24'hFFFF00;  // yellow
    else if (!revealed_here && flagged_here)
        color_out = 24'hFF00FF;  // magenta flag
    else if (!revealed_here)
        color_out = checker ? 24'h5E8F54 : 24'h8CC783; // green board
    else if (revealed_here && mine_here)
        color_out = 24'hFF0000;  // red mine
    else if (adj_here != 0)
        color_out = adj_color;   // number
    else
        color_out = 24'hFFFFFF;  // empty
end

endmodule
