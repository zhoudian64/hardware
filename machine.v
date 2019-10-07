`include "./CPU/rv32i.v"
`include "./Graph/vga.v"
`include "./Keyboard/ps2_keyboard.v"
`include "./instruction_memory/ascii.v"
module machine(
input   clk,
input   clrn,
input   ps2_clk,
input   ps2_data,
output  [2:0]   r,
output  [2:0]   g,
output  [1:0]   b,
output  h_sync,
output  v_sync
);

reg clk25mhz = 1;
always @ (negedge clk or negedge clrn) begin
    if (!clrn)  clk25mhz <= 1;
    else        clk25mhz <= ~clk25mhz;
end

wire    [31:0]  instruction, program_counter;
// instruction memory
ascii inst(program_counter, instruction_memory);

wire    [31:0]  data_from_io,   data_to_memory,     memory_address;
wire    [3:0]   memory_write,   video_memory_write;
wire            memory_read,    video_memory_read,  io_readn,   io_writen;
wire            gpu_readn,      ready,              overflow;
wire    [7:0]   data_from_kbd;
assign data_from_io = io_readn ? {25'h0,ascii_in_vedio_ram} : {23'h0, ready, data_from_kbd};

rv32i           cpu(clk25mhz, clrn,
                instruction, program_counter, 
                data_from_io, data_to_memory, memory_address, 
                memory_write, memory_read, 
                io_writen, io_readn, video_memory_write, video_memory_read);
vga             gpu(clk, clrn, clk25mhz,
                io_writen, memory_address, data_to_memory, 
                video_memory_write, ascii_in_vedio_ram, 
                r, g, b, gpu_readn, h_sync, v_sync);
ps2_keyboard    kbd(clk25mhz, clrn, 
                ps2_clk, ps2_data, io_readn, 
                data_from_kbd, ready, overflow);

endmodule // machine

