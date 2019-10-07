// ps2_keyboard.v
module ps2_keyboard(
input   clk,
input   clrn,
input   ps2_clk,
input   ps2_data,
input   readn,
output  [7:0]   data,
output  ready,
output  reg  overflow,
// useless now
);
reg [9:0]   buffer;
reg [7:0]   fifo    [7:0];
reg [3:0]   count;
reg [2:0]   w_ptr,r_ptr;
//fifo write
reg [3:0]   ps2_clk_sync;

always @ (posedge clk) begin
    ps2_clk_sync <= (ps2_clk_sync[2:0], ps2_clk);
end

wire sampling = ps2_clk_sync[3] &
	            ps2_clk_sync[2] &
	            ~ps2_clk_sync[1] &
                ~ps2_clk_sync[0];

always @ (posedge clk) begin
    if (!clrn) begin
        count <= 0;
        w_ptr <= 0;
        r_ptr <= 0;
        overflow <= 0;
    end else if (sampling) begin
        if (count == 4'd10) begin
            if ((!buffer[0]) &&  
            ps2_data &&
            (^buffer[9:1])) begin
                if ((w_ptr + 3'b1) != r_ptr) begin
                    fifo[w_ptr] <= buffer[8:1];
                    w_ptr <= w_ptr + 3'b1;
                end else begin
                    overflow <= 1;
                end
            end
            count <= 0;
        end else begin
            buffer[count] <= ps2_data;
            count <= count + 4'b1;
        end
    end
    if (!readn && ready) begin
        r_ptr <= r_ptr + 3'b1;
        overflow <= 0;
    end
    assign ready = (w_ptr != r_ptr);
    assign data = fifo[r_ptr];
end


endmodule