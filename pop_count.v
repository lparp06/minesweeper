module pop_count #(
    parameter GRID_SIZE = 25
)(
    input  wire [GRID_SIZE-1:0] input_number,  
    output reg  [$clog2(GRID_SIZE+1)-1:0] out
);

    integer i;

    always @(*) begin
        out = 0;
        for (i = 0; i < GRID_SIZE; i = i + 1)
            out = out + input_number[i];
    end

endmodule
