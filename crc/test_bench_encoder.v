`include "encoder.v"

module test_tb;
  reg clk = 0;
  reg  [7:0] in;
  reg  [7:0] gen;
  wire [7:0] out;
  CRCEncoder encoder(clk, in, gen, out);
  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, test_tb);
    gen = 'h19;
    in = 'b00000001;
    #1 clk = ~clk;
    #1 clk = ~clk;
    in = 'b00000010;
    #1 clk = ~clk;
    #1 clk = ~clk;
    $finish;
end
endmodule
