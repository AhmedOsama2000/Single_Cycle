module Control_Unit #(
	parameter ALU_DECODER_IN = 3
)
(
	// INPUT
	input wire [6:0]  Opcode,	
	input wire [6:0]  Funct7,
	input wire [2:0]  Funct3,
	// OUTPUT
	// Memory Control Signals
	output wire       MEM_Wr_En,
	// Register Write Source
	output wire [1:0] Src_to_Reg,
	// RegFile Control Signals
	output wire 	  Reg_Wr_En,
	// Integer ALU Source signals
	output wire 	  ALU_Src1_Sel,
	output wire 	  ALU_Src2_Sel,
	output wire       Sub,
	// PC signals
	output wire       EN_PC,
	output wire       Branch,
	output wire       Jump,
	// To ALU Decoders
	output wire [ALU_DECODER_IN-1:0] ALU_Ctrl
);

Main_Decoder main_ctrl (
	.Opcode(Opcode),
	.Funct7_6_2(Funct7[6:2]),
	// Memory Control Signals
	.MEM_Wr_En(MEM_Wr_En),
	// Register Write Source
	.Src_to_Reg(Src_to_Reg),
	// RegFile Control Signals
	.Reg_Wr_En(Reg_Wr_En),
	// Integer ALU Source signals
	.ALU_Src1_Sel(ALU_Src1_Sel),
	.ALU_Src2_Sel(ALU_Src2_Sel),
	// PC signals
	.EN_PC(EN_PC),
	.Branch(Branch),
	.Jump(Jump)
);

ALU_Control alu_ctrl  
(
	.Funct3(Funct3),
	.Funct7_5(Funct7[5]),
	.Funct7_0(Funct7[0]),
	.opcode(Opcode)
	.Sub(Sub),
	.EN_PC(EN_PC),
	.ALU_Ctrl(ALU_Ctrl)
);

endmodule