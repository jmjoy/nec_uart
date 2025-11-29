module uart_tx #(
    parameter int CLK_FREQ  = g::CLK_FREQ,
    parameter int BAUD_RATE = g::BAUD_RATE
) (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic [7:0] data,
    input logic data_en,
    output logic busy,
    output logic tx
);

    localparam int MAX_CLK_CNT = CLK_FREQ / BAUD_RATE - 1;
    localparam logic [3:0] MAX_SHIFT_CNT = 10;

    int clk_cnt;

    logic [9:0] tmp_data;
    logic [3:0] shift_cnt;

    assign tmp_data = {1'b1, data, 1'b0};

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            busy <= 0;
        end else if (!busy && data_en) begin
            busy <= 1;
        end else if (shift_cnt == MAX_SHIFT_CNT) begin
            busy <= 0;
        end
    end

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_cnt <= 0;
        end else if (busy) begin
            if (clk_cnt == MAX_CLK_CNT) begin
                clk_cnt <= 0;
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end else begin
            clk_cnt <= 0;
        end
    end

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            shift_cnt <= 0;
        end else if (busy) begin
            if (clk_cnt == MAX_CLK_CNT) begin
                shift_cnt <= shift_cnt + 1'b1;
            end
        end else begin
            shift_cnt <= 0;
        end
    end

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            tx <= 1;
        end else if (busy) begin
            if (shift_cnt == MAX_SHIFT_CNT) begin
                tx <= 1;
            end else if (clk_cnt == 0) begin
                tx <= tmp_data[shift_cnt];
            end
        end else begin
            tx <= 1;
        end
    end

endmodule
