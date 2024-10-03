`timescale 1ps / 1fs

module inverter_tb;

  // Inputs
  reg input_signal;

  // Outputs
  wire output_signal;

  // Instantiate the Unit Under Test (UUT)
  inverter uut (
    .input_signal(input_signal),
    .output_signal(output_signal)
  );

  // Clock generation (optional if needed for your setup)
  // But since this is a simple inverter, we'll just toggle the input manually.

  // Simulation control
  initial begin
    // Initialize Inputs
    input_signal = 0;

    // Initialize the dump file and variables for waveform viewing
    $dumpfile("inverter_tb.vcd");
    $dumpvars(0, inverter_tb);

    // Test different input values with a delay
    #10 input_signal = 1;   // Apply a high signal after 10 time units
    #10 input_signal = 0;   // Return to low signal after 10 time units
    #10 input_signal = 1;   // Toggle back to high
    #10 input_signal = 0;   // Toggle back to low

    // Finish the simulation after some time
    #100 $finish;
  end

endmodule
