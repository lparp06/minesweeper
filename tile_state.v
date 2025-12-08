module tile_state(
    input  wire       clk,
    input  wire       rst,        // active-low reset
    input  wire [5:0] tile_index, // cursor-selected tile
    input  wire       flag,       // one-shot edge pulse for flag
    input  wire       reveal,     // one-shot edge pulse for reveal
    output reg [63:0] flagged,
    output reg [63:0] revealed
);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        // clear everything when rst is driven low
        flagged      <= 64'd0;
        revealed     <= 64'd0;
    end else begin
        // toggle flag state on edge
        if (flag)
            flagged[tile_index] <= ~flagged[tile_index];

        // reveal only once per edge, only if not flagged and not already revealed
        if (reveal && !flagged[tile_index] && !revealed[tile_index]) begin
            revealed[tile_index] <= 1'b1;
        end
    end
end

endmodule
