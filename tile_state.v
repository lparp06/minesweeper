module tile_state #(
    parameter GRID_SIZE = 5,
    parameter TOTAL_TILES = GRID_SIZE * GRID_SIZE
)(
    input  wire                  clk,
    input  wire                  rst,        
    input  wire [$clog2(TOTAL_TILES)-1:0] tile_index,
    input  wire                  flag,
    input  wire                  reveal,

    output reg  [TOTAL_TILES-1:0] flagged,
    output reg  [TOTAL_TILES-1:0] revealed
);

integer i;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        flagged  <= {TOTAL_TILES{1'b0}};
        revealed <= {TOTAL_TILES{1'b0}};
    end else begin
        
        // toggle flag on flag edge
        if (flag)
            flagged[tile_index] <= ~flagged[tile_index];

        // reveal if not flagged
        if (reveal && !flagged[tile_index] && !revealed[tile_index])
            revealed[tile_index] <= 1'b1;

    end
end

endmodule
