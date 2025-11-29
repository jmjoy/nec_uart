`timescale 1ns / 1ns

localparam CLK_PERIOD = 20;

module tb_nec;

    logic sys_clk;
    logic sys_rst_n;

    logic remote_in;

    initial begin
        #0 begin
            sys_clk   = 0;
            sys_rst_n = 0;
            remote_in = 1;
        end
        #20 begin
            sys_rst_n = 1;
        end
        #100 begin
            remote_in = 0;
        end

        // 发送数据 
        #9000000 begin
            remote_in = 1;
        end
        #4500000 begin
            remote_in = 0;
        end
        for (int i = 0; i < 8; i = i + 1) begin
            #562500 begin
                remote_in = 1;
            end
            #562500 begin
                remote_in = 0;
            end
        end
        for (int i = 0; i < 8; i = i + 1) begin
            #562500 begin
                remote_in = 1;
            end
            #1687500 begin
                remote_in = 0;
            end
        end
        for (int i = 0; i < 4; i = i + 1) begin
            #562500 begin
                remote_in = 1;
            end
            #562500 begin
                remote_in = 0;
            end
            #562500 begin
                remote_in = 1;
            end
            #1687500 begin
                remote_in = 0;
            end
        end
        for (int i = 0; i < 4; i = i + 1) begin
            #562500 begin
                remote_in = 1;
            end
            #1687500 begin
                remote_in = 0;
            end
            #562500 begin
                remote_in = 1;
            end
            #562500 begin
                remote_in = 0;
            end
        end
        #562500 begin
            remote_in = 1;
        end

        // 重复码
        #562500 begin
            remote_in = 0;
        end
        #9000000 begin
            remote_in = 1;
        end
        #2250000 begin
            remote_in = 0;
        end
        #562500 begin
            remote_in = 1;
        end

        // 结束
        #562500 begin
            $finish;
        end
    end

    always #(CLK_PERIOD / 2) begin
        sys_clk = ~sys_clk;
    end

    nec u_nec (
        .sys_clk  (sys_clk),
        .sys_rst_n(sys_rst_n),

        .remote_in(remote_in),

        .data_out('z),
        .data_out_en('z),
        .repeat_out_en('z)
    );

endmodule
