// ================================================
// Robust Random Mine Generator (Synthesizable)
// First click + neighbors are always mine-free
// LFSR + counter gives varied layouts
// ================================================
module random_mine_generator #(
    parameter GRID_SIZE   = 8,
    parameter TOTAL_TILES = GRID_SIZE * GRID_SIZE,
    parameter INDEX_BITS  = $clog2(TOTAL_TILES),
    parameter NUM_MINES   = 10
)(
    input  wire                     clk,
    input  wire                     rst,          // active-low reset
    input  wire                     first_click,  // pulse when first reveal occurs
    input  wire [INDEX_BITS-1:0]    root_index,   // index of first revealed tile
    output reg  [TOTAL_TILES-1:0]   mine_map,     // mine placement mask
    output reg                      done          // high when placement finished
);

    // -------------------------------------------------------------
    // Safe zone mask: root + valid neighbors
    // -------------------------------------------------------------
    reg [TOTAL_TILES-1:0] safe_mask;
    integer r, c, nr, nc, idx;

    always @(*) begin
        safe_mask = {TOTAL_TILES{1'b0}};
        r = root_index / GRID_SIZE;
        c = root_index % GRID_SIZE;

        for (nr = 0; nr < GRID_SIZE; nr = nr + 1) begin
            for (nc = 0; nc < GRID_SIZE; nc = nc + 1) begin
                if ((nr >= r-1) && (nr <= r+1) &&
                    (nc >= c-1) && (nc <= c+1)) begin
                    idx = nr * GRID_SIZE + nc;
                    safe_mask[idx] = 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------
    // LFSR + free-running counter for entropy
    // -------------------------------------------------------------
    reg [15:0] lfsr;
    wire fb = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    reg [15:0] free_counter;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            lfsr         <= 16'hACE1;
            free_counter <= 0;
        end else begin
            lfsr         <= {lfsr[14:0], fb};
            free_counter <= free_counter + 1;
        end
    end

    // -------------------------------------------------------------
    // FSM for mine placement
    // -------------------------------------------------------------
    localparam IDLE  = 2'd0,
               INIT  = 2'd1,
               PLACE = 2'd2,
               FINISH= 2'd3;

    reg [1:0] state;
    reg [INDEX_BITS-1:0] placed;
    reg [INDEX_BITS-1:0] candidate;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state    <= IDLE;
            mine_map <= {TOTAL_TILES{1'b0}};
            placed   <= 0;
            done     <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (first_click)
                        state <= INIT;
                end

                INIT: begin
                    mine_map <= {TOTAL_TILES{1'b0}};
                    placed   <= 0;
                    state    <= PLACE;
                end

                PLACE: begin
                    if (placed < NUM_MINES) begin
                        // new candidate each cycle: LFSR ^ counter ^ placed
                        candidate = (lfsr ^ free_counter ^ { {INDEX_BITS{1'b0}} | root_index } ^ placed) % TOTAL_TILES;

                        if (!safe_mask[candidate] && !mine_map[candidate]) begin
                            mine_map[candidate] <= 1'b1;
                            placed <= placed + 1;
                        end
                        // else try a new candidate next clock
                    end else begin
                        state <= FINISH;
                    end
                end

                FINISH: begin
                    done  <= 1'b1;
                    state <= FINISH; // hold until reset
                end
            endcase
        end
    end

endmodule
