
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
// logic [6:0] address_1_counter, address_2_counter, address_3_counter, address_4_counter, address_5_counter, address_6_counter;
logic [31:0] write_data_b [2:0];
logic [31:0] write_data_a [2:0];
logic write_enable_b [2:0];
logic write_enable_a [2:0];
logic [31:0] read_data_a [2:0];
logic [31:0] read_data_b [2:0];

//D-RAMS

//3rd DRAM (s)
dual_port_RAM2 DRAM_inst2 (
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
	
//2nd DRAM (t)
dual_port_RAM1 DRAM_inst1 (
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

//1ST DRAM (s')
dual_port_RAM0 DRAM_inst0 (
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




//REGISTERS HERE********************************************************************************************************************************************************************************
logic [4:0] col_counter; // goes to 8
logic [4:0] row_counter; //goes to 8

logic [17:0] read_data_counter;
logic [1:0] YUV_counter_read; // go up to 3
logic [17:0] start_offset; // changes based on if we are reading y/u/v

logic [15:0] S_prime_buffer;



logic [15:0] S_prime_counter [3:0]; // to read the same 4 S prime slots for calc T
logic [31:0] T_accumulator;

logic [7:0] coeff [3:0];
logic [4:0] T_col_counter; //i dont think we need this
logic [4:0] T_row_counter;



logic [15:0] S_S_counter [7:0]; // to read the same 2 T slots for calc S
logic [15:0] S_T_counter [7:0]; // to write to the same 2 slots for in S DRAM

logic [31:0] S_accumulator[1:0];
logic [4:0] S_col_counter;
logic [4:0] S_four_counter;






//REGISTERS HERE********************************************************************************************************************************************************************************


//CHOOSEING WHERE TO READ FOR READ S' MEGASTATE



logic [31:0] Mult1_op_1, Mult1_op_2, Mult2_op_1, Mult2_op_2, Mult3_op_1, Mult3_op_2, Mult4_op_1, Mult4_op_2;
logic [63:0] Mult_result_long1, Mult_result_long2, Mult_result_long3, Mult_result_long4;
logic [31:0] Mult_result1, Mult_result2, Mult_result3, Mult_result4;

always_comb begin

	
	Mult_result_long1 = coeff[0] * Mult1_op_2;
	Mult_result_long2 = coeff[1] * Mult2_op_2;
	Mult_result_long3 = coeff[2] * Mult3_op_2;
	Mult_result_long4 = coeff[3] * Mult4_op_2;
	
	//not sure if this is clipping by proper amount
	Mult_result1 = Mult_result_long1[31:0];
	Mult_result2 = Mult_result_long2[31:0];
	Mult_result3 = Mult_result_long3[31:0];
	Mult_result4 = Mult_result_long4[31:0];

	
	//LUT HELL :(((
	//how do you put a coefficient table into an embedded RAM??????
	//pleaseeeeeee telll meeeeeeeeeeeeeeee............
	// i hate this
	//LUT HELL :(((
	case (coeff[0])//sorted into rows
		0:C0=32'sd1448;	1:C0=32'sd1448;	2:C0=32'sd1448;	3:C0=32'sd1448;	4:C0=32'sd1448; 5:C0=32'sd1448; 6:C0=32'sd1448; 7:   C0=32'sd1448;   
		8:   C0=32'sd2008; 9:C0=32'sd1702; 10:C0=32'sd1137; 11: C0=32'sd399; 12: C0=-32'sd399; 13:  C0=-32'sd1137; 14:C0=-32'sd1702; 15:C0=-32'sd2008;
		16:  C0 = 32'sd1892; 17:  C0 = 32'sd783; 18:  C0 = -32'sd783; 19:  C0 = -32'sd1892; 20:  C0 = -32'sd1892; 21:  C0 = -32'sd783; 22:  C0 = 32'sd783; 23:  C0 = 32'sd1892;   
		24:  C0 = 32'sd1702; 25:  C0 = -32'sd399; 26:  C0 = -32'sd2008; 27:  C0 = -32'sd1137; 28:  C0 = 32'sd1137; 29:  C0 = 32'sd2008; 30:  C0 = 32'sd399; 31:  C0 = -32'sd1702; 
		32:  C0 = 32'sd1448; 33:  C0 = -32'sd1448; 34:  C0 = -32'sd1448; 35:  C0 = 32'sd1448;   36:  C0 = 32'sd1448; 37:  C0 = -32'sd1448; 38:  C0 = -32'sd1448; 39:  C0 = 32'sd1448; 
		40:  C0 = 32'sd1137; 41:  C0 = -32'sd2008; 42:  C0 = 32'sd399; 43:  C0 = 32'sd1702; 44:  C0 = -32'sd1702; 45:  C0 = -32'sd399; 46:  C0 = 32'sd2008; 47:  C0 = -32'sd1137;  
		48:  C0 = 32'sd783; 49:  C0 = -32'sd1892; 50:  C0 = 32'sd1892; 51:  C0 = -32'sd783; 52:  C0 = -32'sd783; 53:  C0 = 32'sd1892; 54:  C0 = -32'sd1892; 55:  C0 = 32'sd783;   
		56:  C0 = 32'sd399; 57:  C0 = -32'sd1137; 58:  C0 = 32'sd1702; 59:  C0 = -32'sd2008; 60:  C0 = 32'sd2008; 61:  C0 = -32'sd1702; 62:  C0 = 32'sd1137; 63:  C0 = -32'sd399;   
	endcase
	case (coeff[1])
		0:C0=32'sd1448;	1:C0=32'sd1448;	2:C0=32'sd1448;	3:C0=32'sd1448;	4:C0=32'sd1448; 5:C0=32'sd1448; 6:C0=32'sd1448; 7:   C0=32'sd1448;   
		8:   C0=32'sd2008; 9:C0=32'sd1702; 10:C0=32'sd1137; 11: C0=32'sd399; 12: C0=-32'sd399; 13:  C0=-32'sd1137; 14:C0=-32'sd1702; 15:C0=-32'sd2008;
		16:  C0 = 32'sd1892; 17:  C0 = 32'sd783; 18:  C0 = -32'sd783; 19:  C0 = -32'sd1892; 20:  C0 = -32'sd1892; 21:  C0 = -32'sd783; 22:  C0 = 32'sd783; 23:  C0 = 32'sd1892;   
		24:  C0 = 32'sd1702; 25:  C0 = -32'sd399; 26:  C0 = -32'sd2008; 27:  C0 = -32'sd1137; 28:  C0 = 32'sd1137; 29:  C0 = 32'sd2008; 30:  C0 = 32'sd399; 31:  C0 = -32'sd1702; 
		32:  C0 = 32'sd1448; 33:  C0 = -32'sd1448; 34:  C0 = -32'sd1448; 35:  C0 = 32'sd1448;   36:  C0 = 32'sd1448; 37:  C0 = -32'sd1448; 38:  C0 = -32'sd1448; 39:  C0 = 32'sd1448; 
		40:  C0 = 32'sd1137; 41:  C0 = -32'sd2008; 42:  C0 = 32'sd399; 43:  C0 = 32'sd1702; 44:  C0 = -32'sd1702; 45:  C0 = -32'sd399; 46:  C0 = 32'sd2008; 47:  C0 = -32'sd1137;  
		48:  C0 = 32'sd783; 49:  C0 = -32'sd1892; 50:  C0 = 32'sd1892; 51:  C0 = -32'sd783; 52:  C0 = -32'sd783; 53:  C0 = 32'sd1892; 54:  C0 = -32'sd1892; 55:  C0 = 32'sd783;   
		56:  C0 = 32'sd399; 57:  C0 = -32'sd1137; 58:  C0 = 32'sd1702; 59:  C0 = -32'sd2008; 60:  C0 = 32'sd2008; 61:  C0 = -32'sd1702; 62:  C0 = 32'sd1137; 63:  C0 = -32'sd399;   
	endcase
	case (coeff[2])
		0:C0=32'sd1448;	1:C0=32'sd1448;	2:C0=32'sd1448;	3:C0=32'sd1448;	4:C0=32'sd1448; 5:C0=32'sd1448; 6:C0=32'sd1448; 7:   C0=32'sd1448;   
		8:   C0=32'sd2008; 9:C0=32'sd1702; 10:C0=32'sd1137; 11: C0=32'sd399; 12: C0=-32'sd399; 13:  C0=-32'sd1137; 14:C0=-32'sd1702; 15:C0=-32'sd2008;
		16:  C0 = 32'sd1892; 17:  C0 = 32'sd783; 18:  C0 = -32'sd783; 19:  C0 = -32'sd1892; 20:  C0 = -32'sd1892; 21:  C0 = -32'sd783; 22:  C0 = 32'sd783; 23:  C0 = 32'sd1892;   
		24:  C0 = 32'sd1702; 25:  C0 = -32'sd399; 26:  C0 = -32'sd2008; 27:  C0 = -32'sd1137; 28:  C0 = 32'sd1137; 29:  C0 = 32'sd2008; 30:  C0 = 32'sd399; 31:  C0 = -32'sd1702; 
		32:  C0 = 32'sd1448; 33:  C0 = -32'sd1448; 34:  C0 = -32'sd1448; 35:  C0 = 32'sd1448;   36:  C0 = 32'sd1448; 37:  C0 = -32'sd1448; 38:  C0 = -32'sd1448; 39:  C0 = 32'sd1448; 
		40:  C0 = 32'sd1137; 41:  C0 = -32'sd2008; 42:  C0 = 32'sd399; 43:  C0 = 32'sd1702; 44:  C0 = -32'sd1702; 45:  C0 = -32'sd399; 46:  C0 = 32'sd2008; 47:  C0 = -32'sd1137;  
		48:  C0 = 32'sd783; 49:  C0 = -32'sd1892; 50:  C0 = 32'sd1892; 51:  C0 = -32'sd783; 52:  C0 = -32'sd783; 53:  C0 = 32'sd1892; 54:  C0 = -32'sd1892; 55:  C0 = 32'sd783;   
		56:  C0 = 32'sd399; 57:  C0 = -32'sd1137; 58:  C0 = 32'sd1702; 59:  C0 = -32'sd2008; 60:  C0 = 32'sd2008; 61:  C0 = -32'sd1702; 62:  C0 = 32'sd1137; 63:  C0 = -32'sd399;    
	endcase
	case (coeff[3])
		0:C0=32'sd1448;	1:C0=32'sd1448;	2:C0=32'sd1448;	3:C0=32'sd1448;	4:C0=32'sd1448; 5:C0=32'sd1448; 6:C0=32'sd1448; 7:   C0=32'sd1448;   
		8:   C0=32'sd2008; 9:C0=32'sd1702; 10:C0=32'sd1137; 11: C0=32'sd399; 12: C0=-32'sd399; 13:  C0=-32'sd1137; 14:C0=-32'sd1702; 15:C0=-32'sd2008;
		16:  C0 = 32'sd1892; 17:  C0 = 32'sd783; 18:  C0 = -32'sd783; 19:  C0 = -32'sd1892; 20:  C0 = -32'sd1892; 21:  C0 = -32'sd783; 22:  C0 = 32'sd783; 23:  C0 = 32'sd1892;   
		24:  C0 = 32'sd1702; 25:  C0 = -32'sd399; 26:  C0 = -32'sd2008; 27:  C0 = -32'sd1137; 28:  C0 = 32'sd1137; 29:  C0 = 32'sd2008; 30:  C0 = 32'sd399; 31:  C0 = -32'sd1702; 
		32:  C0 = 32'sd1448; 33:  C0 = -32'sd1448; 34:  C0 = -32'sd1448; 35:  C0 = 32'sd1448;   36:  C0 = 32'sd1448; 37:  C0 = -32'sd1448; 38:  C0 = -32'sd1448; 39:  C0 = 32'sd1448; 
		40:  C0 = 32'sd1137; 41:  C0 = -32'sd2008; 42:  C0 = 32'sd399; 43:  C0 = 32'sd1702; 44:  C0 = -32'sd1702; 45:  C0 = -32'sd399; 46:  C0 = 32'sd2008; 47:  C0 = -32'sd1137;  
		48:  C0 = 32'sd783; 49:  C0 = -32'sd1892; 50:  C0 = 32'sd1892; 51:  C0 = -32'sd783; 52:  C0 = -32'sd783; 53:  C0 = 32'sd1892; 54:  C0 = -32'sd1892; 55:  C0 = 32'sd783;   
		56:  C0 = 32'sd399; 57:  C0 = -32'sd1137; 58:  C0 = 32'sd1702; 59:  C0 = -32'sd2008; 60:  C0 = 32'sd2008; 61:  C0 = -32'sd1702; 62:  C0 = 32'sd1137; 63:  C0 = -32'sd399;   
	endcase


	case(YUV_counter_read)// 0=Y, 1=U, 2=V
			2'd0: begin
				start_offset <= S_Y_START_ADDRESS; 
			end
			2'd1: begin
				start_offset <= S_U_START_ADDRESS; 
			end
			2'd2: begin
				start_offset <= S_V_START_ADDRESS; 
			end
	endcase

	case(YUV_counter_read2)// 0=Y, 1=U, 2=V
			2'd0: begin
				start_offset2 <= S_Y_START_ADDRESS; 
			end
			2'd1: begin
				start_offset2 <= S_U_START_ADDRESS; 
			end
			2'd2: begin
				start_offset2 <= S_V_START_ADDRESS; 
			end
	endcase
	
end



inv_cos_states M2State;
always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
		//insert everything with a register here and set to 0
		
		SRAM_address <= 18'd0;
		SRAM_write_data <= 16'd0;
		SRAM_we_n <= 1'b1;
		M2_Stop <= 1'b0;
		
		address_1 <= 7'b0;
		address_2 <= 7'b0;
		address_3 <= 7'b0;
		address_4 <= 7'b0;
		address_5 <= 7'b0;
		address_6 <= 7'b0;
		
		col_counter <= 3'd0;
		row_counter <= 3'd0;
		YUV_counter_read <= 2'd0;
		start_offset <= 18'd0;
		
		S_prime_counter[0] <= 6'd0;
		S_prime_counter[1] <= 6'd0;
		S_prime_counter[2] <= 6'd0;
		S_prime_counter[3] <= 6'd0;
		
		
		T_accumulator <= 32'd0;

		coeff[0] <= 8'd0;
		coeff[1] <= 8'd0;
		coeff[2] <= 8'd0;
		coeff[3] <= 8'd0;
		T_col_counter <= 5'd0;
		T_row_counter <= 5'd0;


		S_counter <= 6'd0; // to read the same 4 T slots for calc S
		S_accumulator[0] <= 32'd0;
		S_accumulator[1] <= 32'd0;
		S_col_counter <= 5'd0;
		S_four_counter <= 4'b0;

		S_S_counter[0] <= 6'd0;
		S_S_counter[1] <= 6'd0;
		S_S_counter[2] <= 6'd0;
		S_S_counter[3] <= 6'd0;
		S_S_counter[4] <= 6'd0;
		S_S_counter[5] <= 6'd0;
		S_S_counter[6] <= 6'd0;
		S_S_counter[7] <= 6'd0;
		
		S_T_counter[0] <= 6'd0;
		S_T_counter[1] <= 6'd0;
		S_T_counter[2] <= 6'd0;
		S_T_counter[3] <= 6'd0;
		S_T_counter[4] <= 6'd0;
		S_T_counter[5] <= 6'd0;
		S_T_counter[6] <= 6'd0;
		S_T_counter[7] <= 6'd0;



		
		
		M2State <= S_M2_IDLE;
	
	
	end else begin
		
		case (M2State)
		S_M2_IDLE: begin
			if(M2_Enable == 1'b1) begin
				

				//need to make if statements that set each
				address_1 <= 7'b0;
				address_2 <= 7'b0;
				address_3 <= 7'b0;
				address_4 <= 7'b0;
				address_5 <= 7'b0;
				address_6 <= 7'b0;
				
				S_prime_counter[0] <= 6'd0;
				S_prime_counter[1] <= 6'd1;
				S_prime_counter[2] <= 6'd2;
				S_prime_counter[3] <= 6'd3;
				
				row_counter <= 3'd0;
				read_data_counter <= 3'd0;
				YUV_counter_read <= 2'd0; // 0 = Y, 1 = U, 2 = V
				//when do we do the intial stuff for SRAM/DRAM
				// SRAM_we_n <= 1'b1;	
				

				S_counter <= 6'd0; 
				S_accumulator <= 32'd0;
				S_col_counter <= 5'd1;
				S_four_counter <= 4'b1;
				
				S_S_counter[0] <= 6'd0;
				S_S_counter[1] <= 6'd2;
				S_S_counter[2] <= 6'd4;
				S_S_counter[3] <= 6'd6;
				S_S_counter[4] <= 6'd8;
				S_S_counter[5] <= 6'd10;
				S_S_counter[6] <= 6'd12;
				S_S_counter[7] <= 6'd14;
				
				S_T_counter[0] <= 6'd0;
				S_T_counter[1] <= 6'd8;
				S_T_counter[2] <= 6'd16;
				S_T_counter[3] <= 6'd24;
				S_T_counter[4] <= 6'd32;
				S_T_counter[5] <= 6'd40;
				S_T_counter[6] <= 6'd48;
				S_T_counter[7] <= 6'd56;

				write_data_b[0] => 32'b0;
				write_data_b[1] => 32'b0;
				write_data_b[2] => 32'b0;
				write_data_a[0] <= 32'b0;
				write_data_a[1] <= 32'b0;
				write_data_a[2] <= 32'b0;

				write_enable_b[0] <= 1'b0;
				write_enable_b[1] <= 1'b0;
				write_enable_b[2] <= 1'b0;
				write_enable_a[0] <= 1'b0;
				write_enable_a[1] <= 1'b0;
				write_enable_a[2] <= 1'b0;
				
				read_data_a[0] <= 32'b0;
				read_data_a[1] <= 32'b0;
				read_data_a[2] <= 32'b0;
				read_data_b[0] <= 32'b0;
				read_data_b[1] <= 32'b0;
				read_data_b[2] <= 32'b0;
				
				

				
				M2State <= S_Read_LeadIn1;
			end
		end
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		//MEGASTATE 1: READING S' **************************************************************
		
		
		S_Read_LeadIn1: begin
			
			write_data_b[0]
			
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 1'b1;
			
			M2State <= S_Read_LeadIn2;
		end
		
		S_Read_LeadIn2: begin
			
			
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 1'b1;
			
			M2State <= S_Read_LeadIn3;
		end
		
		S_Read_LeadIn3: begin
			
			
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 1'b1;
			
			M2State <= S_Read_CommonCase1;
			
			//setting up d-ram (s') to write y0,y1
			address_1 <= 7'd0;
		end
		
		//Y0 comes in
		S_Read_CommonCase1: begin
			
			//setting buffer to Y0
			S_prime_buffer <= SRAM_read_data;
			
			
			
			//setting up for read Y3
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 1'b1;
			
			
			
					
			M2State <= S_Read_CommonCase2;
		end
		
		//Y1
		S_Read_CommonCase2: begin
			
			//setting up for read Y4
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 1'b1;
			
			//writing Y0,Y1 to d-ram
			write_enable_a[0] = 1'b1;
			write_data_a[0] <= {S_prime_buffer, SRAM_read_data};
			address_1 <= address_1 + 1'b1;
			
			M2State <= S_Read_CommonCase3;
		end
		
		//Y2
		S_Read_CommonCase3: begin
			
			//setting buffer to Y2
			S_prime_buffer <= SRAM_read_data;
			
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 1'b1;
			
			M2State <= S_Read_CommonCase4;
		end
		
		//Y3
		S_Read_CommonCase4: begin
			
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 1'b1;
			
			//writing Y2,Y3 to d-ram
			write_enable_a[0] = 1'b1;
			write_data_a[0] <= {S_prime_buffer, SRAM_read_data};
			address_1 <= address_1 + 1'b1;
			
			
			M2State <= S_Read_CommonCase5;
		end
		
		//Y4
		S_Read_CommonCase5: begin
			
			//setting buffer to Y4
			S_prime_buffer <= SRAM_read_data;
			
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 17'd313; //to start @ 320, 640,.....
			//starting the next row in the block of Y values in next state
			
			
			M2State <= S_Read_CommonCase6;
		end
		
		//start reading next row of values (y320, y640, y960, ....)
		//Y5
		S_Read_CommonCase6: begin
			
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 1'b1;
			
			//writing Y4,Y5 to d-ram
			write_enable_a[0] = 1'b1;
			write_data_a[0] <= {S_prime_buffer, SRAM_read_data};
			address_1 <= address_1 + 1'b1;
			
			
			M2State <= S_Read_CommonCase7;
		end
		
		//Y6
		S_Read_CommonCase7: begin
			
			//setting buffer to Y6
			S_prime_buffer <= SRAM_read_data;
			
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 1'b1;
			
			M2State <= S_Read_CommonCase8;
		end
		
		//Y7
		S_Read_CommonCase8: begin
			
			SRAM_we_n <= 1'b1;
			SRAM_address <= start_offset + read_data_counter;
			read_data_counter <= read_data_counter + 1'b1;
			row_counter <= row_counter + 1'b1;
			
			//writing Y6,Y7 to d-ram
			//will show up in cc1
			write_enable_a[0] = 1'b1;
			write_data_a[0] <= {S_prime_buffer, SRAM_read_data};
			address_1 <= address_1 + 1'b1;
			
			if(row_counter == 3'd7) begin //reached the last row
				
				row_counter <= 3'd0;
				
				//SETTING UP FOR CALC T
				
				M2State <= S_Read_Lead_Out1;
				
			end
			
			M2State <= S_Read_CommonCase1;
		end
		
		S_Read_Lead_Out1: begin
			//DELAY STATE TO MAKE SURE THAT LAST S' VALUE IS WRITEN TO DRAM AND SETUP FOR CALC T MEGASTATE
			
			//CALL FOR (Y0,Y1) (Y2,Y3)
			write_enable_a[0] = 1'b0; // WE ARE READING FROM S' DRAM 
			write_enable_a[1] = 1'b1;	// WE ARE WRITING TO T DRAM
			address_1 <= S_prime_counter[0]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[1];
			
			YUV_counter_read <= 2'd2 ? 2'd0 : (YUV_counter_read + 2'd1); //sets the start address for the next read of s'
			
			///column counter turns to 2 next cc
			col_counter <= 4'd1; // 
			row_counter <= 4'd0;// 
			
			M2State <= T_Calc_CommonCase1;
		end
		
	
	
		
	










	
		
		
		
		//MEGASTATE 2: CALCULATING S'C (T) **************************************************************	
		
		
		T_Calc_CommonCase1: begin
				
			//CALL FOR (Y4,Y5) (Y6,Y7)
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[2]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[3];
			
			
			
			//dont write on first period of common case
			if (row_counter > 5'd0) begin
				//WRITE T7
				write_enable_a[1] = 1'b1;
				write_data_a[1] <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
				address_3 <= address_3 + 1'b1;
			end
			



			M2State <= T_Calc_CommonCase2;
		end
		
		//calculating T0
		//RECEIVE (Y0,Y1) (Y2,Y3)
		T_Calc_CommonCase2: begin
			//CALL FOR (Y0,Y1) (Y2,Y3)
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[0]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[1];
			
			
			
			coeff[0] <= 8'd0; //1448
			coeff[1] <= 8'd8; //2008
			coeff[2] <= 8'd16; //1892
			coeff[3] <= 8'd24; //1702
			Mult1_op_2 <= read_data_a[0][15:0]; //Y0
			Mult2_op_2 <= read_data_a[0][16:31]; //Y1
			Mult3_op_2 <= read_data_b[0][15:0]; //Y2
			Mult4_op_2 <= read_data_b[0][16:31]; //Y3
			

			
			
			
			M2State <= T_Calc_CommonCase3;
		end
		
		//calculating T0
		//RECEIVE (Y4,Y5) (Y6,Y7)
		//RECIEVE T0 1/2
		T_Calc_CommonCase3: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[2]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[3];
			
			//T0 1/2
			T_accumulator <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			
			coeff[0] <= 8'd32; //1448
			coeff[1] <= 8'd40; //1137
			coeff[2] <= 8'd48; //783
			coeff[3] <= 8'd56; //399
			Mult1_op_2 <= read_data_a[0][15:0]; //Y4
			Mult2_op_2 <= read_data_a[0][16:31]; //Y5
			Mult3_op_2 <= read_data_b[0][15:0]; //Y6
			Mult4_op_2 <= read_data_b[0][16:31]; //Y6
			

			//column counter turns to 2 next cc
			T_col_counter <= T_col_counter + 5'd1;
			
			
			M2State <= T_Calc_CommonCase4;
		end
		
		//RECIEVE T0 
		T_Calc_CommonCase4: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[0]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[1];
			
			
			//WRITE T0
			write_enable_a[1] = 1'b1;
			write_data_a[1] <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;;
			address_3 <= address_3 + 1'b1;
			
			
			
			coeff[0] <= 8'd1; //etc
			coeff[1] <= 8'd9; 
			coeff[2] <= 8'd17; 
			coeff[3] <= 8'd25; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			
			
			M2State <= T_Calc_CommonCase5;
		end
		
		//RECIEVE T0 1/2
		T_Calc_CommonCase5: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[2]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[3];
			
			
			T_accumulator <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd33; 
			coeff[1] <= 8'd41; 
			coeff[2] <= 8'd49; 
			coeff[3] <= 8'd57; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			//column counter turns to 3 next cc
			T_col_counter <= T_col_counter + 5'd1;
			
			M2State <= T_Calc_CommonCase6;
		end
		
		T_Calc_CommonCase6: begin
			
			
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[0]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[1];
			
			//WRITE T1
			write_enable_a[1] = 1'b1;
			write_data_a[1] <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			address_3 <= address_3 + 1'b1;


			// T_accumulator <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd2; //etc
			coeff[1] <= 8'd10; 
			coeff[2] <= 8'd18; 
			coeff[3] <= 8'd26; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			
			M2State <= T_Calc_CommonCase7;
		end
		
		T_Calc_CommonCase7: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[2]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[3];
			
			T_accumulator <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd34; 
			coeff[1] <= 8'd42; 
			coeff[2] <= 8'd50; 
			coeff[3] <= 8'd58; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			

			//column counter turns to 4 next cc
			T_col_counter <= T_col_counter + 5'd1;
			
			M2State <= T_Calc_CommonCase8;
		end
		
		T_Calc_CommonCase8: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[0]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[1];
			
			//WRITE T2
			write_enable_a[1] = 1'b1;
			write_data_a[1] <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			address_3 <= address_3 + 1'b1;
			
			// T_accumulator <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd3; //etc
			coeff[1] <= 8'd11; 
			coeff[2] <= 8'd19; 
			coeff[3] <= 8'd27; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			M2State <= T_Calc_CommonCase9;
		end
		
		T_Calc_CommonCase9: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[2]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[3];
			
			T_accumulator <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd35; 
			coeff[1] <= 8'd43; 
			coeff[2] <= 8'd51; 
			coeff[3] <= 8'd59; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			//column counter turns to 5 next cc
			T_col_counter <= T_col_counter + 5'd1;
			
			M2State <= T_Calc_CommonCase10;
		end
		
		T_Calc_CommonCase10: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[0]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[1];
			
			//WRITE T3
			write_enable_a[1] = 1'b1;
			write_data_a[1] <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			address_3 <= address_3 + 1'b1;


			// T_accumulator <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd4; //etc
			coeff[1] <= 8'd12; 
			coeff[2] <= 8'd20; 
			coeff[3] <= 8'd28; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			M2State <= T_Calc_CommonCase11;
		end
		
		T_Calc_CommonCase11: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[2]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[3];
			
			T_accumulator <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd36; 
			coeff[1] <= 8'd44; 
			coeff[2] <= 8'd52; 
			coeff[3] <= 8'd60; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			//column counter turns to 6 next cc
			T_col_counter <= T_col_counter + 5'd1;
			
			M2State <= T_Calc_CommonCase12;
		end
		
		T_Calc_CommonCase12: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[0]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[1];
			
			//WRITE T4
			write_enable_a[1] = 1'b1;
			write_data_a[1] <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			address_3 <= address_3 + 1'b1;

			// T_accumulator <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd5; //etc
			coeff[1] <= 8'd13; 
			coeff[2] <= 8'd21; 
			coeff[3] <= 8'd29; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			M2State <= T_Calc_CommonCase13;
		end
		
		T_Calc_CommonCase13: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[2]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[3];
			
			T_accumulator <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd37; 
			coeff[1] <= 8'd45; 
			coeff[2] <= 8'd53; 
			coeff[3] <= 8'd61; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			//column counter turns to 7 next cc
			T_col_counter <= T_col_counter + 5'd1;
			
			M2State <= T_Calc_CommonCase14;
		end
		
		T_Calc_CommonCase14: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[0]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[1];
			
			//WRITE T5
			write_enable_a[1] = 1'b1;
			write_data_a[1] <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			address_3 <= address_3 + 1'b1;

			// T_accumulator <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd6; //etc
			coeff[1] <= 8'd14; 
			coeff[2] <= 8'd22; 
			coeff[3] <= 8'd30; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31];
			
			M2State <= T_Calc_CommonCase15;
		end
		
		T_Calc_CommonCase15: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[2]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[3];
			
			T_accumulator <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd38; 
			coeff[1] <= 8'd46; 
			coeff[2] <= 8'd54; 
			coeff[3] <= 8'd62; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			//column counter turns to 8 next cc
			T_col_counter <= T_col_counter + 5'd1;
			
			M2State <= T_Calc_CommonCase16;
		end
		
		T_Calc_CommonCase16: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[0]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[1];
			
			//WRITE T6
			write_enable_a[1] = 1'b1;
			write_data_a[1] <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			address_3 <= address_3 + 1'b1;

			// T_accumulator <= T_accumulator + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd7; //etc
			coeff[1] <= 8'd15; 
			coeff[2] <= 8'd23; 
			coeff[3] <= 8'd31; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31];
			
			M2State <= T_Calc_CommonCase17;
		end
		
		T_Calc_CommonCase17: begin
			
			write_enable_a[0] = 1'b0;
			address_1 <= S_prime_counter[2]; //READ FROM THE START OF ALL THE S' VALUES WE WROTE
			address_2 <= S_prime_counter[3];
			
			T_accumulator <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			
			coeff[0] <= 8'd39; 
			coeff[1] <= 8'd47; 
			coeff[2] <= 8'd55; 
			coeff[3] <= 8'd63; 
			Mult1_op_2 <= read_data_a[0][15:0]; 
			Mult2_op_2 <= read_data_a[0][16:31]; 
			Mult3_op_2 <= read_data_b[0][15:0]; 
			Mult4_op_2 <= read_data_b[0][16:31]; 
			
			//column counter turns to 1 next cc
			T_col_counter <= 5'd1;
			
			
			T_row_counter <= T_row_counter + 5'd1;

			if (T_row_counter == 5'd7) begin 
				M2State <= S_M2_IDLE;
				//add reset stuff idk
			end
			
			S_prime_counter[0] <= S_prime_counter[0] + 16'd1;
			S_prime_counter[1] <= S_prime_counter[1] + 16'd1;
			S_prime_counter[2] <= S_prime_counter[2] + 16'd1;
			S_prime_counter[3] <= S_prime_counter[3] + 16'd1;

			
			
			
			M2State <= T_Calc_CommonCase1;
		end
		
		




		







		//MEGASTATE 3: CALC S **************************************************************

		S_Calc_Lead_In1: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[0]; //READ T0
			address_4 <= S_T_counter[1]; //READ T8
			
			M2State <= S_Calc_Lead_In2;
		end

		S_Calc_Lead_In2: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[2]; //READ T16
			address_4 <= S_T_counter[3]; //READ T24

			///column counter turns to 2 next cc
			col_counter <= 4'd1;
			row_counter <= 4'd1;
			
			M2State <= S_Calc_CommonCase1;
		end

		//calculating T0
		//RECEIVE (T0,T8) 
		S_Calc_CommonCase1: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[4]; //READ T32
			address_4 <= S_T_counter[5]; //READ T40
			
			
			//S0 1/4      S8 1/4
			coeff[0] <= 8'd0; //1448
			coeff[1] <= 8'd1; //1448
			coeff[2] <= 8'd2; //2008
			coeff[3] <= 8'd3; //1702
			Mult1_op_2 <= read_data_a[1]; //T0
			Mult2_op_2 <= read_data_b[1]; //T8
			Mult3_op_2 <= read_data_a[1]; //T0
			Mult4_op_2 <= read_data_b[1]; //T8
			
			// S_accumulator[0] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			// S_accumulator[1] <= S_accumulator[1] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;

			//WRITE S48,S56
			if (S_row_counter > 5'd0) begin
				//write s48, s56 to address 0,2
				write_enable_a[1] = 1'b1;
				//concat of S_accumulators
				// ! ADD IMPLEMENTATION THAT WRITES TO CORRECT PART OF DRAM ADDRESS [0:15] [16:31]
				write_data_a[1] <= { (S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4) , (S_accumulator[1] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4)};
				
				
			end
			
			
			M2State <= S_Calc_CommonCase2;
		end


		//calculating T0
		//RECEIVE (T16,T24) 
		S_Calc_CommonCase2: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[6]; //READ T48
			address_4 <= S_T_counter[7]; //READ T56
			
			
			//S0 2/4      S8 2/4
			coeff[0] <= 8'd4; //1448
			coeff[1] <= 8'd5; //1448
			coeff[2] <= 8'd6; //1137
			coeff[3] <= 8'd7; //399
			Mult1_op_2 <= read_data_a[1]; //T16
			Mult2_op_2 <= read_data_b[1]; //T24
			Mult3_op_2 <= read_data_a[1]; //T16
			Mult4_op_2 <= read_data_b[1]; //T24
			
			//WRITE S48,S56
			if (S_row_counter > 5'd0) begin
				//write s48, s56 to address 0,2
				write_enable_a[1] = 1'b1;
				//
				S_four_counter <= S_four_counter + 5'd1;
				//concat of S_accumulators
				// ! ADD IMPLEMENTATION THAT WRITES TO CORRECT PART OF DRAM ADDRESS [0:15] [16:31]
				write_data_a[1] <= { (S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4) , (S_accumulator[1] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4)};
					if (S_four_counter == 5'd4) begin
						S_S_counter[7] <= S_S_counter[7] + 16'd1; 
						S_S_counter[6] <= S_S_counter[6] + 16'd1; 
						S_S_counter[5] <= S_S_counter[5] + 16'd1; 
						S_S_counter[4] <= S_S_counter[4] + 16'd1; 
						S_S_counter[3] <= S_S_counter[3] + 16'd1; 
						S_S_counter[2] <= S_S_counter[2] + 16'd1; 
						S_S_counter[1] <= S_S_counter[1] + 16'd1; 
						S_S_counter[0] <= S_S_counter[0] + 16'd1; 
					end

				
			end
			//S0 1/4      S8 1/4
			S_accumulator[0] <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;


			
			
			
			M2State <= S_Calc_CommonCase3;
		end

		//calculating T0
		//RECEIVE (T32,T40) 
		S_Calc_CommonCase3: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[0]; //READ T0
			address_4 <= S_T_counter[1]; //READ T8
			
			
			//S0  3/4     S8     3/4
			coeff[0] <= 8'd8; //1448
			coeff[1] <= 8'd9; //1448
			coeff[2] <= 8'd10; //-399
			coeff[3] <= 8'd11; //1137
			Mult1_op_2 <= read_data_a[1]; //T32
			Mult2_op_2 <= read_data_b[1]; //T40
			Mult3_op_2 <= read_data_a[1]; //T32
			Mult4_op_2 <= read_data_b[1]; //T40
			

			//S0 2/4      S8 2/4 
			S_accumulator[0] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;



			M2State <= S_Calc_CommonCase4;
		end
		
		S_Calc_CommonCase4: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[2]; //READ T16
			address_4 <= S_T_counter[3]; //READ T24
			
			
			//S0       S8 
			coeff[0] <= 8'd12; 
			coeff[1] <= 8'd13;
			coeff[2] <= 8'd14; 
			coeff[3] <= 8'd15; 
			Mult1_op_2 <= read_data_a[1]; //T48
			Mult2_op_2 <= read_data_b[1]; //T56
			Mult3_op_2 <= read_data_a[1]; //T48
			Mult4_op_2 <= read_data_b[1]; //T56
			
			//getting write ready for next state
			write_enable_a[2] = 1'b1;
			address_5 <= S_S_counter[0];
			address_6 <= S_S_counter[1];

			//S0 3/4      S8 3/4
			S_accumulator[0] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;

	
			M2State <= S_Calc_CommonCase5;
		end	
		S_Calc_CommonCase5: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[4]; //READ T32
			address_4 <= S_T_counter[5]; //READ T40
			
			
			//S0 1/4     S8 1/4
			coeff[0] <= 8'd16; 
			coeff[1] <= 8'd17; 
			coeff[2] <= 8'd18;
			coeff[3] <= 8'd19; 
			Mult1_op_2 <= read_data_a[1]; //T48
			Mult2_op_2 <= read_data_b[1]; //T56
			Mult3_op_2 <= read_data_a[1]; //T48
			Mult4_op_2 <= read_data_b[1]; //T56
			
			//WRITE S0,S8
			// ! ADD IMPLEMENTATION THAT WRITES TO CORRECT PART OF DRAM ADDRESS [0:15] [16:31]
				write_data_a[2] <= { (S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4) , (S_accumulator[1] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4)};
	
			M2State <= S_Calc_CommonCase6;
		end	
		T_Calc_CommonCase6: begin
			
			//calculating T0
		//RECEIVE (T16,T24) 
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[6]; //READ T48
			address_4 <= S_T_counter[7]; //READ T56
			
			
			//S0 2/4      S8 2/4
			coeff[0] <= 8'd20; 
			coeff[1] <= 8'd21; 
			coeff[2] <= 8'd22; 
			coeff[3] <= 8'd23; 
			Mult1_op_2 <= read_data_a[1]; //T16
			Mult2_op_2 <= read_data_b[1]; //T24
			Mult3_op_2 <= read_data_a[1]; //T16
			Mult4_op_2 <= read_data_b[1]; //T24
			

			//S0 1/4      S8 1/4
			S_accumulator[0] <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;

	
			M2State <= S_Calc_CommonCase7;
		end	
		S_Calc_CommonCase7: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[0]; //READ T0
			address_4 <= S_T_counter[1]; //READ T8
			
			
			//S0  3/4     S8     3/4
			coeff[0] <= 8'd24;
			coeff[1] <= 8'd25; 
			coeff[2] <= 8'd26; 
			coeff[3] <= 8'd27; 
			Mult1_op_2 <= read_data_a[1]; //T32
			Mult2_op_2 <= read_data_b[1]; //T40
			Mult3_op_2 <= read_data_a[1]; //T32
			Mult4_op_2 <= read_data_b[1]; //T40
			

			//S0 2/4      S8 2/4 
			S_accumulator[0] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;

	
			M2State <= S_Calc_CommonCase8;
		end	
		S_Calc_CommonCase8: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[2]; //READ T16
			address_4 <= S_T_counter[3]; //READ T24
			
			
			//S0       S8 
			coeff[0] <= 8'd28; 
			coeff[1] <= 8'd29;
			coeff[2] <= 8'd30; 
			coeff[3] <= 8'd31; 
			Mult1_op_2 <= read_data_a[1]; //T48
			Mult2_op_2 <= read_data_b[1]; //T56
			Mult3_op_2 <= read_data_a[1]; //T48
			Mult4_op_2 <= read_data_b[1]; //T56
			
			//getting write ready for next state
			write_enable_a[2] = 1'b1;
			address_5 <= S_S_counter[2];
			address_6 <= S_S_counter[3];

			//S0 3/4      S8 3/4
			S_accumulator[0] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;

	
			M2State <= S_Calc_CommonCase9;
		end	
		S_Calc_CommonCase9: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[4]; //READ T32
			address_4 <= S_T_counter[5]; //READ T40
			
			
			//S0 1/4     S8 1/4
			coeff[0] <= 8'd32; 
			coeff[1] <= 8'd33; 
			coeff[2] <= 8'd34;
			coeff[3] <= 8'd35; 
			Mult1_op_2 <= read_data_a[1]; //T48 
			Mult2_op_2 <= read_data_b[1]; //T56 
			Mult3_op_2 <= read_data_a[1]; //T48 
			Mult4_op_2 <= read_data_b[1]; //T56 
			
			//WRITE S0,S8
			// ! ADD IMPLEMENTATION THAT WRITES TO CORRECT PART OF DRAM ADDRESS [0:15] [16:31]
				write_data_a[2] <= { (S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4) , (S_accumulator[1] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4)};
	
	
			M2State <= S_Calc_CommonCase10;
		end	
		S_Calc_CommonCase10: begin
			

			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[6]; //READ T48
			address_4 <= S_T_counter[7]; //READ T56
			
			
			//S0 2/4      S8 2/4
			coeff[0] <= 8'd36; 
			coeff[1] <= 8'd37; 
			coeff[2] <= 8'd38; 
			coeff[3] <= 8'd39; 
			Mult1_op_2 <= read_data_a[1]; //T16
			Mult2_op_2 <= read_data_b[1]; //T24
			Mult3_op_2 <= read_data_a[1]; //T16
			Mult4_op_2 <= read_data_b[1]; //T24
			

			//S0 1/4      S8 1/4
			S_accumulator[0] <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
	
			M2State <= S_Calc_CommonCase11;
		end	
		S_Calc_CommonCase11: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[0]; //READ T0
			address_4 <= S_T_counter[1]; //READ T8
			
			
			//S0  3/4     S8     3/4
			coeff[0] <= 8'd40;
			coeff[1] <= 8'd41; 
			coeff[2] <= 8'd42; 
			coeff[3] <= 8'd43; 
			Mult1_op_2 <= read_data_a[1]; //T32
			Mult2_op_2 <= read_data_b[1]; //T40
			Mult3_op_2 <= read_data_a[1]; //T32
			Mult4_op_2 <= read_data_b[1]; //T40
			

			//S0 2/4      S8 2/4 
			S_accumulator[0] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
	
			M2State <= S_Calc_CommonCase12;
		end	
		S_Calc_CommonCase12: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[2]; //READ T16
			address_4 <= S_T_counter[3]; //READ T24
			
			
			//S0       S8 
			coeff[0] <= 8'd44; 
			coeff[1] <= 8'd45;
			coeff[2] <= 8'd46; 
			coeff[3] <= 8'd47; 
			Mult1_op_2 <= read_data_a[1]; //T48
			Mult2_op_2 <= read_data_b[1]; //T56
			Mult3_op_2 <= read_data_a[1]; //T48
			Mult4_op_2 <= read_data_b[1]; //T56
			
			//getting write ready for next state
			write_enable_a[2] = 1'b1;
			address_5 <= S_S_counter[4];
			address_6 <= S_S_counter[5];


			//S0 3/4      S8 3/4
			S_accumulator[0] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
	
			M2State <= S_Calc_CommonCase13;
		end	
		S_Calc_CommonCase13: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[4]; //READ T32
			address_4 <= S_T_counter[5]; //READ T40
			
			
			//S0 1/4     S8 1/4
			coeff[0] <= 8'd48; 
			coeff[1] <= 8'd49; 
			coeff[2] <= 8'd50;
			coeff[3] <= 8'd51; 
			Mult1_op_2 <= read_data_a[1]; //T0 
			Mult2_op_2 <= read_data_b[1]; //T8 
			Mult3_op_2 <= read_data_a[1]; //T0 
			Mult4_op_2 <= read_data_b[1]; //T8 
			
			//WRITE S0,S8
			// ! ADD IMPLEMENTATION THAT WRITES TO CORRECT PART OF DRAM ADDRESS [0:15] [16:31]
				write_data_a[2] <= { (S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4) , (S_accumulator[1] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4)};
	
	
			M2State <= S_Calc_CommonCase14;
		end	
		S_Calc_CommonCase14: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[6]; //READ T48
			address_4 <= S_T_counter[7]; //READ T56
			
			
			//S0 2/4      S8 2/4
			coeff[0] <= 8'd52; 
			coeff[1] <= 8'd53; 
			coeff[2] <= 8'd54; 
			coeff[3] <= 8'd55; 
			Mult1_op_2 <= read_data_a[1]; //T16
			Mult2_op_2 <= read_data_b[1]; //T24
			Mult3_op_2 <= read_data_a[1]; //T16
			Mult4_op_2 <= read_data_b[1]; //T24
			

			//S0 1/4      S8 1/4
			S_accumulator[0] <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
	
			M2State <= S_Calc_CommonCase15;
		end	
		S_Calc_CommonCase15: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[0]; //READ T0
			address_4 <= S_T_counter[1]; //READ T8
			
			
			//S0  3/4     S8     3/4
			coeff[0] <= 8'd56;
			coeff[1] <= 8'd57; 
			coeff[2] <= 8'd58; 
			coeff[3] <= 8'd59; 
			Mult1_op_2 <= read_data_a[1]; //T32
			Mult2_op_2 <= read_data_b[1]; //T40
			Mult3_op_2 <= read_data_a[1]; //T32
			Mult4_op_2 <= read_data_b[1]; //T40
			

			//S0 2/4      S8 2/4 
			S_accumulator[0] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
	
			M2State <= S_Calc_CommonCase15;
		end	
		S_Calc_CommonCase16: begin
			
			write_enable_a[1] = 1'b0;
			address_3 <= S_T_counter[2]; //READ T16
			address_4 <= S_T_counter[3]; //READ T24
			
			
			//S0       S8 
			coeff[0] <= 8'd60; 
			coeff[1] <= 8'd61;
			coeff[2] <= 8'd62; 
			coeff[3] <= 8'd63; 
			Mult1_op_2 <= read_data_a[1]; //T48
			Mult2_op_2 <= read_data_b[1]; //T56
			Mult3_op_2 <= read_data_a[1]; //T48
			Mult4_op_2 <= read_data_b[1]; //T56
			
			//getting write ready for next state
			//setting for commmon case 1
			write_enable_a[2] = 1'b1;
			address_5 <= S_S_counter[4];
			address_6 <= S_S_counter[5];

			//increment for next column of S values
			S_T_counter[0] <= S_T_counter[0] + 6'd1;
			S_T_counter[1] <= S_T_counter[1] + 6'd1;
			S_T_counter[2] <= S_T_counter[2] + 6'd1;
			S_T_counter[3] <= S_T_counter[3] + 6'd1;
			S_T_counter[4] <= S_T_counter[4] + 6'd1;
			S_T_counter[5] <= S_T_counter[5] + 6'd1;
			S_T_counter[6] <= S_T_counter[6] + 6'd1;
			S_T_counter[7] <= S_T_counter[7] + 6'd1;


			//S0 3/4      S8 3/4
			S_accumulator[0] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;
			S_accumulator[1] <= S_accumulator[0] + Mult_result1 + Mult_result2 + Mult_result3 + Mult_result4;

			S_col_counter <= col_counter + 5'd1;
			


			M2State <= S_Calc_CommonCase1;
		end	
		

				



		













		
		
		
		
	//MEGASTATE 4: WRITE S **************************************************************


		S_Write_LeadIn1: begin

			address_5 <= 7'b0; //Make sure write enable is set for DRAM previously
			SRAM_we_n <= 1'b0;
			SW_data_counterY <= 16'b0;

			M2State <= S_Write_LeadIn2;

		end

		S_Write_LeadIn2: begin

			SRAM_address <= Y_START_ADDRESS;
			SW_data_counterY <= SW_data_counterY + 1'b1;
			hooplaYcount <= hooplaYcount + 1'b1;

			row_counter <= 16'b0;
			

			M2State <= S_Write_CommonCase1;

		end

		S_Write_CommonCase1: begin

			SRAM_write_data[15:8] <= read_data_a[2][7:0]; //s0
			SRAM_write_data[7:0] <= read_data_a[2][15:8]; //s1

			SRAM_address <= Y_START_ADDRESS + SW_data_counterY;
			SW_data_counterY <= SW_data_counterY + 1'b1;
			hooplaYcount <= hooplaYcount + 1'b1;

			address_5 <= address_5 + 1'b1; //DRAM data available 2cc from this

			M2State <= S_Write_CommonCase2;

		end

		S_Write_CommonCase2: begin

			SRAM_write_data[15:8] <= read_data_a[2][23:16]; //s2
			SRAM_write_data[7:0] <= read_data_a[2][31:24]; //s3

			SRAM_address <= Y_START_ADDRESS + SW_data_counterY;
			SW_data_counterY <= SW_data_counterY + 1'b1;
			hooplaYcount <= hooplaYcount + 1'b1;

			

			M2State <= S_Write_CommonCase3;

		end

		S_Write_CommonCase3: begin

			SRAM_write_data[15:8] <= read_data_a[2][7:0]; //s4
			SRAM_write_data[7:0] <= read_data_a[2][15:8]; //s5

			SRAM_address <= Y_START_ADDRESS + SW_data_counterY;
			SW_data_counterY <= SW_data_counterY + 1'b1;
			hooplaYcount <= hooplaYcount + 1'b1;

			address_5 <= address_5 + 1'b1; //DRAM data available 2cc from this

			M2State <= S_Write_CommonCase4;


		end

		S_Write_CommonCase4: begin

			SRAM_write_data[15:8] <= read_data_a[2][23:16]; //s6
			SRAM_write_data[7:0] <= read_data_a[2][31:24]; //s7

			SRAM_address <= Y_START_ADDRESS + SW_data_counterY;
			SW_data_counterY <= SW_data_counterY + 1'b1;
			hooplaYcount <= hooplaYcount + 1'b1;


			if (hooplaYcount == 7) begin

					row_counter <= row_counter + 1'b1;
					hooplaYcount <= 16'b0;

			end
			
			if (row_counter == 7 && hooplaYcount == 7) begin 
				M2State <= S_Write_LeadOut1;
			end else begin
				M2State <= S_Write_CommonCase1;
			end

		end

		S_Write_LeadOut1: begin

			M2State <= S_Write_LeadOut2;

		end

		S_Write_LeadOut2: begin

			M2State <= S_Write_LeadOut3;

		end

		S_Write_LeadOut3: begin

			M2_Stop <= 1'b1;
			M2State <= S_M2_IDLE;			

		end

		
		
		endcase
	end
end
endmodule

