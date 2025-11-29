module bcd_display (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic bcd_in_en,
    input g::bcd_t bcd_in,
    input logic busy_in,

    output logic [7:0] data_out,
    output logic data_out_en
);

    typedef enum logic [2:0] {
        S_IDLE,
        S_START_TX,
        S_WAIT_BUSY,
        S_TX
    } state_t;

    state_t current_state;
    state_t next_state;

    localparam [2:0] MAX_OUT_IDX = 5;

    g::bcd_t bcd_buf;
    logic [2:0] out_idx;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;

        case (current_state)
            S_IDLE: begin
                if (bcd_in_en) begin
                    next_state = S_START_TX;
                end
            end
            S_START_TX: begin
                next_state = S_WAIT_BUSY;
            end
            S_WAIT_BUSY: begin
                if (!busy_in) begin
                    if (out_idx == MAX_OUT_IDX) begin
                        next_state = S_IDLE;
                    end else begin
                        next_state = S_TX;
                    end
                end
            end
            S_TX: begin
                next_state = S_WAIT_BUSY;
            end
            default: begin
            end
        endcase
    end

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            bcd_buf <= 0;
            out_idx <= 0;
            data_out <= '0;
            data_out_en <= 0;
        end else begin
            case (next_state)
                S_IDLE: begin
                    data_out <= '0;
                    data_out_en <= 0;
                    out_idx <= 0;
                end
                S_START_TX: begin
                    bcd_buf <= bcd_in;
                    data_out_en <= 0;
                end
                S_WAIT_BUSY: begin
                    data_out_en <= 0;
                end
                S_TX: begin
                    data_out_en <= 1;
                    out_idx <= out_idx + 1'b1;
                    case (out_idx)
                        0: data_out <= 8'd48 + {4'b0, bcd_buf[11:8]};
                        1: data_out <= 8'd48 + {4'b0, bcd_buf[7:4]};
                        2: data_out <= 8'd48 + {4'b0, bcd_buf[3:0]};
                        3: data_out <= 8'd13;
                        4: data_out <= 8'd10;
                    endcase
                end
                default: begin
                end
            endcase
        end
    end

endmodule
