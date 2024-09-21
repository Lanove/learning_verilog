`timescale 1ps / 1fs

module pwm_tb;

  // Parameters
  parameter DATA_WIDTH = 8;

  // Inputs
  reg clk;
  reg rst;
  reg [DATA_WIDTH-1:0] ccr; // Compare value
  reg [DATA_WIDTH-1:0] psc; // Prescaler value
  reg [DATA_WIDTH-1:0] top; // Top value for the counter
  reg [7:0] pwm_cf_reg; // PWM config register

  // Outputs
  wire out;

  // Instantiate the Unit Under Test (UUT)
  pwm #(.DATA_WIDTH(DATA_WIDTH)) uut (
    .clk(clk),
    .rst(rst),
    .out(out),
    .ccr(ccr),
    .psc(psc),
    .top(top),
    .pwm_cf_reg(pwm_cf_reg)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #1 clk = ~clk; // Toggle clock every 1 time unit
  end

  // Simulation control
  initial begin
    // Initialize Inputs
    rst = 0;
    ccr = 8'd128; // 50% duty cycle
    psc = 8'd1;   // Prescaler value, divide by 2
    top = 8'd255; // Top value for the counter
    pwm_cf_reg = 8'b00000011; // PWM enable, count up mode

    // Initialize the dump file and variables for waveform viewing
    $dumpfile("pwm_tb.vcd");
    $dumpvars(0, pwm_tb);

    // Run the simulation for a specified duration
    #200000 $finish;
  end

endmodule