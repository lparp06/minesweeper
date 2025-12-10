module pop_count #(
    parameter NUM_BITS = 25
)(
    input  wire [NUM_BITS-1:0] input_number,
    output reg  [$clog2(NUM_BITS+1)-1:0] out
);

    integer i;
    reg [$clog2(NUM_BITS+1)-1:0] sum;

    always @(*) begin
        sum = 0;
        for (i = 0; i < NUM_BITS; i = i + 1)
            sum = sum + input_number[i];
        out = sum;
    end
endmodule