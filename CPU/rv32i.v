// rv32i.v
`include "./operate_codes.v"
module rv32i(
input   clk,
input   clrn,
input   [31:0]  instruction,
output  reg [31:0]  program_counter,
input   [31:0]  data_from_io,
output  [31:0]  data_to_memory,
output  reg [31:0]  memory_address,
output  [3:0]   memory_write,
output  memory_read,
output  io_writen,
output  io_readn,
output  [3:0]   video_memory_write,
output  video_memory_read
);

// cpu output control signals
assign  memory_write        =   bytes_write_to_memory   & {4{~io_space  & ~video_memory_space}};
assign  memory_read         =   read_memory             & ~io_space     & ~video_memory_space;
assign  data_to_memory      =   b;
assign  io_writen           = ~(|bytes_write_to_memory  & io_space);
assign  io_readn            =  ~(read_memory            & io_space);
assign  video_memory_write  =   bytes_write_to_memory   & {4{video_memory_space}};
assign  video_memory_read   =   read_memory             & video_memory_space;

// io space and video memory space
// 0xa0000000 ~ 0xbfffffff
wire io_space       = alu_out[31] & ~alu_out[30] & alu_out[29];
// 0xc0000000 ~ 0xdfffffff
wire video_memory_space = alu_out[31] & alu_out[30] & ~alu_out[29];

// PC: rogram counter
reg [31:0]  next_program_counter;
wire    [31:0]  program_counter_plus_4 = program_counter + 4;
always @ (posedge clk or negedge clrn) begin
    if (!clrn) begin
        pc <=0;
    end else begin
        pc <= next_program_counter;
    end
end

// control signals
// after caculate need to write to regs?
reg         write_reg;
// count how many bytes will write to memory
reg [3:0]   bytes_write_to_memory;
reg         read_memory;
reg [31:0]  alu_out;
reg [31:0]  memory_out;

// de instruction
wire    opcode  = instruction[6:0];
wire    rd      = instruction[11:7];
wire    funct3  = instruction[14:12];
wire    rs1     = instruction[19:15];
wire    rs2     = instruction[24:20];
wire    funct7  = instruction[31:25];
wire    sign    = instruction[31];

// immediate
wire    [31:0]  I_IMM   = {20{sign},instruction[31:20]};
wire    [31:0]  S_IMM   = {20{sign},instruction[31:20]};
wire    [31:0]  B_IMM = {20{sign},instruction[31],instruction[7],instruction[30:25],instruction[11:8]};
wire    [31:0]  U_IMM = {instruction[31:12], 12'h0};
wire    [31:0]  J_IMM = {11{sign},instruction[31],instruction[19:12],instruction[20],instruction[30,21],1'b0};
wire    [31:0]  STORE_IMM = {20{sing},instruction[31:25],instruction[11:7]};

// reg io
reg     [31:0]  register [1:31];
wire    [31:0]  data_to_register = (opcode == `LOAD) ? memory_out : alu_out;
wire    [31:0]  a = (rs1==0) ? 0 : register[rs1];
wire    [31:0]  b = (rs2==0) ? 0 : register[rs2];
always @ (posedge clk) begin
    if (write_reg && (rd != 0)) begin
        register[rd] <= data_to_register;
    end
end

// alu
always @(*) begin
    alu_out         = 0;
    memory_out      = 0;
    memory_address  = 0;
    write_reg       = 0;
    // TODO: find out this.
    // wmem = 4'b0000;
    // rmem = 0;
    bytes_write_to_memory   = 4'b0000;
    read_memory             = 0;
    write_reg               = 0;
    next_program_counter = program_counter_plus_4;
    case (opcode)
        `CALCULATE  :
            case (funct3)
                3'b000:
                case (funct7)
                    // ADD
                    7'b0000000: begin
                        alu_out     = a + b;
                        write_reg   = 1;
                    end
                    // SUB
                    7'b0100000: begin
                        alu_out = a - b;
                        write_reg   = 1;
                    end
                    default: ;
                endcase
                // SLL
                3'b001: begin
                    alu_out = a << b[4:0];
                    write_reg   = 1;
                end
                // SLT
                3'b010: begin
                    alu_out = $signed(a) < $signed(b);
                    write_reg   = 1;
                end
                // SLTU
                3'b011: begin
                    alu_out = {1'b0,a} < {1'b0,b};
                    write_reg   = 1;
                end
                // XOR
                3'b100: begin
                    alu_out = a ^ b;
                    write_reg   = 1;
                end
                3'b101:
                case (funct7)
                    // SRL
                    7'b0000000: begin
                        alu_out = a >> b[4:0];
                        write_reg   = 1;
                    end
                    // SRA
                    7'b0100000: begin
                        alu_out = $signed(a) >> b[4:0];
                        write_reg   = 1;
                    end
                    default: ;
                endcase
                // OR
                3'b110: begin
                    alu_out = a | b;
                    write_reg   = 1;
                end
                // AND
                3'b111: begin
                    alu_out = a & b;
                    write_reg   = 1;
                end
                default: ;
            endcase
        `CALCULATEI :
            case (funct3)
                // ADDI
                3'b000: begin
                    alu_out = a + I_IMM;
                    write_reg   = 1;
                end
                // SLLI
                3'b001: begin
                    alu_out = a << rs2;
                    write_reg   = 1;
                end
                // SLTI
                3'b010: begin
                    alu_out = $signed(a) < $signed(I_IMM);
                    write_reg   = 1;
                end
                // SLTU
                3'b011: begin=
                    alu_out = {1'b0,a} < {1'b0,I_IMM};
                    write_reg   = 1;
                end
                // XORI
                3'b100: begin
                    alu_out = a ^ I_IMM;
                    write_reg   = 1;
                end
                // SRAI
                3'b101:
                case (funct7)
                    // SRLI
                    7'b0000000: begin
                        alu_out = a >> rs2;
                        write_reg   = 1;
                    end
                    // SRAI
                    7'b0100000: begin
                        alu_out = $signed(a) >>> rs2;
                        write_reg   = 1;
                    end
                    default: ; 
                endcase
                // ORI
                3'b110: begin
                    alu_out = a | I_IMM;
                    write_reg   = 1;
                end
                3'b111: begin
                    alu_out = a & I_IMM;
                    write_reg   = 1;
                end
            endcase
        // LUI
        `LUI        : begin
            alu_out = U_IMM;
            write_reg   = 1;
        end
        `AUIPC      : begin
            alu_out = U_IMM;
            write_reg   = 1;
        end
        `BRANCH     :
        case (funct3)
            // BEQ
            3'b000: begin
                if (a == b)
                    next_program_counter = program_counter + B_IMM; end
            //  BNE
            3'b001: begin
                if (a != b)
                    next_program_counter = program_counter + B_IMM; end
            //  BLT
            3'b100: begin
                if ($signed(a) < $signed(b))
                    next_program_counter = program_counter + B_IMM; end
            // BGE
            3'b101: begin
                if ($signed(a) >= $signed(b))
                    next_program_counter = program_counter + B_IMM; end
            // BLTU
            3'b110: begin
                if ({1'b0, a} < {1'b0, b})
                    next_program_counter = program_counter + B_IMM; end
            // BGEU
            3'b111: begin
                if ({1'b0, a} >= {1'b0, b})
                    next_program_counter = program_counter + B_IMM; end
            default: ;
        endcase
        `JAL        : begin
            alu_out                 = program_counter_plus_4;
            next_program_counter    = program_counter + J_IMM;
            write_reg               = 1;
        end
        `JALR       : begin
            alu_out                 = program_counter_plus_4;
            next_program_counter    = a + U_IMM;
            write_reg               = 1;
        end
        `FENCE      : ;
        `CSR        : 
        case (funct3)
            3'b000:
            case (rs2)
                // ECALL
                5'b00000: begin
                ; end
                // EBREAK
                5'b00001: begin
                ; end
                default: ;
            endcase
            // CSRRW
            3'b001: begin
            ; end
            // CSRRS
            3'b010: begin
            ; end
            // CSRRC
            3'b011: begin
            ; end   
            // CSRRWI CSRRSI CSRRCI
            default: ;
        endcase
        `LOAD       :
        case (funct3)
            // LB
            3'b000: begin
                alu_out                 = a + S_IMM;
                memory_address          = alu_out;
                read_memory             = 1;
                case (memory_address[1:0])
                    2'b00:  memory_out  = {24{data_from_io[ 7]},data_from_io[ 7: 0]};
                    2'b01:  memory_out  = {24{data_from_io[15]},data_from_io[15: 8]};
                    2'b10:  memory_out  = {24{data_from_io[23]},data_from_io[23:16]};
                    2'b11:  memory_out  = {24{data_from_io[31]},data_from_io[31:24]};
                    default: ;
                endcase
                write_reg               = 1;
            end
            // LH
            3'b001: begin
                alu_out                 = a + S_IMM;
                memory_address          = {alu_out[31:1],1'h0};
                read_memory             = 1;
                case (memory_address[1])
                    1'b0:   memory_out  = {{16{data_from_io[15]}},data_from_io[15: 0]};
                    1'b1:   memory_out  = {{16{data_from_io[31]}},data_from_io[31:16]};
                    default: ;
                endcase
                write_reg               = 1;
            end
            // LW
            3'b010: begin
                alu_out                 = a + S_IMM;
                memory_address          = {alu_out[31:2],2'b00};
                memory_out              = data_from_io;
                read_memory             = 1;
                write_reg               = 1;
            end
            // LBU
            3'b100: begin
                alu_out                 = a + S_IMM;
                memory_address          = alu_out;
                read_memory             = 1;
                case (memory_address[1:0])
                    2'b00:  memory_out  = {24'b0,data_from_io[ 7: 0]};
                    2'b01:  memory_out  = {24'b0,data_from_io[15: 8]};
                    2'b10:  memory_out  = {24'b0,data_from_io[23:16]};
                    2'b11:  memory_out  = {24'b0,data_from_io[31:24]};
                    default: ;
                endcase
                write_reg               = 1;
            end
            // LHU
            3'b101: begin
                alu_out                 = a + S_IMM;
                memory_address          = {alu_out[31:1], 1'b0};
                read_memory             = 1;
                case (memory_address[1])
                    1'b0: memory_out    = {16'b0, data_from_io[15:0]};
                    1'b1: memory_out    = {16'b0, data_from_io[31:16]};
                    default: ;
                endcase
                write_reg               = 1;
            end
            default: ;
        endcase
        `STORE      :
        case (funct3)
            // SB
            3'b000: begin
                alu_out                 = a + STORE_IMM;
                memory_address          = alu_out;
                bytes_write_to_memory   = 4'b0001 << alu_out[1:0];
            end
            // SH
            3'b001: begin
                alu_out                 = a + STORE_IMM;
                memory_address          = {alu_out[31:1], 1'b0};
                bytes_write_to_memory   = 4'b0011 << {alu_out[1], 1'b0};
            end
            // SW
            3'b010: begin
                alu_out                 = a + STORE_IMM;
                memory_address          = {alu_out[31:2],2'b0};
                bytes_write_to_memory   = 4'b1111;
            end
            default: ;
        endcase
        default: ;
    endcase
end

endmodule // rv32i