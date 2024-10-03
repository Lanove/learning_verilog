module uart_rx (
    input wire reset_n,            // Active-low reset
    input wire baud_clk_16x,       // 16x baud clock
    input wire cfg_rx_enable,      // Enable signal for reception
    input wire cfg_stop_bit,       // Stop bit configuration (0: 1 stop bit, 1: 2 stop bits)
    input wire [1:0] cfg_pri_mod,  // Parity mode (0: None, 2: Even, 3: Odd)

    input wire rx,                 // UART RX line (input)
    output wire [1:0] error_ind,   // Error indicator (00: normal, 01: framing error, 10: parity error, 11: FIFO full)
    output wire [7:0] rx_data,     // Received data (from FIFO)
    output wire rx_valid,          // Data available (FIFO not empty)
    output wire fifo_empty         // FIFO empty flag
);

    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;

    // Internal FIFO signals
    wire fifo_wr_en;
    wire [DATA_WIDTH-1:0] fifo_data_in;

    // RX FIFO for buffering received data
    uart_fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) rx_fifo (
        .clk(baud_clk_16x),
        .rst_n(reset_n),
        .wr_en(fifo_wr_en),          // Write to FIFO when FSM requests it
        .rd_en(rx_valid),            // Read from FIFO when external logic requests data
        .wr_data(fifo_data_in),      // Data written to FIFO
        .rd_data(rx_data),           // Data read from FIFO
        .full(),                     // FIFO full flag (not used here, managed inside FSM)
        .empty(fifo_empty)           // FIFO empty flag
    );

    // FSM for handling the UART reception
    reg [2:0] rxstate;           // RX state
    reg [2:0] cnt;               // Bit counter
    reg [3:0] offset;            // Free-running counter
    reg [3:0] rxpos;             // Stable RX position
    reg [7:0] fifo_data;         // Data to be written to FIFO
    reg fifo_wr;                 // FIFO write enable register
    reg [1:0] error_reg;         // Error indicator register

    // Assign outputs
    assign fifo_wr_en = fifo_wr;  // Connect FIFO write enable
    assign fifo_data_in = fifo_data;
    assign error_ind = error_reg;

    // FSM State Definitions
    parameter idle_st      = 3'b000;
    parameter xfr_start    = 3'b001;
    parameter xfr_data_st  = 3'b010;
    parameter xfr_pri_st   = 3'b011;
    parameter xfr_stop_st1 = 3'b100;
    parameter xfr_stop_st2 = 3'b101;

    // UART Receive FSM
    always @(negedge reset_n or posedge baud_clk_16x) begin
        if (!reset_n) begin
            rxstate   <= idle_st;
            offset    <= 4'b0;
            rxpos     <= 4'b0;
            cnt       <= 3'b0;
            error_reg <= 2'b00;
            fifo_wr   <= 1'b0;
            fifo_data <= 8'h00;
        end else begin
            offset <= offset + 1;
            case (rxstate)
                idle_st: begin
                    fifo_wr <= 1'b0;  // Disable FIFO write
                    if (!rx && cfg_rx_enable) begin  // Start bit detected
                        if (!fifo_empty) begin  // FIFO has space
                            rxstate <= xfr_start;
                            cnt <= 3'b0;
                            rxpos <= offset + 8;  // Set stable RX position (center of the bit)
                            error_reg <= 2'b00;  // Clear errors
                        end else begin
                            error_reg <= 2'b11;  // FIFO full error
                        end
                    end
                end

                xfr_start: begin
                    if (cnt < 7 && rx) begin  // Noise or glitch detected, return to idle
                        rxstate <= idle_st;
                    end else if (cnt == 7 && !rx) begin  // Valid start bit detected
                        rxstate <= xfr_data_st;
                        cnt <= 3'b0;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end

                xfr_data_st: begin
                    if (rxpos == offset) begin
                        fifo_data[cnt] <= rx;  // Capture received data bit
                        cnt <= cnt + 1;
                        if (cnt == 7) begin
                            if (cfg_pri_mod == 2'b00) begin  // No parity
                                rxstate <= xfr_stop_st1;
                            end else begin
                                rxstate <= xfr_pri_st;  // Go to parity check
                            end
                        end
                    end
                end

                xfr_pri_st: begin
                    if (rxpos == offset) begin
                        if (cfg_pri_mod == 2'b10) begin  // Even parity
                            if (rx != ^fifo_data) error_reg <= 2'b10;  // Parity error
                        end else begin  // Odd parity
                            if (rx != ~(^fifo_data)) error_reg <= 2'b10;  // Parity error
                        end
                        rxstate <= xfr_stop_st1;
                    end
                end

                xfr_stop_st1: begin
                    if (rxpos == offset) begin
                        if (rx) begin  // Stop bit detected
                            if (cfg_stop_bit) begin  // 2 stop bits
                                rxstate <= xfr_stop_st2;
                            end else begin  // 1 stop bit
                                fifo_wr <= 1'b1;  // Write to FIFO
                                rxstate <= idle_st;
                            end
                        end else begin  // Framing error
                            error_reg <= 2'b01;  // Framing error
                            fifo_wr <= 1'b1;  // Write to FIFO
                            rxstate <= idle_st;
                        end
                    end
                end

                xfr_stop_st2: begin
                    if (rxpos == offset) begin
                        fifo_wr <= 1'b1;  // Write to FIFO
                        if (rx) begin  // Stop bit detected
                            rxstate <= idle_st;
                        end else begin  // Framing error
                            error_reg <= 2'b01;  // Framing error
                            rxstate <= idle_st;
                        end
                    end
                end

                default: rxstate <= idle_st;  // Default back to idle
            endcase
        end
    end

endmodule
