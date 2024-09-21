`timescale 1ns / 1ps

module pwm_btn_test_tb;
    // Parameters
    localparam DATA_WIDTH = 8;
    localparam CLK_PERIOD = 10; // Clock period in time units

    // Testbench signals
    reg clk;
    reg duty_btn;
    reg psc_btn;
    reg rst_btn;
    wire out_pwm;
    wire pwm_overflow_flag;

    // Instantiate the DUT (Device Under Test)
    pwm_btn_test dut (
        .clk(clk),
        .duty_btn(duty_btn),
        .psc_btn(psc_btn),
        .rst_btn(rst_btn),
        .out_pwm(out_pwm),
        .pwm_overflow_flag(pwm_overflow_flag)
    );

    // Clock generation
    initial begin        
        // Initialize the dump file and variables for waveform viewing
        $dumpfile("pwm_btn_test_tb.vcd");
        $dumpvars(0, pwm_btn_test_tb);

        // Initialize inputs
        duty_btn = 0;
        psc_btn = 0;
        rst_btn = 0;
        clk = 0;

        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Stimulus generation
    initial begin
        // Apply reset
        rst_btn = 1;
        #(CLK_PERIOD * 2);
        rst_btn = 0;

        forever begin
            #(CLK_PERIOD * 2000);
        end
    end

    // Counter for pwm_overflow_flag positive edges
    integer overflow_counter = 0;

    // Monitor the pwm_overflow_flag and apply duty_btn on every 5th positive edge
    always @(posedge pwm_overflow_flag) begin
        overflow_counter = overflow_counter + 1;
        if (overflow_counter == 5) begin
            duty_btn = 1;
            #(CLK_PERIOD * 100);
            duty_btn = 0;
            overflow_counter = 0; // Reset the counter
        end
    end

    // Counter for duty_btn positive edges
    integer duty_btn_counter = 0;

    // Monitor the duty_btn and apply psc_btn on every 10th positive edge
    always @(posedge duty_btn) begin
        duty_btn_counter = duty_btn_counter + 1;
        if (duty_btn_counter == 10) begin
            psc_btn = 1;
            #(CLK_PERIOD * 100);
            psc_btn = 0;
            duty_btn_counter = 0; // Reset the counter
        end
    end


      // Finish simulation after a specific time
    initial begin
      #(CLK_PERIOD * 1000000); // Adjust the time as needed
      $finish;
    end

endmodule