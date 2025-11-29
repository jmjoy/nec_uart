module nec_bcd (
    input logic sys_clk,
    input logic sys_rst_n,

    input logic [7:0] data_in,
    input logic data_in_en,
    input logic repeat_in_en,

    output g::bcd_t bcd_out,
    output logic bcd_out_en
);

    typedef enum logic [2:0] {
        S_IDLE,
        S_SEND,
        S_REPEAT
    } state_t;

    state_t current_state;
    state_t next_state;

    g::bcd_t tmp_bcd;
    g::bcd_t last_bcd;

    logic [7:0] data_in0;
    logic posedge_data_in;
    logic posedge_repeat_in;

    syncer #(
        .WIDTH(8)
    ) u_syncer_data_in (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .in(data_in),
        .out(data_in0),
        .posedge_out(),
        .negedge_out()
    );

    syncer #(
        .WIDTH(1)
    ) u_syncer_data_in_en (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .in(data_in_en),
        .out(),
        .posedge_out(posedge_data_in),
        .negedge_out()
    );

    syncer #(
        .WIDTH(1)
    ) u_syncer_repeat_in_en (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .in(repeat_in_en),
        .out(),
        .posedge_out(posedge_repeat_in),
        .negedge_out()
    );

    bin2bcd u_bin2bcd (
        .bin(data_in0),
        .bcd(tmp_bcd)
    );

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
                if (posedge_data_in) begin
                    next_state = S_SEND;
                end else if (posedge_repeat_in) begin
                    next_state = S_REPEAT;
                end
            end
            S_SEND, S_REPEAT: begin
                next_state = S_IDLE;
            end
            default: begin
            end
        endcase
    end

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            bcd_out_en <= 0;
            last_bcd <= 0;
        end else begin
            case (next_state)
                S_IDLE: begin
                    bcd_out_en <= 0;
                end
                S_SEND: begin
                    bcd_out <= tmp_bcd;
                    last_bcd <= tmp_bcd;
                    bcd_out_en <= 1;
                end
                S_REPEAT: begin
                    bcd_out <= last_bcd;
                    bcd_out_en <= 1;
                end
                default: begin
                end
            endcase
        end
    end

endmodule
