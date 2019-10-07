module CRCEncoder(
  input wire clk,
  input wire [CRC_LENGTH-1:0] in,
  input wire [CRC_LENGTH-1:0] generator,
  output wire [CRC_LENGTH-1:0] out
);
  parameter CRC_LENGTH = 8;
  reg [CRC_LENGTH-1:0] crc_register = {CRC_LENGTH{1'b0}};
  assign out = crc_register;
  integer i=0;
  always @(posedge clk) begin
    crc_register = crc_register ^ in;
    for (i = 0; i < 8; i = i + 1) begin
      if (crc_register[7]) begin
        crc_register = (crc_register << 1) ^ generator;
      end else begin 
        crc_register <<= 1;
      end
    end
  end
endmodule