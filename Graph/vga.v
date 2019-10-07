`include "./char_ram.v"
`include "./vga_controller.v"
`include "./font_table.v"

// vga.v
module vga(
input   clk,
input   clrn,
input   clk25mhz;
input   io_writen,
input   [31:0]  video_memory_address,
input   [31:0]  data_from_cpu_to_memory,
input   video_memory_write,
output  [6:0]   ascii_in_video_ram,
output  [2:0]   red,
output  [2:0]   green,
output  [1:0]   blue,
output  readn,
output  horizontal_sync,
output  vertical_sync
);


    wire    font_dot;
    wire    [12:0]  font_address = {ascii_in_reg, font_row_address, font_col_address};
    wire    [7:0]   back_color;
    wire    [7:0]   vga_8_pixel = font_dot ? 8'hff : back_color;
    font_table table (font_address, font_dot);

    wire    [8:0]   row_address;
    wire    [9:0]   col_address;
    wire    [5:0]   char_row_address = row_address[8:3];
    wire    [6:0]   char_col_address = col_address[9:3];
    wire    [2:0]   font_row_address = row_address[2:0];
    wire    [2:0]   font_col_address = col_address[2:0];
    
    wire [12:0] vga_char_ram_address = {char_row_address,6'h0} +{char_row_address,4'h0}+char_col_address;
    wire [12:0]     char_ram_address = clk25mhz ? vga_char_ram_address : video_memory_address[14:2];
    vga_controller  vgac    (vga_8_pixel,clk25mhz,clrn,row_address,col_address,red,green,blue,readn,horizontal_sync,vertical_sync);

    wire [6:0]  ascii_in_video_ram;
    reg  [6:0]  ascii_in_reg;
    char_ram ram (clk,char_ram_address,data_from_cpu_to_memory[6:0],ascii_in_video_ram,video_memory_write&~clk25mhz);

    always @ (negedge clk25mhz) begin
        ascii_in_reg <= ascii_in_video_ram;
    end

    reg [31:0] cursor = 32'h0;
    always @(posedge clk25mhz) begin
        // if (!io_wrn) cursor <= data_input;
        // cursor <= data_input;
        if (!io_writen) cursor <= data_from_cpu_to_memory;
    end
    wire    [7:0] back_rgb  = 'b00000011;
    wire    [5:0] cars_row  = cursor[13:8];
    wire    [6:0] cars_col  = cursor[6:0];
    wire        rows_equ    = char_row_address == cars_row;
    wire        cols_equ    = char_col_address == cars_col;
    assign      back_color  = (rows_equ && cols_equ) ? back_rgb : 8'b00000011;


endmodule