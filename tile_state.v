module tile_state(
    input  wire       clk,
    input  wire       rst,
    input  wire [5:0] tile_index,
    input  wire       flag,
    input  wire       reveal,
    output reg [63:0] flagged,
    output reg [63:0] revealed,
    output reg [5:0]  reveal_count
);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        flagged      <= 64'd0;
        revealed     <= 64'd0;
        reveal_count <= 6'd0;
    end else begin
        if (flag)
            flagged[tile_index] <= ~flagged[tile_index];

        if (reveal && !flagged[tile_index] && !revealed[tile_index]) begin
            revealed[tile_index] <= 1'b1;
            reveal_count <= reveal_count + 1;
        end
    end
end

endmodule
