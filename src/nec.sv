module nec (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic remote_in,

    output logic [7:0] data_out,
    output logic data_out_en,
    output logic repeat_out_en
);

    localparam int MAX_SAMPLING_CNT = g::CLK_FREQ / g::NEC_SAMPLING_RATE / 2 - 1;
    localparam int SAMPLING_9MS_CNT = 9_000 / (1_000_000 / g::NEC_SAMPLING_RATE);
    localparam int SAMPLING_4_5MS_CNT = 4_500 / (1_000_000 / g::NEC_SAMPLING_RATE);
    localparam int SAMPLING_2_25MS_CNT = 2_250 / (1_000_000 / g::NEC_SAMPLING_RATE);
    localparam int SAMPLING_562_5US_CNT = 562_500 / (1_000_000_000 / g::NEC_SAMPLING_RATE);
    localparam int SAMPLING_1_6875MS_CNT = 1_687_500 / (1_000_000_000 / g::NEC_SAMPLING_RATE);
    localparam logic [5:0] MAX_DATA_CNT = 32;

    typedef enum logic [4:0] {
        S_IDLE = 0,
        S_WAIT_BURST_9MS = 1,
        S_START_JUDGE = 2,
        S_JUDGEING = 3,
        S_FIN_REPEAT = 4,
        S_START_DATA_562_5US = 5,
        S_WAIT_DATA_562_5US = 6,
        S_START_DATA_JUDGE = 7,
        S_WAIT_DATA_JUDGE = 8,
        S_GET_DATA_0 = 9,
        S_GET_DATA_1 = 10,
        S_CHK_DATA = 11,
        S_FIN_DATA = 12,
        S_FIN = 13
    } state_t;

    state_t current_state;
    state_t next_state;

    int sampling_cnt;
    logic sampling_clk;

    logic remote_in0;
    logic remote_in1;

    int timer_cnt;

    logic [5:0] data_cnt;
    logic [31:0] data_buf;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            remote_in0 <= 0;
            remote_in1 <= 0;
        end else begin
            remote_in0 <= remote_in;
            remote_in1 <= remote_in0;
        end
    end

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sampling_cnt <= 0;
            sampling_clk <= 0;
        end else if (sampling_cnt == MAX_SAMPLING_CNT) begin
            sampling_cnt <= 0;
            sampling_clk <= !sampling_clk;
        end else begin
            sampling_cnt <= sampling_cnt + 1;
        end
    end

    always_ff @(posedge sampling_clk or negedge sys_rst_n) begin
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
                if (!remote_in1) begin
                    next_state = S_WAIT_BURST_9MS;
                end
            end
            S_WAIT_BURST_9MS: begin
                if (timer_cnt >= SAMPLING_9MS_CNT - 3 && timer_cnt <= SAMPLING_9MS_CNT + 3 && remote_in1) begin
                    next_state = S_START_JUDGE;
                end else if (timer_cnt > SAMPLING_9MS_CNT + 3) begin
                    next_state = S_IDLE;
                end else if (remote_in1) begin
                    next_state = S_IDLE;
                end
            end
            S_START_JUDGE: begin
                next_state = S_JUDGEING;
            end
            S_JUDGEING: begin
                if (timer_cnt >= SAMPLING_2_25MS_CNT - 3 && timer_cnt <= SAMPLING_2_25MS_CNT + 3) begin
                    if (!remote_in1) begin
                        next_state = S_FIN_REPEAT;
                    end
                end else if (timer_cnt >= SAMPLING_4_5MS_CNT - 3 && timer_cnt <= SAMPLING_4_5MS_CNT + 3) begin
                    if (!remote_in1) begin
                        next_state = S_START_DATA_562_5US;
                    end
                end else if (timer_cnt > SAMPLING_4_5MS_CNT + 3) begin
                    next_state = S_IDLE;
                end
            end
            S_FIN_REPEAT: begin
                next_state = S_FIN;
            end
            S_START_DATA_562_5US: begin
                next_state = S_WAIT_DATA_562_5US;
            end
            S_WAIT_DATA_562_5US: begin
                if (timer_cnt >= SAMPLING_562_5US_CNT - 3 && timer_cnt <= SAMPLING_562_5US_CNT + 3) begin
                    if (remote_in1) begin
                        next_state = S_START_DATA_JUDGE;
                    end
                end else if (timer_cnt > SAMPLING_562_5US_CNT + 3) begin
                    next_state = S_IDLE;
                end
            end
            S_START_DATA_JUDGE: begin
                next_state = S_WAIT_DATA_JUDGE;
            end
            S_WAIT_DATA_JUDGE: begin
                if (timer_cnt >= SAMPLING_562_5US_CNT - 3 && timer_cnt <= SAMPLING_562_5US_CNT + 3) begin
                    if (!remote_in1) begin
                        next_state = S_GET_DATA_0;
                    end
                end else if (timer_cnt >= SAMPLING_1_6875MS_CNT- 3 && timer_cnt <= SAMPLING_1_6875MS_CNT + 3) begin
                    if (!remote_in1) begin
                        next_state = S_GET_DATA_1;
                    end
                end else if (timer_cnt > SAMPLING_1_6875MS_CNT + 3) begin
                    next_state = S_IDLE;
                end
            end
            S_GET_DATA_0, S_GET_DATA_1: begin
                if (data_cnt == MAX_DATA_CNT) begin
                    next_state = S_CHK_DATA;
                end else begin
                    next_state = S_START_DATA_562_5US;
                end
            end
            S_CHK_DATA: begin
                if (data_buf[31:24] == ~data_buf[23:16]) begin
                    next_state = S_FIN_DATA;
                end else begin
                    next_state = S_IDLE;
                end
            end
            S_FIN_DATA: begin
                next_state = S_FIN;
            end
            S_FIN: begin
                if (remote_in1) begin
                    next_state = S_IDLE;
                end
            end
            default: begin
            end
        endcase
    end

    always_ff @(posedge sampling_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            timer_cnt <= 0;
            data_cnt <= 0;
            data_out <= 0;
            data_out_en <= 0;
            repeat_out_en <= 0;
            data_buf <= 0;
        end else begin
            case (next_state)
                S_IDLE: begin
                    timer_cnt <= 0;
                    data_cnt <= 0;
                    data_out <= 0;
                    data_out_en <= 0;
                    repeat_out_en <= 0;
                    data_buf <= 0;
                end
                S_WAIT_BURST_9MS: begin
                    timer_cnt <= timer_cnt + 1;
                end
                S_START_JUDGE: begin
                    timer_cnt <= 0;
                end
                S_JUDGEING: begin
                    timer_cnt <= timer_cnt + 1;
                end
                S_FIN_REPEAT: begin
                    repeat_out_en <= 1;
                end
                S_START_DATA_562_5US: begin
                    timer_cnt <= 0;
                end
                S_WAIT_DATA_562_5US: begin
                    timer_cnt <= timer_cnt + 1;
                end
                S_START_DATA_JUDGE: begin
                    timer_cnt <= 0;
                end
                S_WAIT_DATA_JUDGE: begin
                    timer_cnt <= timer_cnt + 1;
                end
                S_GET_DATA_0: begin
                    data_buf[data_cnt[4:0]] <= 1'b0;
                    data_cnt <= data_cnt + 1'b1;
                end
                S_GET_DATA_1: begin
                    data_buf[data_cnt[4:0]] <= 1'b1;
                    data_cnt <= data_cnt + 1'b1;
                end
                S_FIN_DATA: begin
                    data_out <= data_buf[23:16];
                    data_out_en <= 1;
                end
                S_FIN: begin
                    data_out <= 0;
                    data_out_en <= 0;
                    repeat_out_en <= 0;
                end
                default: begin
                end
            endcase
        end
    end

endmodule
