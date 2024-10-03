module inverter (
    input wire input_signal,
    output wire output_signal
);
    assign output_signal = ~input_signal;
endmodule