module top_nec_uart #(
    parameter logic [27:0] MAX_TIMER_CNT = 27'd25_000_000 - 27'b1
) (
    input logic sys_clk,
    input logic sys_rst_n,

    input  logic remote_in,
    output logic uart_out
);

    logic [7:0] nec_data;
    logic nec_data_en;
    logic nec_repeat_en;

    g::bcd_t bcd;
    logic bcd_en;
    logic uart_busy;
    logic [7:0] data;
    logic data_en;

    // logic [7:0] numbers[9:0];
    // assign numbers[0] = 8'd0;
    // assign numbers[1] = 8'd6;
    // assign numbers[2] = 8'd23;
    // assign numbers[3] = 8'd128;
    // assign numbers[4] = 8'd255;

    // logic [27:0] timer_cnt;

    // logic [ 3:0] num_idx;

    // always_ff @(posedge sys_clk or negedge sys_rst_n) begin
    //     if (!sys_rst_n) begin
    //         timer_cnt <= 0;
    //         num_idx <= 0;
    //         bin <= 0;
    //         bcd_en <= 0;
    //     end else if (timer_cnt == MAX_TIMER_CNT) begin
    //         timer_cnt <= 0;
    //         bcd_en <= 0;
    //     end else if (timer_cnt == MAX_TIMER_CNT / 2) begin
    //         if (num_idx == 4) begin
    //             num_idx <= 0;
    //         end else begin
    //             num_idx <= num_idx + 1'b1;
    //         end
    //         bin <= numbers[num_idx];
    //         bcd_en <= 1;
    //         timer_cnt <= timer_cnt + 1'b1;
    //     end else begin
    //         timer_cnt <= timer_cnt + 1'b1;
    //         bcd_en <= 0;
    //     end
    // end

    nec u_nec (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .remote_in(remote_in),
        .data_out(nec_data),
        .data_out_en(nec_data_en),
        .repeat_out_en(nec_repeat_en)
    );

    nec_bcd u_nec_bcd (
        .sys_clk  (sys_clk),
        .sys_rst_n(sys_rst_n),

        .data_in(nec_data),
        .data_in_en(nec_data_en),
        .repeat_in_en(nec_repeat_en),

        .bcd_out(bcd),
        .bcd_out_en(bcd_en)
    );

    bcd_display u_bcd_display (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .bcd_in_en(bcd_en),
        .bcd_in(bcd),
        .busy_in(uart_busy),
        .data_out(data),
        .data_out_en(data_en)
    );

    uart_tx u_uart_tx (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .data(data),
        .data_en(data_en),
        .busy(uart_busy),
        .tx(uart_out)
    );

endmodule
