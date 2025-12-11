// -----------------------------------------------------------
// render.v - Minesweeper tile renderer with adjacency numbers
// -----------------------------------------------------------
module render #(
    parameter GRID_SIZE   = 8,
    parameter TOTAL_TILES = GRID_SIZE * GRID_SIZE,
    parameter TILE_SIZE   = 480 / GRID_SIZE,
    parameter BORDER      = 4,
    parameter FONT_SCALE  = 1
)(
    input  wire        clk,
    input  wire        rst,             // active-low
    input  wire        active_pixels,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [3:0]  keys,
    input  wire [9:0]  switches,
    input  wire        game_ready,

    input  wire [TOTAL_TILES-1:0]       mine_map,
    input  wire [TOTAL_TILES*4-1:0]     adj,

    output reg  [23:0] color_out,

    // first-click out
    output reg  [$clog2(TOTAL_TILES)-1:0] start_index,
    output reg                            start,

    output wire [$clog2(TOTAL_TILES+1)-1:0] reveal_count,
    output wire [$clog2(TOTAL_TILES+1)-1:0] flag_count,

    output reg         mine_found
);

    localparam ROWCOL_BITS = $clog2(GRID_SIZE);
    localparam INDEX_BITS  = $clog2(TOTAL_TILES);
    localparam FONT_SIZE   = 8;

    // -----------------------------
    // Pixel → tile index
    // -----------------------------
    wire [9:0] x_adj = (x < 80) ? 10'd0 : (x - 80);
    wire [ROWCOL_BITS-1:0] tile_x = x_adj / TILE_SIZE;
    wire [ROWCOL_BITS-1:0] tile_y = y / TILE_SIZE;
    wire [INDEX_BITS-1:0]  tile_index = tile_y * GRID_SIZE + tile_x;

    // -----------------------------
    // Cursor movement
    // -----------------------------
    reg  [ROWCOL_BITS-1:0] sel_x = 0;
    reg  [ROWCOL_BITS-1:0] sel_y = 0;
    wire [3:0] key_i = ~keys;
    reg  [3:0] key_prev;
    wire [3:0] key_edge = key_i & ~key_prev;

    always @(posedge clk or negedge rst)
        if (!rst) key_prev <= 4'd0;
        else      key_prev <= key_i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sel_x <= 0; sel_y <= 0;
        end else begin
            if (key_edge[0] && sel_x < GRID_SIZE-1) sel_x <= sel_x + 1;
            if (key_edge[3] && sel_x > 0)           sel_x <= sel_x - 1;
            if (key_edge[2] && sel_y > 0)           sel_y <= sel_y - 1;
            if (key_edge[1] && sel_y < GRID_SIZE-1) sel_y <= sel_y + 1;
        end
    end

    wire [INDEX_BITS-1:0] cursor_index = sel_y * GRID_SIZE + sel_x;

    // -----------------------------
    // Cursor border visual
    // -----------------------------
    wire [9:0] sel_x0 = sel_x * TILE_SIZE;
    wire [9:0] sel_x1 = sel_x0 + TILE_SIZE;
    wire [9:0] sel_y0 = sel_y * TILE_SIZE;
    wire [9:0] sel_y1 = sel_y0 + TILE_SIZE;

    wire inside_cursor =
        (x_adj >= sel_x0) && (x_adj < sel_x1) &&
        (y     >= sel_y0) && (y     < sel_y1);

    wire on_border =
        inside_cursor &&
       ((x_adj - sel_x0 < BORDER) || (sel_x1 - x_adj <= BORDER) ||
        (y     - sel_y0 < BORDER) || (sel_y1 - y     <= BORDER));

    // -----------------------------
    // Switch edge detection
    // -----------------------------
    reg sw8_prev, sw9_prev;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sw8_prev <= 1'b0;
            sw9_prev <= 1'b0;
        end else begin
            sw8_prev <= switches[8];
            sw9_prev <= switches[9];
        end
    end
    wire reveal_edge = switches[8] & ~sw8_prev;
    wire flag_edge   = switches[9] & ~sw9_prev;

    // -----------------------------
    // First-click deferral
    // -----------------------------
    reg first_reveal_done;
    reg pending_first;
    reg [INDEX_BITS-1:0] pending_index;

    reg game_ready_prev;
    always @(posedge clk or negedge rst) begin
        if (!rst) game_ready_prev <= 1'b0;
        else      game_ready_prev <= game_ready;
    end
    wire game_ready_rise = game_ready & ~game_ready_prev;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            first_reveal_done <= 1'b0;
            start             <= 1'b0;
            start_index       <= {INDEX_BITS{1'b0}};
            pending_first     <= 1'b0;
            pending_index     <= {INDEX_BITS{1'b0}};
        end else begin
            start <= 1'b0;
            if (!first_reveal_done && reveal_edge) begin
                first_reveal_done <= 1'b1;
                start             <= 1'b1;
                start_index       <= cursor_index;
                pending_first     <= 1'b1;
                pending_index     <= cursor_index;
            end
            if (game_ready_rise && pending_first)
                pending_first <= 1'b0;
        end
    end

    wire use_pending      = game_ready_rise && pending_first;
    wire [INDEX_BITS-1:0] reveal_index = use_pending ? pending_index : cursor_index;
    wire flagged_at_reveal = flagged_w[reveal_index];
    wire reveal_req       = use_pending | (game_ready && reveal_edge && !flagged_at_reveal);

    // -----------------------------
    // Flood fill
    // -----------------------------
    wire [3:0] adj_at_reveal = adj[reveal_index*4 +: 4];
    wire empty_at_reveal = (adj_at_reveal == 4'd0);

    reg start_flood_d;
    always @(posedge clk or negedge rst)
        if (!rst) start_flood_d <= 1'b0;
        else      start_flood_d <= reveal_req && empty_at_reveal;

    wire [TOTAL_TILES-1:0] flood_mask;
    wire flood_done;
    wire [TOTAL_TILES-1:0] flagged_w;
    wire [TOTAL_TILES-1:0] revealed_w;

    flood_fill #(.GRID_SIZE(GRID_SIZE)) flood_i (
        .clk(clk),
        .rst(rst),
        .start(start_flood_d),
        .root_index(reveal_index),
        .flagged(flagged_w),
        .revealed(revealed_w),
        .adj(adj),
        .result_mask(flood_mask),
        .done(flood_done)
    );

    reg [TOTAL_TILES-1:0] flood_mask_lat;
    reg flood_apply_lat;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            flood_mask_lat  <= {TOTAL_TILES{1'b0}};
            flood_apply_lat <= 1'b0;
        end else begin
            flood_apply_lat <= flood_done;
            if (flood_done) flood_mask_lat <= flood_mask;
        end
    end

    wire [TOTAL_TILES-1:0] single_reveal_mask =
        (reveal_req && !empty_at_reveal) ? (1'b1 << reveal_index) : {TOTAL_TILES{1'b0}};

    // -----------------------------
    // Flag pulse
    // -----------------------------
    wire flag_pulse_here = game_ready && flag_edge && !revealed_w[cursor_index];

    // -----------------------------
    // tile_state
    // -----------------------------
    tile_state #(.GRID_SIZE(GRID_SIZE)) tile_state_i (
        .clk(clk),
        .rst(rst),
        .tile_index(cursor_index),
        .flag(flag_pulse_here),
        .reveal(1'b0), // keep reveal hard-wired low
        .flood_update(flood_mask_lat | single_reveal_mask),
        .flood_apply(flood_apply_lat | (reveal_req && !empty_at_reveal)),
        .flagged(flagged_w),
        .revealed(revealed_w)
    );

    pop_count #(.NUM_BITS(TOTAL_TILES)) pc_r (.input_number(revealed_w), .out(reveal_count));
    pop_count #(.NUM_BITS(TOTAL_TILES)) pc_f (.input_number(flagged_w),  .out(flag_count));

    wire mine_here      = mine_map[tile_index];
    wire revealed_here  = revealed_w[tile_index];
    wire flagged_here   = flagged_w[tile_index];
    wire [3:0] adj_here = adj[tile_index*4 +: 4];

    // -----------------------------
    // mine_found latch
    // -----------------------------
    always @(posedge clk or negedge rst)
        if (!rst) mine_found <= 1'b0;
        else if (game_ready && revealed_here && mine_here)
            mine_found <= 1'b1;

        // -----------------------------
    // Tile colors & adjacency numbers
    // -----------------------------
    wire checker = tile_x[0] ^ tile_y[0];

    // Character and color for numbers
    // If your tile_color doesn’t provide char_code, you can compute it locally:
    // wire [7:0] adj_char = (adj_here != 0) ? (adj_here + 8'd48) : 8'd32;
    wire [7:0]  adj_char;
    wire [23:0] adj_color;
    tile_color tc_i(
        .count(adj_here),
        .char_code(adj_char),
        .color(adj_color)
    );

    // Font coordinates (centered within each tile)
    wire [9:0] tile_x_px = tile_x * TILE_SIZE;
    wire [9:0] tile_y_px = tile_y * TILE_SIZE;
    localparam FONT_BOX   = FONT_SIZE * FONT_SCALE;
    localparam FONT_OFFSET= (TILE_SIZE - FONT_BOX) / 2;

    wire [9:0] font_x = x_adj - tile_x_px - FONT_OFFSET;
    wire [9:0] font_y = y     - tile_y_px - FONT_OFFSET;
    wire       in_font_box = (font_x < FONT_BOX) && (font_y < FONT_BOX);

    // Scale to 8x8 glyph space
    wire [9:0] font_x_div = font_x / FONT_SCALE;
    wire [9:0] font_y_div = font_y / FONT_SCALE;
    wire [2:0] font_row   = in_font_box ? font_y_div[2:0] : 3'd0;
    wire [2:0] font_col   = in_font_box ? font_x_div[2:0] : 3'd0;

    wire [7:0] font_bits;
    font font_i(
        .char_code(adj_char),
        .row(font_row),
        .bits(font_bits)
    );

    wire font_pixel_on = in_font_box && font_bits[7 - font_col];

    // -----------------------------
    // Color output
    // -----------------------------
    wire [23:0] unrevealed_color = checker ? 24'h5E8F54 : 24'h8CC783;

    always @(*) begin
        if (!active_pixels)
            color_out = 24'h000000;          // blank
        else if (on_border)
            color_out = 24'hFFFF00;          // cursor border
        else if (!game_ready)
            color_out = unrevealed_color;    // grid not ready yet
        else if (flagged_here)
            color_out = 24'hFFA500;          // flagged tile (orange)
        else if (!revealed_here)
            color_out = unrevealed_color;    // unrevealed tile
        else if (mine_here)
            color_out = 24'hFF0000;          // mine hit
        else if (adj_here != 0)
            color_out = font_pixel_on ? adj_color : 24'hDFDAC4; // number on beige
        else
            color_out = 24'hFFFFFF;          // empty revealed
    end

endmodule
