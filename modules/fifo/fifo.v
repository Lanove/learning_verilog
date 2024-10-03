module fifo #(parameter DATA_WIDTH = 8, parameter FIFO_DEPTH = 16)
(
    input wire clk,              // Clock signal
    input wire rst_n,            // Reset signal (active low)
    input wire wr_en,            // Write enable
    input wire rd_en,            // Read enable
    input wire [DATA_WIDTH-1:0] wr_data, // Data to write
    output reg [DATA_WIDTH-1:0] rd_data, // Data to read
    output wire full,            // FIFO full flag
    output wire empty            // FIFO empty flag
);

    reg [DATA_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0]; // FIFO memory array
    reg [$clog2(FIFO_DEPTH)-1:0] rd_ptr;  // Read pointer
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr;  // Write pointer
    reg [FIFO_DEPTH:0] fifo_count;        // FIFO counter

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            fifo_mem[wr_ptr] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_data <= fifo_mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // FIFO counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_count <= 0;
        end else if (wr_en && !rd_en && !full) begin
            fifo_count <= fifo_count + 1;
        end else if (!wr_en && rd_en && !empty) begin
            fifo_count <= fifo_count - 1;
        end
    end

    // Flags
    assign full = (fifo_count == FIFO_DEPTH);
    assign empty = (fifo_count == 0);

endmodule
