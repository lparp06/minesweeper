// ===========================================================
// FLOOD-FILL FSM MODULE
// Reveals all connected zero-adjacent tiles
// ===========================================================
module flood_fill #(
    parameter GRID_SIZE   = 8,
    parameter TOTAL_TILES = GRID_SIZE * GRID_SIZE,
    parameter INDEX_BITS  = $clog2(TOTAL_TILES)
)(
    input  wire                      clk,
    input  wire                      rst,           // active-low reset
    input  wire                      start,         // one-cycle pulse to start flood
    input  wire [INDEX_BITS-1:0]     root_index,    // starting tile
    input  wire [TOTAL_TILES-1:0]    flagged,       // do not reveal flagged tiles
    input  wire [TOTAL_TILES-1:0]    revealed,      // already revealed tiles
    input  wire [TOTAL_TILES*4-1:0]  adj,           // adjacency numbers (4 bits each)
    output reg  [TOTAL_TILES-1:0]    result_mask,   // bits to OR into revealed[]
    output reg                       done           // one-cycle pulse when finished
);

    // FSM states
    localparam IDLE  = 3'd0;
    localparam INIT  = 3'd1;
    localparam SCAN  = 3'd2;
    localparam CHECK = 3'd3;
    localparam NEI   = 3'd4;
    localparam FIN   = 3'd5;

    reg [2:0] state;

    reg [INDEX_BITS-1:0] scan_i;
    reg [2:0] nei_step;
    reg changed;

    integer row, col, nr, nc;
    reg [INDEX_BITS-1:0] nei_idx;
    reg [3:0] cur_adj;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state       <= IDLE;
            result_mask <= {TOTAL_TILES{1'b0}};
            done        <= 1'b0;
            scan_i      <= 0;
            nei_step    <= 0;
            changed     <= 0;
        end else begin
            case(state)

                IDLE: begin
                    done <= 1'b0;
                    if (start) state <= INIT;
                end

                INIT: begin
                    result_mask <= {TOTAL_TILES{1'b0}};
                    done        <= 1'b0;
                    scan_i      <= 0;
                    nei_step    <= 0;
                    changed     <= 0;

                    // Add root tile if not flagged/revealed
                    if (!flagged[root_index] && !revealed[root_index]) begin
                        result_mask[root_index] <= 1'b1;
                        if (adj[root_index*4 +: 4] == 0)
                            changed <= 1;
                    end

                    // Decide next state
                    if (adj[root_index*4 +: 4] == 0)
                        state <= SCAN;
                    else
                        state <= FIN;
                end

                SCAN: begin
                    scan_i   <= 0;
                    nei_step <= 0;
                    changed  <= 0;
                    state    <= CHECK;
                end

                CHECK: begin
                    row     = scan_i / GRID_SIZE;
                    col     = scan_i % GRID_SIZE;
                    cur_adj = adj[scan_i*4 +: 4];

                    if (result_mask[scan_i] && cur_adj == 0) begin
                        nei_step <= 0;
                        state    <= NEI;
                    end else begin
                        if (scan_i == TOTAL_TILES - 1) begin
                            if (changed)
                                state <= SCAN;
                            else
                                state <= FIN;
                        end else begin
                            scan_i <= scan_i + 1;
                        end
                    end
                end

                NEI: begin
                    case(nei_step)
                        3'd0: begin nr = row-1; nc = col-1; end
                        3'd1: begin nr = row-1; nc = col;   end
                        3'd2: begin nr = row-1; nc = col+1; end
                        3'd3: begin nr = row;   nc = col-1; end
                        3'd4: begin nr = row;   nc = col+1; end
                        3'd5: begin nr = row+1; nc = col-1; end
                        3'd6: begin nr = row+1; nc = col;   end
                        3'd7: begin nr = row+1; nc = col+1; end
                        default: begin nr = -1; nc = -1; end
                    endcase

                    if (nr >= 0 && nr < GRID_SIZE && nc >= 0 && nc < GRID_SIZE) begin
                        nei_idx = nr*GRID_SIZE + nc;
                        if (!flagged[nei_idx] && !revealed[nei_idx] && !result_mask[nei_idx]) begin
                            result_mask[nei_idx] <= 1'b1;
                            if (adj[nei_idx*4 +:4] == 0)
                                changed <= 1;
                        end
                    end

                    if (nei_step == 3'd7) begin
                        if (scan_i == TOTAL_TILES-1) begin
                            if (changed)
                                state <= SCAN;
                            else
                                state <= FIN;
                        end else begin
                            scan_i <= scan_i + 1;
                            state <= CHECK;
                        end
                    end else begin
                        nei_step <= nei_step + 1;
                    end
                end

                FIN: begin
                    done  <= 1'b1; // one-cycle pulse
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule