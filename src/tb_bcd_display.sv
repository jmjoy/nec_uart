`timescale 1ns / 1ns

localparam CLK_PERIOD = 20;

module tb_bcd_display;

    logic sys_clk;
    logic sys_rst_n;

    g::bcd_t bcd_in;
    logic bcd_in_en;
    logic busy_in;
    logic [7:0] data_out;
    logic data_out_en;

    initial begin
        #0 begin
            sys_clk = 0;
            sys_rst_n = 0;
            bcd_in = 0;
            bcd_in_en = 0;
            busy_in = 0;
        end
        #200 begin
            sys_rst_n = 1;
        end
        #200 begin
            bcd_in = 12'b0001_0010_1000;
            bcd_in_en = 1;
        end
        #20 begin
            bcd_in_en = 0;
        end
        #20000 begin
            $finish;
        end
    end

    always #(CLK_PERIOD / 2) begin
        sys_clk = ~sys_clk;
    end

    // Monitor data_out_en and set busy_in accordingly
    always @(posedge data_out_en) begin
        #20 busy_in = 1;
        #2000 busy_in = 0;
    end

    bcd_display u_bcd_display (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .bcd_in_en(bcd_in_en),
        .bcd_in(bcd_in),
        .busy_in(busy_in),
        .data_out(data_out),
        .data_out_en(data_out_en)
    );

endmodule
