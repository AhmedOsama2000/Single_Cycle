module RV32I #(
	parameter XLEN   = 32,
	parameter IMM    = 32 
)
(
	input 	wire 						rst_n,
	input 	wire 						CLK,
	input	wire 						EN_PC
);

// -------------------------------------- Internal Signals -------------------------------------- //
// -------------------------------------- PC Signals -------------------------------------- //
wire [XLEN-1:0]   pc_prog_out;  
wire [XLEN-1:0]   pc4_to_reg; 
// -------------------------------------- IMemory Signals -------------------------------------- //
wire [31:0] 	  get_instr;
// -------------------------------------- DMemory Signals -------------------------------------- //
wire [XLEN-1:0]   data_mem_out;
// -------------------------------------- Controller Signals -------------------------------------- //
wire [6:0]        opcode = get_instr[6:0];
wire [6:0]   	  funct7 = get_instr[31:25];
wire [2:0]   	  funct3 = get_instr[14:12];
wire 	          mem_wr_en;
wire [1:0]   	  src_to_reg;
wire              reg_wr_En;
wire              alu_src1_sel;
wire              alu_src2_sel;
wire              branch;
wire              jump;
wire              Sub;
wire    [2:0]     alu_ctrl;
// -------------------------------------- IMM_EXT Signals -------------------------------------- //
wire [XLEN-1:0]   imm_o;
// -------------------------------------- RegFile Signals -------------------------------------- //
wire [XLEN-1:0]   rs1_out;
wire [XLEN-1:0]   rs2_out;
wire [XLEN-1:0]   reg_rd;
// -------------------------------------- ALU SIGNALS -------------------------------------- //
wire              branch_taken;
wire              overflow;
wire [XLEN-1:0]   rs1_src;
wire [XLEN-1:0]   rs2_src;
wire [XLEN-1:0]   result;
/*******************************************************************
PROGRAM COUNTER
*******************************************************************/
PC prog_count (
	// input
	.CLK(CLK),
	.rst_n(rst_n),
	.PC_Addr(result),
	.En_PC(EN_PC),
	.PC_Change(pc_change),
	// output
	.PC_Out(pc_prog_out)     
); 
/*******************************************************************
INSTRUCTION Memory
*******************************************************************/
IMem instr_mem (
	.PC(pc_prog_out),
	.instr(get_instr)
);
/*******************************************************************
CONTROLLER
*******************************************************************/
Control_Unit Controller (
	.Opcode(opcode),
	.Funct7(funct7),
	.Funct3(funct3),
	// Memory Control Signals
	.MEM_Wr_En(mem_wr_en),
	// Register Write Srcs
	.Src_to_Reg(src_to_reg),
	// RegFile Control Signals
	.Reg_Wr_En(reg_wr_En),
	// Integer ALU Source signals
	.ALU_Src1_Sel(alu_src1_sel),
	.ALU_Src2_Sel(alu_src2_sel),
	// PC signals
	.EN_PC(EN_PC),
	.Branch(branch),
	.Jump(jump),
	// ALU ADD/SUB Operation
	.Sub(Sub),
	// To ALU Decoders
	.ALU_Ctrl(alu_ctrl)
);
/*******************************************************************
REGISTER FILES
*******************************************************************/
RegFile #(
	.XLEN(XLEN)
)
	Register_File 
(
	.rst_n(rst_n),
	.CLK(CLK),
	.Rs1_rd(get_instr[19:15]),
	.Rs2_rd(get_instr[24:20]),
	.Reg_Wr(reg_wr_En),
	.Rd_Wr(get_instr[11:7]),
	.Rd_In(reg_rd),
	.Rs1_Out(rs1_out),
	.Rs2_Out(rs2_out)
);
/*******************************************************************
IMM EXT
*******************************************************************/
IMM_EXT Imm_Ext (
	.IMM_IN(get_instr),
	.opcode(opcode),     
	.IMM_OUT(imm_o)
);
/*******************************************************************
 ALU Sources MUX Selection
*******************************************************************/
mux2x1 sel_src1 (
	.i0(rs1_out),
	.i1(pc_prog_out * 4),
	.sel(alu_src1_sel),
	.out(rs1_src)
);
mux2x1 sel_src2 (
	.i0(rs2_out),
	.i1(imm_o),
	.sel(alu_src2_sel),
	.out(rs2_src)
);
/*******************************************************************
ALU
*******************************************************************/
ALU #(
	.XLEN(XLEN)
) 
	ALU 
(
	.Rs1(rs1_src),
	.Rs2(rs2_src),
	.Sub(Sub),
	.ALU_ctrl(alu_ctrl),
	.Funct3(funct3),
	.Funct7_5(funct7[5]),
	.Result(result),
	.overflow(overflow)  
);

Branch_Unit #(
	.XLEN(XLEN)
) 
	Branch_Detect
(
	// INPUT
	.funct3(funct3),
	.Rs1(rs1_out),
	.Rs2(rs2_out),
	.En(ALU.alu_decode.D_out[4]), 
	// OUTPUT
	.Branch_taken(branch_taken)
);

assign pc_change = (branch_taken & branch) | (jump);

/*******************************************************************
 Data Memory
*******************************************************************/
DMem #(
	.XLEN(XLEN)
)
	Data_Memory
(
	.CLK(CLK),
	.rst_n(rst_n),
	.Mem_Wr_En(mem_wr_en),
	.Data_In(rs2_out),
	.Addr(result),
	.Data_Out(data_mem_out)
);
assign pc4_to_reg = pc_prog_out + 3'b100;

mux4x1 reg_src (
	.i0(result),       // From Integer ALU
	.i1(data_mem_out), // From Data Memory in case of load		   
	.i2(pc4_to_reg),   // In Case of jump instructions
	.sel0(src_to_reg[0]),
	.sel1(src_to_reg[1]),
	.out(reg_rd)
);


endmodule

