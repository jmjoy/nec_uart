module syncer #(
    parameter int WIDTH     = 1,
    parameter bit RESET_VAL = 1'b0
) (
    input  logic             sys_clk,
    input  logic             sys_rst_n,
    input  logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out,
    output logic             posedge_out,
    output logic             negedge_out
);

    // =========================================================
    // Gowin 优化部分
    // =========================================================
    // (* syn_keep = 1 *) 告诉 Gowin 综合器：
    // 不要优化这些线/寄存器，保留它们原本的结构。
    // 这可以防止综合器因为觉得"逻辑冗余"而把两级触发器合并成一级。

    (* syn_keep = 1 *)logic [WIDTH-1:0] sync_r0;
    (* syn_keep = 1 *)logic [WIDTH-1:0] sync_r1;

    // 注意：有些版本的综合器可能偏好 syn_preserve
    // 如果 syn_keep 不生效，可以尝试 (* syn_preserve = 1 *)

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sync_r0 <= {WIDTH{RESET_VAL}};
            sync_r1 <= {WIDTH{RESET_VAL}};
        end else begin
            sync_r0 <= in;
            sync_r1 <= sync_r0;
        end
    end

    assign out = sync_r1;

    assign posedge_out = !sync_r0 && sync_r1;

    assign negedge_out = sync_r0 && !sync_r1;

endmodule
