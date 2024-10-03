`timescale 1ps / 1fs

module fifo_tb;

  // Parameters
  parameter DATA_WIDTH = 8;
  parameter FIFO_DEPTH = 16;

  // Inputs
  reg clk;
  reg rst_n;
  reg wr_en;
  reg rd_en;
  reg [DATA_WIDTH-1:0] wr_data;

  // Outputs
  wire [DATA_WIDTH-1:0] rd_data;
  wire full;
  wire empty;

  // Instantiate the Unit Under Test (UUT)
  fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) uut (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .wr_data(wr_data),
    .rd_data(rd_data),
    .full(full),
    .empty(empty)
  );

  // Clock control task (manual clock toggling only during operations)
  task toggle_clock;
    begin
      #1 clk = ~clk; // Toggle clock
      #1 clk = ~clk; // Toggle back (generate a full clock cycle)
    end
  endtask

  // Simulation control
  initial begin
    // Initialize Inputs
    clk = 0;
    rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    wr_data = 0;

    // Initialize the dump file and variables for waveform viewing
    $dumpfile("fifo_tb.vcd");
    $dumpvars(0, fifo_tb);

    // Reset sequence
    #10 rst_n = 1;  // Release reset after 10 time units

    // First sequence: Write incrementally (0x01, 0x02, 0x03, ...) until FIFO full
    write_to_fifo_incremental();
    // Read from FIFO until empty
    read_from_fifo();

    // Finish the simulation after some time
    #500 $finish;
  end

  // Task to write incrementally (0x01, 0x02, 0x03, ...) until FIFO full
  task write_to_fifo_incremental;
    begin
      wr_data = 8'h01; // Start from 0x01
      while (!full) begin
        wr_en = 1;
        toggle_clock;  // Toggle clock during write operation
        wr_data = wr_data + 8'h01;  // Increment by 0x01 each cycle (0x01, 0x02, 0x03, ...)
      end
      wr_en = 0;  // Stop writing when FIFO is full
    end
  endtask

  // Task to read from the FIFO until empty
  task read_from_fifo;
    begin
      while (!empty) begin
        rd_en = 1;  // Enable reading from FIFO
        toggle_clock;  // Toggle clock during read operation
      end
      rd_en = 0;  // Stop reading when FIFO is empty
    end
  endtask

endmodule
