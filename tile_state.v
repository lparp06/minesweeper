module tile_state #(
    parameter GRID_SIZE   = 8,
    parameter TOTAL_TILES = GRID_SIZE*GRID_SIZE,
    parameter INDEX_BITS  = $clog2(TOTAL_TILES)
)(
    input  wire                     clk,
    input  wire                     rst,           // active-low reset
    input  wire [INDEX_BITS-1:0]    tile_index,    // current cursor tile
    input  wire                     flag,          // toggle flag request
    input  wire                     reveal,        // reveal request
    input  wire [TOTAL_TILES-1:0]   flood_update,  // mask from flood-fill
    input  wire                     flood_apply,   // pulse when flood mask valid
    output reg  [TOTAL_TILES-1:0]   flagged,       // persistent flag state
    output reg  [TOTAL_TILES-1:0]   revealed       // persistent reveal state
);

    // Edge detection for the flag input
    reg flag_prev;
    wire flag_edge = flag & ~flag_prev;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            flag_prev <= 0;
        else
            flag_prev <= flag;
    end

    // Mask for single-tile reveal
    wire [TOTAL_TILES-1:0] single_reveal_mask =
        (reveal && !flagged[tile_index]) ? (1'b1 << tile_index) : {TOTAL_TILES{1'b0}};

    always @(posedge clk or negedge rst) begin
    if (!rst) begin
        flagged  <= {TOTAL_TILES{1'b0}};
        revealed <= {TOTAL_TILES{1'b0}};
    end else begin
        // Toggle flag on pulse
        if (flag)
            flagged[tile_index] <= ~flagged[tile_index];

        // Merge reveals
        revealed <= revealed
                  | single_reveal_mask
                  | (flood_apply ? flood_update : {TOTAL_TILES{1'b0}});
    end
	end


endmodule
