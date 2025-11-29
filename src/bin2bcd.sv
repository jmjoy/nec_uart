module bin2bcd (
    input  logic [ 7:0] bin,
    output logic [11:0] bcd
);
    logic [19:0] tmp;

    always_comb begin
        tmp = {12'b0, bin};

        for (int i = 0; i < 8; i = i + 1) begin
            // Adjust BCD digits before shifting
            tmp[11:8] = (tmp[11:8] > 4'd4) ? tmp[11:8] + 4'd3 : tmp[11:8];
            tmp[15:12] = (tmp[15:12] > 4'd4) ? tmp[15:12] + 4'd3 : tmp[15:12];
            tmp[19:16] = (tmp[19:16] > 4'd4) ? tmp[19:16] + 4'd3 : tmp[19:16];
            tmp = tmp << 1;
        end

        bcd = tmp[19:8];
    end

endmodule
