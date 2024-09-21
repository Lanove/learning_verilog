module pwm#(
            parameter DATA_WIDTH = 8
           )(
            input wire clk,
            input wire rst,
            output wire out,
            input wire [DATA_WIDTH - 1:0] ccr, // Compare value
            input wire [DATA_WIDTH - 1:0] psc, // Prescaler value, 0 mean no prescaler, 1 is 2 times slower, 2 is 4 times slower, etc.
            input wire [DATA_WIDTH - 1:0] top, // Top value for the counter
            input wire [7:0] pwm_cf_reg, // PWM config register
            output wire overflow_flag_out
           );
  localparam T = 1'b1;
  localparam F = 1'b0;

  reg pwm_en;
  reg pwm_mode;
  reg pwm_inv;
  reg [4:0] reserved;
  
  reg overflow_flag = 'd0;

  reg [DATA_WIDTH - 1:0] cnt = 'b0;
  reg [DATA_WIDTH - 1:0] psc_cnt = 'b0;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pwm_en <= 1'b0;
      pwm_mode <= 1'b0;
      pwm_inv <= 1'b0;
      reserved <= 5'b0;
    end else begin
      pwm_en <= pwm_cf_reg[0]; // PWM enable is first bit
      pwm_mode <= pwm_cf_reg[1]; // PWm mode is second bit
      pwm_inv <= pwm_cf_reg[2]; // PWM inversion is third bit
      reserved <= pwm_cf_reg[7:3]; // Remaining bits is reserved
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      psc_cnt <= 'b0;
    end else if (pwm_en) begin
      if(psc_cnt < psc) begin
        psc_cnt <= psc_cnt + 1;
      end else begin
        psc_cnt <= 'b0;
        if (pwm_mode == 1'b0) begin
          // Count up mode
          if (cnt < top) begin
            cnt <= cnt + 1;
            overflow_flag <= 1'b0; // Clear overflow flag
          end else begin
            cnt <= 'b0;
            overflow_flag <= 1'b1; // Set overflow flag
          end
        end else begin
          // Count down mode
          if (cnt > 'b0) begin
            cnt <= cnt - 1;
            overflow_flag <= 1'b0; // Clear overflow flag
          end else begin
            cnt <= top;
            overflow_flag <= 1'b1; // Set overflow flag
          end
        end
      end
    end
  end

  assign out = (cnt < ccr) ? pwm_inv : ~pwm_inv;
  assign overflow_flag_out = overflow_flag;
endmodule

