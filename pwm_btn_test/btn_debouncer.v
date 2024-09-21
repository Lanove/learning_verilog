module btn_debouncer#(
    parameter DEBOUNCE_TIME = 8 // Number of clock cycles to debounce
)(
    input wire clk,
    input wire rst,
    input wire btn_in,
    output reg btn_out
);
    reg [DEBOUNCE_TIME-1:0] shift_reg;
    reg btn_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 0;
            btn_state <= 0;
            btn_out <= 0;
        end else begin
            shift_reg <= {shift_reg[DEBOUNCE_TIME-2:0], btn_in};
            if (&shift_reg) begin
                btn_state <= 1;
            end else if (~|shift_reg) begin
                btn_state <= 0;
            end
            btn_out <= btn_state; // Assign btn_out within the always block
        end
    end
endmodule