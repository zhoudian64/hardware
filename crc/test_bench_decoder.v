`include "decoder.v"

module test_tb;
  reg clk = 0;
  reg [7:0] in;
  reg [7:0] gen;
  wire out;
  CRCDecoder decoder(clk, in, gen, out);
  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, test_tb);
    gen = 'h07;
    in = 'hab;
    #1 clk = ~clk;
    #1 clk = ~clk;
    in = 'hcd;
    #1 clk = ~clk;
    #1 clk = ~clk;
    in = 'hef;
    #1 clk = ~clk;
    #1 clk = ~clk;
    in = 'h23;
    #1 clk = ~clk;
    #1 clk = ~clk;
    $finish;
end
endmodule
