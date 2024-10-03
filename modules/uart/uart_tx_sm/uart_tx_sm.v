module uart_tx (
    input wire reset_n,           // Active-low reset
    input wire baud_clk_16x,      // 16x baud clock
    input wire cfg_tx_enable,     // Transmit enable
    input wire cfg_stop_bit,      // Stop bit configuration: 0 --> 1 stop bit, 1 --> 2 stop bits
    input wire [1:0] cfg_pri_mod, // Parity mode: 00 --> None, 10 --> Even, 11 --> Odd

    input wire [7:0] tx_data,     // Data to be transmitted (written to FIFO)
    input wire tx_start,          // Start transmission (write to FIFO)
    output wire tx_ready,         // Ready to accept more data
    output wire tx,               // UART TX line (output)
    output wire fifo_full         // FIFO full flag (cannot accept more data)
);

    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;

    // Internal FIFO signals
    wire [DATA_WIDTH-1:0] fifo_data_out;
    wire fifo_rd_en;
    wire fifo_empty;

    // FIFO for buffering data to be transmitted
    uart_fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) tx_fifo (
        .clk(baud_clk_16x),           // Same clock for both FIFO and FSM
        .rst_n(reset_n),
        .wr_en(tx_start),             // Write to FIFO when tx_start is asserted
        .rd_en(fifo_rd_en),           // Read from FIFO when FSM requests
        .wr_data(tx_data),            // Data to be written to the FIFO
        .rd_data(fifo_data_out),      // Data read from the FIFO
        .full(fifo_full),             // FIFO full flag
        .empty(fifo_empty)            // FIFO empty flag
    );

    // FSM for handling the UART transmission
    reg [2:0] txstate;         // TX state
    reg [7:0] txdata;          // Data to be transmitted (loaded from FIFO)
    reg [2:0] cnt;             // Bit counter
    reg [3:0] divcnt;          // Clock division counter (16x)
    reg so;                    // TX line output register
    reg fifo_rd;               // FIFO read enable register
    wire fifo_rd_enable;       // Read from FIFO enable signal

    // Assign TX output signal
    assign tx = so;

    // FIFO read control
    assign fifo_rd_en = fifo_rd_enable;

    // TX Ready (FIFO is not full)
    assign tx_ready = !fifo_full;

    // FSM State Definitions
    parameter idle_st      = 3'b000;
    parameter xfr_data_st  = 3'b001;
    parameter xfr_pri_st   = 3'b010;
    parameter xfr_stop_st1 = 3'b011;
    parameter xfr_stop_st2 = 3'b100;

    // UART Transmit FSM
    always @(negedge reset_n or posedge baud_clk_16x) begin
        if (!reset_n) begin
            txstate <= idle_st;
            so <= 1'b1;                // Idle state keeps TX high
            cnt <= 3'b0;
            txdata <= 8'h00;
            fifo_rd <= 1'b0;
            divcnt <= 4'b0;
        end else begin
            // Divide the 16x baud clock down to 1x baud clock
            divcnt <= divcnt + 1;
            if (divcnt == 4'b0000) begin  // Perform FSM logic once every 16 clock cycles
                case (txstate)
                    idle_st: begin
                        if (!fifo_empty && cfg_tx_enable) begin
                            so <= 1'b0;           // Start bit
                            cnt <= 3'b0;
                            fifo_rd <= 1'b1;      // Read from FIFO
                            txdata <= fifo_data_out;
                            txstate <= xfr_data_st;
                        end
                    end

                    xfr_data_st: begin
                        fifo_rd <= 1'b0;          // De-assert FIFO read
                        so <= txdata[cnt];        // Transmit data bits
                        cnt <= cnt + 1;
                        if (cnt == 7) begin
                            if (cfg_pri_mod == 2'b00) begin
                                txstate <= xfr_stop_st1;  // No parity, go to stop bit
                            end else begin
                                txstate <= xfr_pri_st;    // Go to parity transmission
                            end
                        end
                    end

                    xfr_pri_st: begin
                        if (cfg_pri_mod == 2'b10) begin
                            so <= ^txdata;         // Even parity
                        end else begin
                            so <= ~(^txdata);      // Odd parity
                        end
                        txstate <= xfr_stop_st1;
                    end

                    xfr_stop_st1: begin
                        so <= 1'b1;                // Stop bit
                        if (cfg_stop_bit == 1'b0) begin
                            txstate <= idle_st;    // 1 stop bit, return to idle
                        end else begin
                            txstate <= xfr_stop_st2;  // 2 stop bits, move to second stop bit
                        end
                    end

                    xfr_stop_st2: begin
                        so <= 1'b1;                // Second stop bit
                        txstate <= idle_st;        // Return to idle after second stop bit
                    end

                    default: txstate <= idle_st;    // Default case returns to idle
                endcase
            end
        end
    end

endmodule
