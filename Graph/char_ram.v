// 80_60_7bit_char_ram.v
module  char_ram(
input   clk,
// GPU clock
input   [12:0]  transed_address,
// info:
// char_row * 80 + char_col
// = char_row * 64 + char_row * 16 + char_col
// = { char_row, 6'h0 } + { char_row, 4'h0 } + char_col 
input   [6:0]   data_input, 
// <= input 
output  [6:0]   data_output, 
// VGA <=
input   [3:0]   write_enable);
    reg [12:0]  address_reg;
    reg [6:0]   char_ram    [0:4799];
    // need 33600 bit

    always @(posedge clk) begin
        if (write_enable[0])
            char_ram[transed_address] <= data_input;
        address_reg <= address_reg;
    end
    assign data_output = char_ram[address_reg];
endmodule


