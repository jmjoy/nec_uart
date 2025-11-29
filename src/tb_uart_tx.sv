`timescale 1ns / 1ns

localparam CLK_PERIOD = 20;

module tb_uart_tx;

    logic sys_clk;
    logic sys_rst_n;

    logic [7:0] data;
    logic data_en;
    logic busy;
    logic tx;

    initial begin
        #0 begin
            sys_clk   = 0;
            sys_rst_n = 0;
            data = '0;
            data_en = '0;
        end
        #200 begin
            data = 8'b1010_0011;
            data_en = 1'b1;
            sys_rst_n = 1;
        end
        # 200 begin
            data_en = 1'b0;
        end
        #173600 begin
            $finish;
        end
    end

    always #(CLK_PERIOD / 2) begin
        sys_clk = ~sys_clk;
    end

    uart_tx u_uart_tx (
        .sys_clk  (sys_clk),
        .sys_rst_n(sys_rst_n),

        .data(data),
        .data_en(data_en),
        .busy(busy),
        .tx(tx)
    );

endmodule
