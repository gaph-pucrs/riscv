/*!\file PUCRS-RV.sv
 * PUCRS-RV VERSION - 1.0 - Public Release
 *
 * Distribution:  September 2021
 *
 * Willian Nunes   <willian.nunes@edu.pucrs.br>
 * Marcos Sartori  <marcos.sartori@acad.pucrs.br>
 * Ney calazans    <ney.calazans@pucrs.br>
 *
 * Research group: GAPH-PUCRS  <>
 *
 * \brief
 * Is the top Module of PUCRS-RV.
 *
 * \detailed
 * This is the top Module of the PUCRS-RV processor
 * and is responsible for the instantiation of the lower level modules
 * ans also defines the interface ports(inputs and outputs) os the processor.
 */
/*
`include "./pkg.sv"
`include "./fetch.sv"
`include "./decoder.sv"
`include "./operandFetch.sv"
`include "./regbank.sv"
`include "./execute.sv"
`include "./retire.sv"
*/
import my_pkg::*;

module PUCRS_RV(
    input logic         clk,
    input logic         reset,
    input logic [31:0]  instruction,                    // Object Code coming from Memory
    output logic [31:0] i_address,                      // Instruction Address in Memory
    output logic        read,                           // Memory chip enable
    output logic [31:0] read_address,                   // Data address in Memory
    input logic [31:0]  DATA_in,                        // Data coming from Memory
    output logic [31:0] DATA_out,                       // Data to be written in Memory
    output logic [31:0] write_address,
    output logic [3:0]  write);                          // Memory Write signal One Hot, each bit address 1 byte

    logic jump_wb, jump_retire, bubble, freeMem, we_retire;
    logic [3:0] write_retire;
    logic regD_we;
    logic [31:0] dataA, dataB, data_RLock;
    logic [4:0] regA_add, regB_add;
    logic [31:0] regD_add, regD_add_int;
    logic [31:0] result_wb, data_wb, New_pc;
    logic [31:0] IR, instruction_OPFetch; 
    logic [31:0] NPC_decode, NPC_OPFetch, NPC_execute;
    logic [31:0] opA_execute, opB_execute, opC_execute;
    logic [31:0] write_address_retire;
    logic [3:0] decode_tag, OPF_tag, execute_tag, retire_tag;
    fmts fmt_OPFetch;
    instruction_type i_OPFetch, i_execute, i_retire;
    xu xu_OPFetch, xu_execute;
    logic [31:0] result_retire [1:0];
    logic [31:1] wrAddr;
    logic [1:0] MEMBlock;

//////////////////////////////////////////////////////////// FETCH //////////////////////////////////////////////////////////////////////////////////

    fetch #('0) fetch1 (.clk(clk), .reset(reset), .ce(bubble), .jump(jump_wb), .result(New_pc), .instruction(instruction), 
                .i_address(i_address), .IR(IR), .NPC(NPC_decode), .tag_out(decode_tag));

//////////////////////////////////////////////////////////// DECODER ////////////////////////////////////////////////////////////////////////////////

    decoder decoder1 (.clk(clk), .reset(reset), .ce(bubble), .NPC_in(NPC_decode), .instruction(IR), .tag_in(decode_tag), 
                .NPC_out(NPC_OPFetch), .fmt_out(fmt_OPFetch), 
                .instruction_out(instruction_OPFetch), .i_out(i_OPFetch), .xu_sel(xu_OPFetch), .tag_out(OPF_tag));

/////////////////////////////////////////////////////////// OP FETCH ////////////////////////////////////////////////////////////////////////////////

    operandFetch OPfecth (.clk(clk), .reset(reset), .we(regD_we), .NPC(NPC_OPFetch),
                .fmt(fmt_OPFetch), .instruction(instruction_OPFetch), .i(i_OPFetch), .xu_sel_in(xu_OPFetch), .tag_in(OPF_tag), .dataA(dataA), 
                .dataB(dataB), .regA_add(regA_add), .regB_add(regB_add), .opA_out(opA_execute), .opB_out(opB_execute), 
                .opC_out(opC_execute), .NPC_out(NPC_execute), .i_out(i_execute), .xu_sel(xu_execute), .tag_out(execute_tag), .wrAddr(wrAddr), .bubble(bubble));

/////////////////////////////////////////////////////////// execute /////////////////////////////////////////////////////////////////////////////////

    execute execute1 (.clk(clk), .reset(reset), .NPC(NPC_execute), .opA(opA_execute), .opB(opB_execute), .opC(opC_execute),
                .i(i_execute), .xu_sel(xu_execute), .tag_in(execute_tag),  .result_out(result_retire), .jump_out(jump_retire), 
                .tag_out(retire_tag), .we_out(we_retire),
                .DATA_in(DATA_in), .read_address(read_address), .read(read), .write(write_retire));

/////////////////////////////////////////////////////////// RETIRE //////////////////////////////////////////////////////////////////////////////////

    retire retire1 (.clk(clk), .reset(reset), .result(result_retire), .jump(jump_retire), .we(we_retire),
                .tag_in(retire_tag), .reg_we(regD_we), .WrData(data_wb),
                .New_pc(New_pc), .jump_out(jump_wb),
                .write_in(write_retire),
                .write(write), .write_address(write_address), .DATA_out(DATA_out));

/////////////////////////////////////////////////////////// REGISTER BANK ///////////////////////////////////////////////////////////////////////////

    regbank regbank1 (.clk(clk), .reset(reset), .addra(regA_add), .addrb(regB_add), .addrw(wrAddr), .in(data_wb), .outa(dataA), .outb(dataB));

endmodule
