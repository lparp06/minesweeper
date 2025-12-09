module adj_fsm
#(
    parameter GRID_SIZE = 5,
    parameter TOTAL_SQUARES = GRID_SIZE * GRID_SIZE,
    parameter INDEX_WIDTH = $clog2(TOTAL_SQUARES)
)
(
    input  wire clk,
    input  wire rst,
    input  wire [TOTAL_SQUARES-1:0] mine_map,
    output reg  [TOTAL_SQUARES*4-1:0] adj,
    output reg done
);

reg [1:0] S, NS;

localparam IDLE      = 2'd0,
           NEXT_TILE = 2'd1,
           DONE      = 2'd2;

reg  [INDEX_WIDTH-1:0] tile_index;
wire [3:0] tile_count;

neighbor_check #(
    .NUM_SQUARES(GRID_SIZE),
    .INDEX_LENGTH(INDEX_WIDTH)
) nc (
    .tile_index(tile_index),
    .mine_map(mine_map),
    .count(tile_count)
);

//----------------------------------------------------------
// State register
//----------------------------------------------------------
always @(posedge clk or negedge rst) begin
    if (!rst)
        S <= IDLE;
    else
        S <= NS;
end

//----------------------------------------------------------
// Next-state logic
//----------------------------------------------------------
always @(*) begin
    case (S)
        IDLE:       NS = NEXT_TILE;

        NEXT_TILE:  
            NS = (tile_index == TOTAL_SQUARES-1) ? DONE : NEXT_TILE;

        DONE:       NS = DONE;

        default:    NS = DONE;
    endcase
end

//----------------------------------------------------------
// Output logic and tile counter
//----------------------------------------------------------
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        tile_index <= 0;
        done       <= 0;
        adj        <= {TOTAL_SQUARES*4{1'b0}};
    end else begin
        case (S)
            IDLE: begin
                tile_index <= 0;
                done       <= 0;
            end

            NEXT_TILE: begin
                adj[tile_index*4 +: 4] <= tile_count;

                if (tile_index == TOTAL_SQUARES-1)
                    done <= 1;
                else
                    tile_index <= tile_index + 1'b1;
            end

            DONE: begin
                done <= 1;
            end
        endcase
    end
end

endmodule
