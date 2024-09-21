module pwm_btn_test(
    input wire clk,
    input wire duty_btn,
    input wire psc_btn,
    input wire rst_btn,
    output wire out_pwm,
    output wire pwm_overflow_flag
);
    localparam DATA_WIDTH = 8;
    localparam INCREMENT = (2 ** DATA_WIDTH) / 10; // 10% of 2^DATA_WIDTH
    
    reg [DATA_WIDTH - 1:0] duty = 'b0;
    reg [DATA_WIDTH - 1:0] psc = 'b0;
    reg [7:0] debounce_psc = 'd0;
    reg [DATA_WIDTH - 1:0] top = 'd255;
    reg [7:0] pwm_cf_reg = 'b00000011; // PWM enable, count up mode

    wire debounce_clk;
    wire rst_btn_debounced;
    wire psc_btn_debounced;
    wire duty_btn_debounced;
    wire debounce_rst = 1'b0;
    // wire pwm_overflow_flag;

    // Prescaler for debounce clock
    reg [DATA_WIDTH - 1:0] prescaler_cnt = 0;
    reg debounce_clk_reg = 0;
    always @(posedge clk) begin
        if (prescaler_cnt < debounce_psc) begin
            prescaler_cnt <= prescaler_cnt + 1;
        end else begin
            prescaler_cnt <= 0;
            debounce_clk_reg <= ~debounce_clk_reg;
        end
    end
    assign debounce_clk = debounce_clk_reg;

    // Instantiate debouncer for each button
    btn_debouncer #(.DEBOUNCE_TIME(2)) debouncer_0 (    
        .clk(debounce_clk),
        .rst(debounce_rst),
        .btn_in(rst_btn),
        .btn_out(rst_btn_debounced)
    );

    btn_debouncer #(.DEBOUNCE_TIME(2)) debouncer_1 (    
        .clk(debounce_clk),
        .rst(debounce_rst),
        .btn_in(psc_btn),
        .btn_out(psc_btn_debounced)
    );

    btn_debouncer #(.DEBOUNCE_TIME(2)) debouncer_2 (    
        .clk(debounce_clk),
        .rst(debounce_rst),
        .btn_in(duty_btn),
        .btn_out(duty_btn_debounced)
    );
    
    pwm #(.DATA_WIDTH(DATA_WIDTH)) pwm_0 (
    .clk(clk),
    .rst(rst_btn_debounced),
    .out(out_pwm),
    .ccr(duty),
    .psc(psc),
    .top(top),
    .pwm_cf_reg(pwm_cf_reg),
    .overflow_flag_out(pwm_overflow_flag)
  );

    always @(posedge duty_btn_debounced) begin
        duty <= duty + INCREMENT;
    end

    always @(posedge psc_btn_debounced) begin
        if(psc == 0) begin
            psc <= 4;
        end else begin
            psc <= psc * 4;
        end
    end

    always @(posedge rst_btn_debounced) begin
        psc <= 'd0;
        duty <= 'd0;
    end

endmodule