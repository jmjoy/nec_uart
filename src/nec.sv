module nec (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic remote_in,

    output logic [7:0] data_out,
    output logic data_out_en,
    output logic repeat_out_en
);

    localparam int MAX_SAMPLING_CNT = g::CLK_FREQ / g::NEC_SAMPLING_RATE / 2 - 1;
    localparam int SAMPLING_9MS_CNT = 9 * g::NEC_SAMPLING_RATE / 1_000;
    localparam int SAMPLING_4_5MS_CNT = 45 * g::NEC_SAMPLING_RATE / 10_000;
    localparam int SAMPLING_2_25MS_CNT = 225 * g::NEC_SAMPLING_RATE / 100_000;
    localparam int SAMPLING_562_5US_CNT = 5625 * g::NEC_SAMPLING_RATE / 10_000_000;
    localparam int SAMPLING_1_6875MS_CNT = 16875 * g::NEC_SAMPLING_RATE / 10_000_000;
    localparam int TIMING_TOLERANCE = 10;
    localparam logic [5:0] MAX_DATA_CNT = 32;

    typedef enum logic [3:0] {
        S_IDLE = 0,
        S_WAIT_BURST_9MS = 1,
        S_JUDGEING = 2,
        S_FIN_REPEAT = 3,
        S_WAIT_DATA_562_5US = 4,
        S_WAIT_DATA_JUDGE = 5,
        S_GET_DATA_0 = 6,
        S_GET_DATA_1 = 7,
        S_CHK_DATA = 8,
        S_FIN_DATA = 9,
        S_FIN = 10
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

    // 入场清零脉冲：检测进入计时状态时立即清零计时器
    logic clr_timer;
    assign clr_timer = current_state != next_state;

    // 在 sampling_clk 域下同步输入信号（消除亚稳态）
    always_ff @(posedge sampling_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            remote_in0 <= 1;
            remote_in1 <= 1;
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
                if (timer_cnt >= SAMPLING_9MS_CNT - TIMING_TOLERANCE && timer_cnt <= SAMPLING_9MS_CNT + TIMING_TOLERANCE && remote_in1) begin
                    next_state = S_JUDGEING;
                end else if (timer_cnt > SAMPLING_9MS_CNT + TIMING_TOLERANCE) begin
                    next_state = S_IDLE;
                end else if (remote_in1) begin
                    next_state = S_IDLE;
                end
            end
            S_JUDGEING: begin
                if (timer_cnt >= SAMPLING_2_25MS_CNT - TIMING_TOLERANCE && timer_cnt <= SAMPLING_2_25MS_CNT + TIMING_TOLERANCE) begin
                    if (!remote_in1) begin
                        next_state = S_FIN_REPEAT;
                    end
                end else if (timer_cnt >= SAMPLING_4_5MS_CNT - TIMING_TOLERANCE && timer_cnt <= SAMPLING_4_5MS_CNT + TIMING_TOLERANCE) begin
                    if (!remote_in1) begin
                        next_state = S_WAIT_DATA_562_5US;
                    end
                end else if (timer_cnt > SAMPLING_4_5MS_CNT + TIMING_TOLERANCE) begin
                    next_state = S_IDLE;
                end
            end
            S_FIN_REPEAT: begin
                next_state = S_FIN;
            end
            S_WAIT_DATA_562_5US: begin
                if (timer_cnt >= SAMPLING_562_5US_CNT - TIMING_TOLERANCE && timer_cnt <= SAMPLING_562_5US_CNT + TIMING_TOLERANCE) begin
                    if (remote_in1) begin
                        next_state = S_WAIT_DATA_JUDGE;
                    end
                end else if (timer_cnt > SAMPLING_562_5US_CNT + TIMING_TOLERANCE) begin
                    next_state = S_IDLE;
                end
            end
            S_WAIT_DATA_JUDGE: begin
                if (timer_cnt >= SAMPLING_562_5US_CNT - TIMING_TOLERANCE && timer_cnt <= SAMPLING_562_5US_CNT + TIMING_TOLERANCE) begin
                    if (!remote_in1) begin
                        next_state = S_GET_DATA_0;
                    end
                end else if (timer_cnt >= SAMPLING_1_6875MS_CNT - TIMING_TOLERANCE && timer_cnt <= SAMPLING_1_6875MS_CNT + TIMING_TOLERANCE) begin
                    if (!remote_in1) begin
                        next_state = S_GET_DATA_1;
                    end
                end else if (timer_cnt > SAMPLING_1_6875MS_CNT + TIMING_TOLERANCE) begin
                    next_state = S_IDLE;
                end
            end
            S_GET_DATA_0, S_GET_DATA_1: begin
                if (data_cnt == MAX_DATA_CNT) begin
                    next_state = S_CHK_DATA;
                end else begin
                    next_state = S_WAIT_DATA_562_5US;
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
            // 统一计时器控制：入场清零，计时状态递增
            if (clr_timer) begin
                timer_cnt <= 0;
            end else begin
                timer_cnt <= timer_cnt + 1;
            end

            case (next_state)
                S_IDLE: begin
                    timer_cnt <= 0;
                    data_cnt <= 0;
                    data_out <= 0;
                    data_out_en <= 0;
                    repeat_out_en <= 0;
                    data_buf <= 0;
                end
                S_FIN_REPEAT: begin
                    repeat_out_en <= 1;
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
