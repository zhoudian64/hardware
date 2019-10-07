module CRCDecoder(
  input wire clk,
  input wire [CRC_LENGTH-1:0] in,
  input wire [CRC_LENGTH-1:0] generator,
  output wire ok
);
  parameter CRC_LENGTH = 8;
  reg [CRC_LENGTH+CRC_LENGTH-1:0] buffer = 0;
  assign ok = buffer[CRC_LENGTH-1:0] == 0;
  integer i;
  always @(posedge clk) begin
    buffer = {buffer[CRC_LENGTH-1:0],in};
    for (i = 0; i < 8; i = i + 1) begin
      if (buffer[CRC_LENGTH+CRC_LENGTH-i-1]) begin
        buffer[CRC_LENGTH+CRC_LENGTH-i-2 -: 8] ^= generator;
      end
    end
  end
endmodule