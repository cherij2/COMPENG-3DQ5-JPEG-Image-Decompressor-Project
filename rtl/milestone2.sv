
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

// This is the top module (same as experiment4 from lab 5 - just module renamed to "project")
// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA
module milestone2 (

	input logic Clock,
	input logic Resetn,
	
	input logic[15:0] SRAM_read_data,
	
	output logic[17:0] SRAM_address,
	output logic[15:0] SRAM_write_data,
	output logic SRAM_we_n,
	output logic M2_Stop,
	input logic M2_Enable
	
);


logic [6:0] address_1, address_2, address_3, address_4, address_5, address_6;
logic [31:0] write_data_b [2:0];
logic write_enable_b [2:0];
logic [31:0] read_data_a [2:0];
logic [31:0] read_data_b [2:0];

//D-RAMS

//3rd DRAM
dual_port_RAM2 dual_port_RAM_inst2 (
	.address_a ( address_5 ),
	.address_b ( address_6 ),
	.clock ( Clock ),
	.data_a ( 32'h00 ),
	.data_b ( write_data_b[2] ),
	.wren_a ( 1'b0 ),
	.wren_b ( write_enable_b[2] ),
	.q_a ( read_data_a[2] ),
	.q_b ( read_data_b[2] )
	);
	
//2nd DRAM
dual_port_RAM1 dual_port_RAM_inst1 (
	.address_a ( address_3 ),
	.address_b ( address_4 ),
	.clock ( Clock ),
	.data_a ( 32'h00 ),
	.data_b ( write_data_b[1] ),
	.wren_a ( 1'b0 ),
	.wren_b ( write_enable_b[1] ),
	.q_a ( read_data_a[1] ),
	.q_b ( read_data_b[1] )
	);

//1ST DRAM
dual_port_RAM0 dual_port_RAM_inst0 (
	.address_a ( address_1 ),
	.address_b ( address_2 ),
	.clock ( Clock ),
	.data_a ( 32'h00 ),
	.data_b ( write_data_b[0] ),
	.wren_a ( 1'b0 ),
	.wren_b ( write_enable_b[0] ),
	.q_a ( read_data_a[0] ),
	.q_b ( read_data_b[0] )
	);




//REGISTERS HERE
logic [2:0] col_counter; // goes to 8
logic [2:0] row_counter; //goes to 8

logic [17:0] read_data_counter;

logic even_odd_counter;




//REGISTERS HERE




inv_cos_states M2State;
always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
		//insert everything with a register here and set to 0
		
		SRAM_address <= 18'd0;
		SRAM_write_data <= 16'd0;
		SRAM_we_n <= 1'b1;
		M2_Stop <= 1'b0;
		
		col_counter <= 3'd0;
		row_counter <= 3'd0;
		
		M2State <= S_M2_IDLE;
	
	
	end else begin
		
		case (M2State)
		S_M2_IDLE: begin
			if(M2_Enable == 1'b1) begin
				col_counter <= 3'd0;
				row_counter <= 3'd0;
				
				read_data_counter <= 3'd0;
				
				
				M2State <= S_M2_IDLE;
			end
		end
		
		S_Read_Lead_In1: begin
			
			SRAM_address <= S_Y_START_ADDRESS + read_data_counter;
			
			
			M2State <= S_Read_CommonCase2;
		end
		
		S_Read_CommonCase2: begin
			
			
			
			M2State <= S_Read_CommonCase3;
		end
		
		S_Read_CommonCase3: begin
			
			
			
			M2State <= S_Read_CommonCase4;
		end
		S_Read_CommonCase4: begin
			
			
			
			M2State <= S_Read_CommonCase5;
		end
		
		S_Read_CommonCase5: begin
			
			
			
			M2State <= S_Read_CommonCase6;
		end
		
		S_Read_CommonCase6: begin
			
			
			
			M2State <= S_Read_CommonCase7;
		end
		S_Read_CommonCase7: begin
			
			
			
			M2State <= S_Read_CommonCase8;
		end
		S_Read_CommonCase8: begin
			
			
			
			M2State <= S_Read_CommonCase9;
		end
		
		S_Read_CommonCase9: begin
			
			
			
			M2State <= S_Read_CommonCase10;
		end
		
		S_Read_CommonCase10: begin
			
			
			
			M2State <= S_Read_CommonCase11;
		end
		
		S_Read_CommonCase11: begin
			
			
			
			M2State <= S_Read_CommonCase12;
		end
		
		S_Read_CommonCase12: begin
			
			
			
			M2State <= S_Read_CommonCase13;
		end
		
		S_Read_CommonCase13: begin
			
			
			
			M2State <= S_Read_CommonCase14;
		end
		
		S_Read_CommonCase14: begin
			
			
			
			M2State <= S_Read_CommonCase15;
		end
		
		S_Read_CommonCase15: begin
			
			
			
			M2State <= S_Read_CommonCase16;
		end
		
		S_Read_CommonCase16: begin
			
			
			
			M2State <= S_Read_Lead_Out1;
		end
		
		S_Read_Lead_Out1: begin
			
			
			
			M2State <= S_M2_IDLE;
		end
		
		
		
		
	
		
		
		endcase
	end
end
endmodule

