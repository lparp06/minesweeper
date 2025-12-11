module random_mine_generator #(
    parameter GRID_SIZE   = 8,
    parameter TOTAL_TILES = GRID_SIZE * GRID_SIZE,
    parameter INDEX_BITS  = $clog2(TOTAL_TILES),
    parameter NUM_MINES   = 10
)(
    input  wire                  clk,
    input  wire                  rst,          // active-low reset
    input  wire                  first_click,  // pulse when first reveal occurs
    input  wire [INDEX_BITS-1:0] root_index,   // index of first revealed tile
    output reg  [TOTAL_TILES-1:0] mine_map,    // mine placement mask
    output reg                   done          // high when placement finished
);

    // entropy sources
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

    // FSM states
    localparam IDLE    = 3'd0,
               INIT    = 3'd1,
               SAFESET = 3'd2,
               PLACE   = 3'd3,
               FINISH  = 3'd4;

    reg [2:0] state;
    reg [INDEX_BITS-1:0] placed;
    reg [INDEX_BITS-1:0] candidate;
    reg [TOTAL_TILES-1:0] safe_mask;

    // root row/col and neighbor step
    reg [INDEX_BITS-1:0] root_r, root_c;
    reg [3:0] step;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state    <= IDLE;
            mine_map <= {TOTAL_TILES{1'b0}};
            safe_mask<= {TOTAL_TILES{1'b0}};
            placed   <= 0;
            done     <= 0;
            step     <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (first_click) begin
                        state  <= INIT;
                    end
                end

                INIT: begin
                    mine_map <= {TOTAL_TILES{1'b0}};
                    safe_mask<= {TOTAL_TILES{1'b0}};
                    placed   <= 0;
                    // compute root row/col once
                    root_r   <= root_index / GRID_SIZE;
                    root_c   <= root_index % GRID_SIZE;
                    step     <= 0;
                    state    <= SAFESET;
                end

                SAFESET: begin
                    // map step 0..8 to dr,dc offsets
                    integer dr, dc, nr, nc, idx;
                    case (step)
                        0: begin dr=0;  dc=0;  end
                        1: begin dr=-1; dc=-1; end
                        2: begin dr=-1; dc=0;  end
                        3: begin dr=-1; dc=1;  end
                        4: begin dr=0;  dc=-1; end
                        5: begin dr=0;  dc=1;  end
                        6: begin dr=1;  dc=-1; end
                        7: begin dr=1;  dc=0;  end
                        8: begin dr=1;  dc=1;  end
                    endcase
                    nr = root_r + dr;
                    nc = root_c + dc;
                    if (nr >= 0 && nr < GRID_SIZE && nc >= 0 && nc < GRID_SIZE) begin
                        idx = nr*GRID_SIZE + nc;
                        safe_mask[idx] <= 1'b1;
                    end
                    if (step == 8) begin
                        state <= PLACE;
                    end else begin
                        step <= step + 1;
                    end
                end

                PLACE: begin
                    if (placed < NUM_MINES) begin
                        candidate = (lfsr ^ free_counter ^ placed) % TOTAL_TILES;
                        if (!safe_mask[candidate] && !mine_map[candidate]) begin
                            mine_map[candidate] <= 1'b1;
                            placed <= placed + 1;
                        end
                    end else begin
                        state <= FINISH;
                    end
                end

                FINISH: begin
                    done <= 1'b1;
                    state<= FINISH;
                end
            endcase
        end
    end

endmodule
