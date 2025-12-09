module neighbor_check #(
    parameter NUM_SQUARES  = 5,
    parameter INDEX_LENGTH = $clog2(NUM_SQUARES*NUM_SQUARES)
)(
    input  wire [INDEX_LENGTH-1:0]          tile_index,
    input  wire [NUM_SQUARES*NUM_SQUARES-1:0] mine_map,
    output reg  [3:0]                       count
);

    // Compute number of bits needed to store row/col
    localparam ROWCOL_BITS = $clog2(NUM_SQUARES);

    reg [ROWCOL_BITS-1:0] row, col;

    always @(*) begin
        // Convert flat index -> row/col
        row = tile_index / NUM_SQUARES;
        col = tile_index % NUM_SQUARES;

        count = 4'd0;

        // NW
        if (row > 0 && col > 0 &&
            mine_map[(row-1)*NUM_SQUARES + (col-1)])
            count = count + 1;

        // N
        if (row > 0 &&
            mine_map[(row-1)*NUM_SQUARES + col])
            count = count + 1;

        // NE
        if (row > 0 && col < NUM_SQUARES-1 &&
            mine_map[(row-1)*NUM_SQUARES + (col+1)])
            count = count + 1;

        // W
        if (col > 0 &&
            mine_map[row*NUM_SQUARES + (col-1)])
            count = count + 1;

        // E
        if (col < NUM_SQUARES-1 &&
            mine_map[row*NUM_SQUARES + (col+1)])
            count = count + 1;

        // SW
        if (row < NUM_SQUARES-1 && col > 0 &&
            mine_map[(row+1)*NUM_SQUARES + (col-1)])
            count = count + 1;

        // S
        if (row < NUM_SQUARES-1 &&
            mine_map[(row+1)*NUM_SQUARES + col])
            count = count + 1;

        // SE
        if (row < NUM_SQUARES-1 && col < NUM_SQUARES-1 &&
            mine_map[(row+1)*NUM_SQUARES + (col+1)])
            count = count + 1;
    end

endmodule
