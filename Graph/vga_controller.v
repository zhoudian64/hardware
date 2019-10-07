// 640_480_60_vga_controller.v
// horizontal
// 96,                  48,         640,                    16
// Sync pulse length,   Back porch, Active video(actually), Front porch
// vertical
// 2,                   32,         480,            10
// Sync pulse length,   Back porch, Active video,   Front porch
module vga_controller(
input   [7:0]   rgb_input;
// rrr_ggg_bb
input clk,
input clrn,
// clear !
output  reg [8:0]   row_address,
// pixel ram row address 480(512)lines
output  reg [9:0]   col_address,
output  reg [2:0]   red,
output  reg [2:0]   green,
output  reg [1:0]   blue,
output  reg readn,
// read pixel RAM !
output  reg horizontal_sync,
output  reg vertical_sync,
);
    reg [9:0]   horizontal_count;
    // count from 0 - 799 (1024)
    always @ (posedge clk or negedge clrn) begin
        if (!clrn) begin
            horizontal_count <= 10'h0;
            // clear
        end else if (horizontal_count == 10'd799) begin
            horizontal_count <= 10'h0;
            // /r
        end else begin
            horizontal_count <= horizontal_count + 10'h1;
            // next pixel
        end
    end

    reg [9:0]   vertical_count;
    always @ (posedge clk or negedge clrn) begin
        if (!clrn) begin
            vertical_count <= 10'h0;
            // clear
        end else if (horizontal_count == 10'd799) begin
            if (vertical_count == 10'd524) begin
                vertical_count <= 10'h0;
            end else begin
                vertical_count <= vertical_count + 10'h1;
            end
        end

    wire    [9:0]   row = vertical_count - 10'd35;
    wire    [9:0]   col = horizontal_count - 10'd143;
    wire            horizontal_sync_signal = (horizontal_count > 10'd95);
    wire            vertical_sync_signal = (vertical_count > 10'd1);
    wire            read =  (horizontal_count > 10'd142) &&
                            (horizontal_count < 10'd783) &&
                            (vertical_count > 10'd34) &&
                            (vertical_count < 10'd515);
    always @ (posedge clk) begin
        row_address <= row[8:0];
        col_address <= col;
        horizontal_sync <= horizontal_sync_signal;
        vertical_sync <= vertical_sync_signal;
        readn <= ~read;
        red <= readn ? 3'h0 : rgb_input[7:5];
        greed <= readn ? 3'h0 : rgb_input[4:2];
        blue <= readn ? 2'h0 : rgb_input[1:0];
    end
endmodule