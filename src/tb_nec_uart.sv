`timescale 1ns / 1ns

localparam CLK_PERIOD = 20;

module tb_nec_uart;

    logic sys_clk;
    logic sys_rst_n;

    logic uart_out;

    initial begin
        #0 begin
            sys_clk   = 0;
            sys_rst_n = 0;
        end
        #40 begin
            sys_rst_n = 1;
        end
        #2700000 begin
            $finish;
        end
    end

    always #(CLK_PERIOD / 2) begin
        sys_clk = ~sys_clk;
    end

    top_nec_uart #(
        .MAX_TIMER_CNT(27'd22500 - 27'b1)
    ) u_top_nec_uart (
        .sys_clk  (sys_clk),
        .sys_rst_n(sys_rst_n),

        .remote_in('z),
        .uart_out (uart_out)
    );

endmodule
