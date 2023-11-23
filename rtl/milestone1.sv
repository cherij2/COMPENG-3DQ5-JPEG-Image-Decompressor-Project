
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

// This is the top module (same as experiment4 from lab 5 - just module renamed to "project")
// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA
module milestone1 (

	input logic Clock,
	input logic Resetn,
	
	input logic[15:0] SRAM_read_data,
	
	output logic[17:0] SRAM_address,
	output logic[15:0] SRAM_write_data,
	output logic SRAM_we_n,
	output logic M1_Stop,
	input logic M1_Enable
	
);


//REMEMBER TO CHANGE M1_STOP AT THE END

//COLOURSPACE CONVERSION AND INTERPOLATION
//logic [31:0] Y_Even;
//logic [31:0] UPrime_Even;
//logic [31:0] VPrime_Even;

//logic [31:0] Y_Odd;
logic [31:0] UPrime_Odd;
logic [31:0] VPrime_Odd;

logic [31:0] Final_UPrime_Odd;
logic [31:0] Final_VPrime_Odd;
logic [31:0] Final_UPrime_Even;
logic [31:0] Final_VPrime_Even;


logic [7:0] Shift_Count_U [5:0];
logic [7:0] Shift_Count_V [5:0];


//logic [31:0] UOdd_Op [5:0];
//logic [31:0] VOdd_Op [5:0];

logic [17:0] data_counterU;
logic [17:0] data_counterV;
logic [17:0] data_counterY;
logic [17:0] data_counterRGB;
logic even_odd_counter;
logic [7:0] row_counter; //needs to go up to 240
logic [8:0] col_counter; //needs to go up to 320

logic [17:0] Y_guys;

logic [31:0] R_Even;
logic [31:0] G_Even;
logic [31:0] B_Even;

logic [31:0] R_Odd;
logic [31:0] G_Odd;
logic [31:0] B_Odd;

logic [31:0] R_Even_buf;
logic [31:0] G_Even_buf;
logic [31:0] B_Even_buf;

logic [31:0] R_Odd_buf;
logic [31:0] G_Odd_buf;
logic [31:0] B_Odd_buf;

logic [31:0] R_Even_buf2;
logic [31:0] G_Even_buf2;
logic [31:0] B_Even_buf2;

logic [31:0] R_Odd_buf2;
logic [31:0] G_Odd_buf2;
logic [31:0] B_Odd_buf2;



//logic [17:0] even_odd_count;


//Instantiate 4 Multipliers
logic [31:0] Mult1_op_1, Mult1_op_2, Mult2_op_1, Mult2_op_2, Mult3_op_1, Mult3_op_2, Mult4_op_1, Mult4_op_2;
logic [63:0] Mult_result_long1, Mult_result_long2, Mult_result_long3, Mult_result_long4;
logic [31:0] Mult_result1, Mult_result2, Mult_result3, Mult_result4;

always_comb begin

	Mult_result_long1 = Mult1_op_1 * Mult1_op_2;
	Mult_result_long2 = Mult2_op_1 * Mult2_op_2;
	Mult_result_long3 = Mult3_op_1 * Mult3_op_2;
	Mult_result_long4 = Mult4_op_1 * Mult4_op_2;

	Mult_result1 = Mult_result_long1[31:0];
	Mult_result2 = Mult_result_long2[31:0];
	Mult_result3 = Mult_result_long3[31:0];
	Mult_result4 = Mult_result_long4[31:0];
	
	R_Even = R_Even_buf2[31] ? 8'd0 : ( |R_Even_buf2[30:24] ? 8'd255 : R_Even_buf2[23:16] );
	R_Odd = R_Odd_buf2[31] ? 8'd0 : ( |R_Odd_buf2[30:24] ? 8'd255 : R_Odd_buf2[23:16] );

	B_Even = B_Even_buf2[31] ? 8'd0 : ( |B_Even_buf2[30:24] ? 8'd255 : B_Even_buf2[23:16] );
	B_Odd = B_Odd_buf2[31] ? 8'd0 : ( |B_Odd_buf2[30:24] ? 8'd255 : B_Odd_buf2[23:16] );

	G_Even = G_Even_buf2[31] ? 8'd0 : ( |G_Even_buf2[30:24] ? 8'd255 : G_Even_buf2[23:16] );
	G_Odd = G_Odd_buf2[31] ? 8'd0 : ( |G_Odd_buf2[30:24] ? 8'd255 : G_Odd_buf2[23:16] );
	
end

//Handle clipping and signed RGB stuff



interp_csc_states M1State;

always_ff @ (posedge Clock or negedge Resetn) begin

if (~Resetn) begin

		data_counterU <= 18'd0;
		data_counterV <= 18'd0;
		data_counterY <= 18'd0;
		data_counterRGB <= 18'd0;
		even_odd_counter <= 1'b0;
		row_counter <= 8'd0; //needs to go up to 240
		col_counter <= 9'd0; //needs to go up to 320
		
		SRAM_address <= 18'd0;
		SRAM_write_data <= 16'd0;
		SRAM_we_n <= 1'b1;
		
		M1_Stop <= 1'b0;
		
		
		//UPrime_Even <= 32'd0;
		//VPrime_Even <= 32'd0;

		UPrime_Odd <= 32'sd0;
		VPrime_Odd <= 32'sd0;

		Final_UPrime_Odd <= 32'sd0;
		Final_VPrime_Odd <= 32'sd0;
		Final_UPrime_Even <= 32'sd0;
		Final_VPrime_Even <= 32'sd0;
		//M1_Enable <= 1'b1;
		
		//R_Even <= 32'd0;
		//G_Even <= 32'd0;
		//B_Even <= 32'd0;

		//R_Odd <= 32'd0;
		//G_Odd <= 32'd0;
		//B_Odd <= 32'd0;

		R_Even_buf <= 32'sd0;
		G_Even_buf <= 32'sd0;
		B_Even_buf <= 32'sd0;

		R_Odd_buf <= 32'sd0;
		G_Odd_buf <= 32'sd0;
		B_Odd_buf <= 32'sd0;

		R_Even_buf2 <= 32'sd0;
		G_Even_buf2 <= 32'sd0;
		B_Even_buf2 <= 32'sd0;

		R_Odd_buf2 <= 32'sd0;
		G_Odd_buf2 <= 32'sd0;
		B_Odd_buf2 <= 32'sd0;
		
		Mult1_op_1 <= 32'sd0;
		Mult1_op_2 <= 32'sd0;
		Mult2_op_1 <= 32'sd0; 
		Mult2_op_2 <= 32'sd0; 
		Mult3_op_1 <= 32'sd0; 
		Mult3_op_2 <= 32'sd0; 
		Mult4_op_1 <= 32'sd0; 
		Mult4_op_2 <= 32'sd0;
	
		M1State <= S_M1_IDLE;

	
	end else begin

	case (M1State)

			S_M1_IDLE: begin
				if(M1_Enable == 1'b1) begin
					
					SRAM_we_n <= 1'b1;
					SRAM_address <= U_START_ADDRESS + data_counterU;
					
					R_Even_buf <= 32'sd0;
					G_Even_buf <= 32'sd0;
					B_Even_buf <= 32'sd0;

					R_Odd_buf <= 32'sd0;
					G_Odd_buf <= 32'sd0;
					B_Odd_buf <= 32'sd0;

					R_Even_buf2 <= 32'sd0;
					G_Even_buf2 <= 32'sd0;
					B_Even_buf2 <= 32'sd0;

					R_Odd_buf2 <= 32'sd0;
					G_Odd_buf2 <= 32'sd0;
					B_Odd_buf2 <= 32'sd0;
					
					UPrime_Odd <= 32'sd0;
					VPrime_Odd <= 32'sd0;

					Final_UPrime_Odd <= 32'sd0;
					Final_VPrime_Odd <= 32'sd0;
					Final_UPrime_Even <= 32'sd0;
					Final_VPrime_Even <= 32'sd0;
					
					Mult1_op_1 <= 32'sd0;
					Mult1_op_2 <= 32'sd0;
					Mult2_op_1 <= 32'sd0; 
					Mult2_op_2 <= 32'sd0; 
					Mult3_op_1 <= 32'sd0; 
					Mult3_op_2 <= 32'sd0; 
					Mult4_op_1 <= 32'sd0; 
					Mult4_op_2 <= 32'sd0;
					
					Shift_Count_U[0] <= 8'd0;	
					Shift_Count_U[1] <= 8'd0;
					Shift_Count_U[2] <= 8'd0;
					Shift_Count_U[3] <= 8'd0;
					Shift_Count_U[4] <= 8'd0;
					Shift_Count_U[5] <= 8'd0;
					
					Shift_Count_V[0] <= 8'd0;	
					Shift_Count_V[1] <= 8'd0;
					Shift_Count_V[2] <= 8'd0;
					Shift_Count_V[3] <= 8'd0;
					Shift_Count_V[4] <= 8'd0;
					Shift_Count_V[5] <= 8'd0;
											
					Y_guys <= 18'd0;
					
					M1State <= S_Lead_In1;
				end
			end
		
			S_Lead_In1: begin
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				data_counterU <= data_counterU + 1'b1;
				col_counter <= col_counter + 8'd1;
				
				M1State <= S_Lead_In2;
			
			end
			
			S_Lead_In2: begin
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
				data_counterV <= data_counterV + 1'b1;
				
				M1State <= S_Lead_In3;
			
			end
			
			S_Lead_In3: begin
				
				SRAM_we_n <= 1'b1;
				//check
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				//check later if 0 and 1 are in correct spots shift reg
				Shift_Count_U[1] <= SRAM_read_data[7:0]; //0
				Shift_Count_U[0] <= SRAM_read_data[15:8]; //1
				
				//(21*u0)
				Mult1_op_1 <= 32'sd21;
				Mult1_op_2 <= {24'd0 , SRAM_read_data[7:0]};
				
				
				//UOdd_Op[0] <= 32'd21 * SRAM_read_data[7:0];
				
				data_counterU <= data_counterU + 1'b1;
				col_counter <= col_counter + 8'd1;
				
				M1State <= S_Lead_In4;
			
			end
			
			S_Lead_In4: begin
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				
				
				
				Shift_Count_V[1] <= SRAM_read_data[7:0];
				Shift_Count_V[0] <= SRAM_read_data[15:8];		
				
				//(-52*U)
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= Shift_Count_U[1];
				
				//(21*U)
				Mult2_op_1 <= 32'sd21;
				Mult2_op_2 <= {24'd0 , SRAM_read_data[7:0]};
			
				//UOdd_Op[1] <= 32'd52 * Shift_Count_U[1];
				//VOdd_Op[0] <= 32'd21 * SRAM_read_data[7:0];
				
				data_counterV <= data_counterV + 1'b1;
			
				M1State <= S_Lead_In5;
			
			end
			
			S_Lead_In5: begin
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				//(159*U0)
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
				
				//(-52*V)
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};
				
				
				//UOdd_Op[2] <= 32'd159 * Shift_Count_U[1];
				//VOdd_Op[1] <= 32'd52 * Shift_Count_V[1];
			
				Shift_Count_U[2] <= Shift_Count_U[0];
				Shift_Count_U[3] <= Shift_Count_U[1];
				
				Shift_Count_U[1] <= SRAM_read_data[7:0];
				Shift_Count_U[0] <= SRAM_read_data[15:8];
				
				M1State <= S_Lead_In6;
				
			end
			
			S_Lead_In6: begin
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				//(159*U1)
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[2]};
				
				//(159*V)
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};
			
				//UOdd_Op[3] <= 32'd159 * Shift_Count_U[2];
				//VOdd_Op[2] <= 32'd159 * Shift_Count_V[1];
			
				Shift_Count_V[2] <= Shift_Count_V[0];
				Shift_Count_V[3] <= Shift_Count_V[1];
				
				Shift_Count_V[1] <= SRAM_read_data[7:0];
				Shift_Count_V[0] <= SRAM_read_data[15:8];
				
				M1State <= S_Lead_In7;
			
			end
			
			S_Lead_In7: begin
				
				
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				//(-52*U2)
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
				
				//(159*V1)
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
			
				//UOdd_Op[4] <= 32'd21 * Shift_Count_U[1];
				//VOdd_Op[3] <= 32'd159 * Shift_Count_V[2];
			
				M1State <= S_Lead_In8;
			
			end
			
			S_Lead_In8: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
				Y_guys <= Y_guys + 1'b1;

				
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				
				//(21*U3)
				Mult1_op_1 <= 32'sd21;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[0]};
				
				//(-52*V2)
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};
				
				//(21*V3)
				Mult3_op_1 <= 32'sd21;
				Mult3_op_2 <= {24'd0 , Shift_Count_V[0]};
			
				//UOdd_Op[5] <= 32'd52 * Shift_Count_U[0];
				//VOdd_Op[4] <= 32'd21 * Shift_Count_V[1]; 
				
				M1State <= S_Lead_In9;
			
			end
			
			S_Lead_In9: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
					
				
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2 + Mult_result3;
			
				
				
			
				//VOdd_Op[5] <= 32'd52 * Shift_Count_V[0]; DONE IN PREV STATE
				
				Shift_Count_U[4] <= Shift_Count_U[3];
				Shift_Count_U[5] <= Shift_Count_U[3];
				
				Shift_Count_V[4] <= Shift_Count_V[3];
				Shift_Count_V[5] <= Shift_Count_V[3];
				
				M1State <= S_Lead_In10;
			
			end
			
			S_Lead_In10: begin
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV; //received 2cc later
				
				
				//data_counterU <= data_counterU + 1'b1;
				// need to stay at U (4,5), to get 4, so dont run this commented code
				
				
				Final_UPrime_Even <= Shift_Count_U[3];
				Final_VPrime_Even <= Shift_Count_V[3];

				Final_UPrime_Odd <= (UPrime_Odd + 32'sd128) >>> 8;
				Final_VPrime_Odd <= (VPrime_Odd + 32'sd128) >>> 8;
				
				UPrime_Odd <= 32'd0;
				VPrime_Odd <= 32'd0;
				
				M1State <= S_Lead_In11;
			
			end

			S_Lead_In11: begin
			
				//data_counterV <= data_counterV + 1'b1;
				// need to stay at V (4,5) so dont run this commented code

				
				Mult1_op_1 <= 32'sd76284;
				Mult1_op_2 <= {24'd0 , SRAM_read_data[7:0]} - 32'sd16; //Y0
				
				Mult2_op_1 <= 32'sd76284;
				Mult2_op_2 <= {24'd0 , SRAM_read_data[15:8]} - 32'sd16; //Y1
				
				
				Mult3_op_1 <= 32'sd104595;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd104595;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				
				M1State <= S_Lead_In12;
				
			end
			
			S_Lead_In12: begin
				
				R_Odd_buf <= Mult_result2 + Mult_result4;
				G_Odd_buf <= Mult_result2;
				B_Odd_buf <= Mult_result2;
				
				R_Even_buf <= Mult_result1 + Mult_result3;
				G_Even_buf <= Mult_result1;
				B_Even_buf <= Mult_result1;
				
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[3]};
				
				
				Mult3_op_1 <= -32'sd25624;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd25624;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
				
				Shift_Count_U[1] <= Shift_Count_U[0];
				Shift_Count_U[2] <= Shift_Count_U[1];
				Shift_Count_U[3] <= Shift_Count_U[2];
				Shift_Count_U[4] <= Shift_Count_U[3];
				Shift_Count_U[5] <= Shift_Count_U[4];
				Shift_Count_U[0] <= SRAM_read_data[7:0];
				
				M1State <= S_Lead_In13;
			
			end
			
			S_Lead_In13: begin
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
			
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
			
				//UOdd_Op[2] <= 32'd159 * Shift_Count_U[3];
				//VOdd_Op[2] <= 32'd159 * Shift_Count_V[2];
				
				Mult3_op_1 <= -32'sd53281;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd53281;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				//G_Odd_buf <= G_Odd_buf - (32'd53281 * (VPrime_Odd - 32'd128));
				//G_Even_buf <= G_Even_buf - (32'd53281 * (VPrime_Even - 32'd128));
				
				Shift_Count_V[1] <= Shift_Count_V[0];
				Shift_Count_V[2] <= Shift_Count_V[1];
				Shift_Count_V[3] <= Shift_Count_V[2];
				Shift_Count_V[4] <= Shift_Count_V[3];
				Shift_Count_V[5] <= Shift_Count_V[4];
				Shift_Count_V[0] <= SRAM_read_data[7:0];

				
				
				M1State <= S_Lead_In14;
			
			end
			
			S_Lead_In14: begin
				
				
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[2]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
			
				//UOdd_Op[3] <= 32'd159 * Shift_Count_U[2];
				//VOdd_Op[3] <= 32'd159 * Shift_Count_V[2];
				
				Mult3_op_1 <= 32'sd132251;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd132251;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
				//B_Odd_buf <= B_Odd_buf + (32'd132251 * (UPrime_Odd - 32'd128));
				//B_Even_buf <= B_Even_buf + (32'd132251 * (UPrime_Even - 32'd128));
				
				//R_Even <= R_Even_buf >> 16;
				//G_Even <= G_Even_buf >> 16;
				
				M1State <= S_Lead_In15;
			
			end
			
			S_Lead_In15: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
				Y_guys <= Y_guys + 1'b1;

				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				B_Odd_buf <= B_Odd_buf + Mult_result4;
				B_Even_buf <= B_Even_buf + Mult_result3;
			
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};
				
			
				//UOdd_Op[4] <= 32'd52 * Shift_Count_U[1];
				//VOdd_Op[4] <= 32'd52 * Shift_Count_V[1];
				

				M1State <= S_Lead_In16;
				
			end
			
			S_Lead_In16: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
				
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				
				
				
				//Here we DONT increase data counter U because next time we need U(6,7)
				
			//	UOdd_Op[0] <= 32'd21 * Shift_Count_U[5];
			//	VOdd_Op[0] <= 32'd21 * Shift_Count_V[5];
				
			//	UOdd_Op[5] <= 32'd21 * Shift_Count_U[0];
			//	VOdd_Op[5] <= 32'd21 * Shift_Count_V[0];
				
				//delay in state table results in us having to do calc directly
				// in the uprime vprime odd calc
				
				//B_Even <= B_Even_buf >> 16;
				//R_Odd <= R_Odd_buf >> 16;
				
				Mult1_op_1 <= 32'sd21;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[0]};
				
				Mult2_op_1 <= 32'sd21;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[0]};
				
				Mult3_op_1 <= 32'sd21;
				Mult3_op_2 <= {24'd0 , Shift_Count_U[5]};
				
				Mult4_op_1 <= 32'sd21;
				Mult4_op_2 <= {24'd0 , Shift_Count_V[5]};
				
				//another buffer to hold the rgb values so our combinational logic
				//for clipping doesnt mess up our rgb values
				R_Even_buf2 <= R_Even_buf;
				R_Odd_buf2 <= R_Odd_buf;
				
				G_Even_buf2 <= G_Even_buf;
				G_Odd_buf2 <= G_Odd_buf;
				
				B_Even_buf2 <= B_Even_buf;
				B_Odd_buf2 <= B_Odd_buf;
				
				//UPrime_Odd <= (32'd21 * Shift_Count_U[5] - UOdd_Op[1] + UOdd_Op[2] + UOdd_Op[3] - UOdd_Op[4] + 32'd21 * Shift_Count_U[0] + 32'd128) >>> 8;
				//VPrime_Odd <= (32'd21 * Shift_Count_V[5] - VOdd_Op[1] + VOdd_Op[2] + VOdd_Op[3] - VOdd_Op[4] + 32'd21 * Shift_Count_V[0] + 32'd128) >>> 8;
			
	
				M1State <= S_Lead_In17;
				

			end
			
			S_Lead_In17: begin
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				
				
				
				//UPrime_Odd <= UPrime_Odd + Mult_result1 + Mult_result3;
				//VPrime_Odd <= UPrime_Odd + Mult_result2 + Mult_result4;
				
				
				// SINCE ODD IS 1 MORE THAN EVEN, WE CAN JUST TAKE (J-1)/2
				// AND CALL IT EVEN, SINCE EVEN IS J/2 AND ONE LESS THAN ODD 
				Final_UPrime_Even <= Shift_Count_U[3];
				Final_VPrime_Even <= Shift_Count_V[3];
				
				Final_UPrime_Odd <= (Mult_result1 + Mult_result3 + UPrime_Odd + 32'sd128) >>> 8;
				Final_VPrime_Odd <= (Mult_result2 + Mult_result4 + VPrime_Odd + 32'sd128) >>> 8;
				
				//G_Odd <= G_Odd_buf >> 16;
				//B_Odd <= B_Odd_buf >> 16;
				
				UPrime_Odd <= 32'd0;
				VPrime_Odd <= 32'd0;
				
				even_odd_counter <= 1'b0;
				
				

				M1State <= S_CommonCase1;
			
			end
			
			S_CommonCase1: begin
				
				//WHAT DO WE DO WITH SRAM READ DATA Y VALUES? 
				//NO REGISTER TO STORE THEM?
				//we read directly from the sram read data, we line it up so that the 
				//calculations requiring Y happen when SRAM read data has the Y values 
				//available
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				
				//from leadin case we go from U4 -> U5
				//counter goes from 0 -> 1
				even_odd_counter <= ~even_odd_counter; 
				//even odd counter goes to 1 so next 6 CC the UV address
				// will not update because we need to stay at UV(6,7) for
				// two reads
				
				//WRITE STATE
				SRAM_write_data[15:8] <= R_Even;
				SRAM_write_data[7:0] <= G_Even;
				
				Mult1_op_1 <= 32'sd76284;
				Mult1_op_2 <= {24'd0 , SRAM_read_data[15:8]} - 32'sd16; //Y0
				
				Mult2_op_1 <= 32'sd76284;
				Mult2_op_2 <= {24'd0 , SRAM_read_data[7:0]} - 32'sd16; //Y1
				
				Mult3_op_1 <= 32'sd104595;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd104595;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				
				
				
				M1State <= S_CommonCase2;
				
			end
			
			S_CommonCase2: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				R_Odd_buf <= Mult_result2 + Mult_result4;
				G_Odd_buf <= Mult_result2;
				B_Odd_buf <= Mult_result2;
				
				R_Even_buf <= Mult_result1 + Mult_result3;
				G_Even_buf <= Mult_result1;
				B_Even_buf <= Mult_result1;
				
				//WRITE STATE
				SRAM_write_data[15:8] <= B_Even;
				SRAM_write_data[7:0] <= R_Odd;
				
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[3]};
				
				Mult3_op_1 <= -32'sd25624;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd25624;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
				Shift_Count_U[1] <= Shift_Count_U[0];
				Shift_Count_U[2] <= Shift_Count_U[1];
				Shift_Count_U[3] <= Shift_Count_U[2];
				Shift_Count_U[4] <= Shift_Count_U[3];
				Shift_Count_U[5] <= Shift_Count_U[4];
				
				if (even_odd_counter == 0) begin
					
					Shift_Count_U[0] <= SRAM_read_data[15:8];
				
				end else begin
				
					Shift_Count_U[0] <= SRAM_read_data[7:0];
					
				end
				
				
				
				M1State <= S_CommonCase3;
				
			end
			
			S_CommonCase3: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				//WRITE STATE
				SRAM_write_data[15:8] <= G_Odd;
				SRAM_write_data[7:0] <= B_Odd;
				
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
				
				Mult3_op_1 <= -32'sd53281;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd53281;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				Shift_Count_V[1] <= Shift_Count_V[0];
				Shift_Count_V[2] <= Shift_Count_V[1];
				Shift_Count_V[3] <= Shift_Count_V[2];
				Shift_Count_V[4] <= Shift_Count_V[3];
				Shift_Count_V[5] <= Shift_Count_V[4];
				
				if (even_odd_counter == 0) begin
					
					Shift_Count_V[0] <= SRAM_read_data[15:8];
				
				end else begin
				
					Shift_Count_V[0] <= SRAM_read_data[7:0];	

				end
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value
				
				M1State <= S_CommonCase4;
				
			end
			
			S_CommonCase4: begin
				
				
				
				SRAM_we_n <= 1'b1;
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				
				
				//data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				
				
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[2]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
			
				Mult3_op_1 <= 32'sd132251;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd132251;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				

				M1State <= S_CommonCase5;
				
			end
			
			S_CommonCase5: begin
				
				//Back to read
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
				Y_guys <= Y_guys + 1'b1;

				if (even_odd_counter == 0) begin
					
					data_counterU <= data_counterU;
					col_counter <= col_counter;
					
				end else begin
					
					col_counter <= col_counter + 8'd1;
					data_counterU <= data_counterU + 1'b1;
					
					//even_odd_counter <= 1'b0;
									
				end
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				B_Odd_buf <= B_Odd_buf + Mult_result4;
				B_Even_buf <= B_Even_buf + Mult_result3;
				
				
			
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};
				
				
				M1State <= S_CommonCase6;
				
			end
			
			S_CommonCase6: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value
				
				if (even_odd_counter == 0) begin
					
					data_counterV <= data_counterV;
				
				end else begin
				
					data_counterV <= data_counterV + 1'b1;
									
				end
				
				
				Mult1_op_1 <= 32'sd21;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[0]};
				
				Mult2_op_1 <= 32'sd21;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[0]};
				
				Mult3_op_1 <= 32'sd21;
				Mult3_op_2 <= {24'd0 , Shift_Count_U[5]};
				
				Mult4_op_1 <= 32'sd21;
				Mult4_op_2 <= {24'd0 , Shift_Count_V[5]};
				
				R_Even_buf2 <= R_Even_buf;
				R_Odd_buf2 <= R_Odd_buf;
				
				G_Even_buf2 <= G_Even_buf;
				G_Odd_buf2 <= G_Odd_buf;
				
				B_Even_buf2 <= B_Even_buf;
				B_Odd_buf2 <= B_Odd_buf;
				
				M1State <= S_CommonCase7;
			
				
			end
			
			S_CommonCase7: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				
				
				//col_counter <= col_counter + 8'd1;
				
				//CHECKS IF WE NEED TO READ THE EVEN OR ODD VALUE IN THE PAIR
				//doesnt check the above even_odd_counter statement until 
				//next period
			
				//In this mux we're checking if we should add to the counter
				// the first time it should be updating for UV(6,7)
				// the next time it should stay at UV(6,7)
				
				
				//after lead-in case and first common case run, we need
				//to make sure we are still of U(4,5) i think we need to remove
				//this and go to the even odd conmparison thing to increment U
//				data_counterU <= data_counterU + 1'b1;
				
				// in the final case we are at oddevencoutner = 1, U157, col counter 78
				// oddevencounter = 0(updated in commoncase1), U158, col counter = 79
				
				
				Final_UPrime_Even <= Shift_Count_U[3];
				Final_VPrime_Even <= Shift_Count_V[3];
				
				Final_UPrime_Odd <= (Mult_result1 + Mult_result3 + UPrime_Odd + 32'sd128) >>> 8;
				Final_VPrime_Odd <= (Mult_result2 + Mult_result4 + VPrime_Odd + 32'sd128) >>> 8;
				
				UPrime_Odd <= 32'd0;
				VPrime_Odd <= 32'd0;
				
				if (col_counter == 8'd79) begin
					
					// oddevencounter = 1, U159, col counter = 79
					col_counter <= 8'd0;
					
					M1State <= S_Lead_Out1;
					//col counter = 0
				
				end
				
				else begin
					
					M1State <= S_CommonCase1;
				

					//we dont need to increment U,V anymore if we are in 158,
					//increment the oddevencounter by 1 so it stays at 159 instead of 158
					//we just need to keep reading 159
					
					
				end
				/*
				HAVE MUX TO EITHER CONTINUE TO CCASE 1
				OR TO LEAD OUT CASE. DEPENDENT ON DATA_COUNTER(?)
				*/ 
				
			
			end
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			//Start of Leadout, leadout has loop that repeats its self 3 times, this loop is 7cc
			//basically a copy paste of the common case but we dont read U,V anymore
			//new shift register values are just the last U value in the row repeated
			
			S_Lead_Out1: begin
				
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				
				//from leadin case we go from U4 -> U5
				//counter goes from 0 -> 1
//				even_odd_counter <= ~even_odd_counter; 
				//even odd counter goes to 1 so next 6 CC the UV address
				// will not update because we need to stay at UV(6,7) for
				// two reads
				
				//WRITE STATE
				SRAM_write_data[15:8] <= R_Even;
				SRAM_write_data[7:0] <= G_Even;
				
				Mult1_op_1 <= 32'sd76284;
				Mult1_op_2 <= {24'd0 , SRAM_read_data[15:8]} - 32'sd16; //Y0
				
				Mult2_op_1 <= 32'sd76284;
				Mult2_op_2 <= {24'd0 , SRAM_read_data[7:0]} - 32'sd16; //Y1
				
				Mult3_op_1 <= 32'sd104595;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd104595;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				M1State <= S_Lead_Out2;
			
			end
			
			S_Lead_Out2: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				R_Odd_buf <= Mult_result2 + Mult_result4;
				G_Odd_buf <= Mult_result2;
				B_Odd_buf <= Mult_result2;
				
				R_Even_buf <= Mult_result1 + Mult_result3;
				G_Even_buf <= Mult_result1;
				B_Even_buf <= Mult_result1;
				
				//WRITE STATE
				SRAM_write_data[15:8] <= B_Even;
				SRAM_write_data[7:0] <= R_Odd;
				
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[3]};
				
				Mult3_op_1 <= -32'sd25624;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd25624;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
				Shift_Count_U[0] <= SRAM_read_data[7:0];
				Shift_Count_U[1] <= Shift_Count_U[0];
				Shift_Count_U[2] <= Shift_Count_U[1];
				Shift_Count_U[3] <= Shift_Count_U[2];
				Shift_Count_U[4] <= Shift_Count_U[3];
				Shift_Count_U[5] <= Shift_Count_U[4];
				
				
				M1State <= S_Lead_Out3;
			
			end
			
			S_Lead_Out3: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				//WRITE STATE
				SRAM_write_data[15:8] <= G_Odd;
				SRAM_write_data[7:0] <= B_Odd;
				
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
				
				Mult3_op_1 <= -32'sd53281;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd53281;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				Shift_Count_V[0] <= SRAM_read_data[7:0];	
				Shift_Count_V[1] <= Shift_Count_V[0];
				Shift_Count_V[2] <= Shift_Count_V[1];
				Shift_Count_V[3] <= Shift_Count_V[2];
				Shift_Count_V[4] <= Shift_Count_V[3];
				Shift_Count_V[5] <= Shift_Count_V[4];
				


				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value
				
				M1State <= S_Lead_Out4;
			
			end
			S_Lead_Out4: begin
				
				
				SRAM_we_n <= 1'b1;
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				
				
				//data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				
				
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[2]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
			
				Mult3_op_1 <= 32'sd132251;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd132251;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				

				M1State <= S_Lead_Out5;
			
			end
			S_Lead_Out5: begin
				
				//Back to read
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
				Y_guys <= Y_guys + 1'b1;

				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				B_Odd_buf <= B_Odd_buf + Mult_result4;
				B_Even_buf <= B_Even_buf + Mult_result3;
				
				
			
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};
				
			
				M1State <= S_Lead_Out6;
			
			end
			S_Lead_Out6: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value

				
				Mult1_op_1 <= 32'sd21;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[0]};
				
				Mult2_op_1 <= 32'sd21;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[0]};
				
				Mult3_op_1 <= 32'sd21;
				Mult3_op_2 <= {24'd0 , Shift_Count_U[5]};
				
				Mult4_op_1 <= 32'sd21;
				Mult4_op_2 <= {24'd0 , Shift_Count_V[5]};
				
				R_Even_buf2 <= R_Even_buf;
				R_Odd_buf2 <= R_Odd_buf;
				
				G_Even_buf2 <= G_Even_buf;
				G_Odd_buf2 <= G_Odd_buf;
				
				B_Even_buf2 <= B_Even_buf;
				B_Odd_buf2 <= B_Odd_buf;
				
				M1State <= S_Lead_Out7;
			
			end
			S_Lead_Out7: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				
	
				
				//CHECKS IF WE NEED TO READ THE EVEN OR ODD VALUE IN THE PAIR
				//doesnt check the above even_odd_counter statement until 
				//next period
			
				//In this mux we're checking if we should add to the counter
				// the first time it should be updating for UV(6,7)
				// the next time it should stay at UV(6,7)
				
				
				//after lead-in case and first common case run, we need
				//to make sure we are still of U(4,5) i think we need to remove
				//this and go to the even odd conmparison thing to increment U
//				data_counterU <= data_counterU + 1'b1;
				
				// in the final case we are at oddevencoutner = 1, U157, col counter 78
				// oddevencounter = 0(updated in commoncase1), U158, col counter = 79
				
				
				Final_UPrime_Even <= Shift_Count_U[3];
				Final_VPrime_Even <= Shift_Count_V[3];
				
				Final_UPrime_Odd <= (Mult_result1 + Mult_result3 + UPrime_Odd + 32'sd128) >>> 8;
				Final_VPrime_Odd <= (Mult_result2 + Mult_result4 + VPrime_Odd + 32'sd128) >>> 8;
				
				UPrime_Odd <= 32'd0;
				VPrime_Odd <= 32'd0;
				
				
				//add some counter so that the number of times loop repeasts is < 3
				//if < 3, go to S_Lead_Out1, otherwise S_Lead_Out8
				if (Y_guys == 16'd159) begin
					M1State <= S_Lead_Out8;
				end
				
				else begin
					M1State <= S_Lead_Out1;
				end
				
			end
			
			//end of loop

			
			S_Lead_Out8: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				
				//from leadin case we go from U4 -> U5
				//counter goes from 0 -> 1
//				even_odd_counter <= ~even_odd_counter; 
				//even odd counter goes to 1 so next 6 CC the UV address
				// will not update because we need to stay at UV(6,7) for
				// two reads
				
				//WRITE STATE
				SRAM_write_data[15:8] <= R_Even;
				SRAM_write_data[7:0] <= G_Even;
				
				Mult1_op_1 <= 32'sd76284;
				Mult1_op_2 <= {24'd0 , SRAM_read_data[15:8]} - 32'sd16; //Y0
				
				Mult2_op_1 <= 32'sd76284;
				Mult2_op_2 <= {24'd0 , SRAM_read_data[7:0]} - 32'sd16; //Y1
				
				Mult3_op_1 <= 32'sd104595;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd104595;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				
				M1State <= S_Lead_Out9;
			
			end
			S_Lead_Out9: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				R_Odd_buf <= Mult_result2 + Mult_result4;
				G_Odd_buf <= Mult_result2;
				B_Odd_buf <= Mult_result2;
				
				R_Even_buf <= Mult_result1 + Mult_result3;
				G_Even_buf <= Mult_result1;
				B_Even_buf <= Mult_result1;
				
				//WRITE STATE
				SRAM_write_data[15:8] <= B_Even;
				SRAM_write_data[7:0] <= R_Odd;
				
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[3]};
				
				Mult3_op_1 <= -32'sd25624;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd25624;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
				Shift_Count_U[0] <= SRAM_read_data[7:0];
				Shift_Count_U[1] <= Shift_Count_U[0];
				Shift_Count_U[2] <= Shift_Count_U[1];
				Shift_Count_U[3] <= Shift_Count_U[2];
				Shift_Count_U[4] <= Shift_Count_U[3];
				Shift_Count_U[5] <= Shift_Count_U[4];
				
				M1State <= S_Lead_Out10;
			
			end
			S_Lead_Out10: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				//WRITE STATE
				SRAM_write_data[15:8] <= G_Odd;
				SRAM_write_data[7:0] <= B_Odd;
				
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
				
				Mult3_op_1 <= -32'sd53281;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd53281;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				Shift_Count_V[0] <= SRAM_read_data[7:0];	
				Shift_Count_V[1] <= Shift_Count_V[0];
				Shift_Count_V[2] <= Shift_Count_V[1];
				Shift_Count_V[3] <= Shift_Count_V[2];
				Shift_Count_V[4] <= Shift_Count_V[3];
				Shift_Count_V[5] <= Shift_Count_V[4];
				M1State <= S_Lead_Out11;
			
			end
			S_Lead_Out11: begin
				
				SRAM_we_n <= 1'b1;
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				
				
				//data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				
				
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[2]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
			
				Mult3_op_1 <= 32'sd132251;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd132251;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
				
				M1State <= S_Lead_Out12;
			
			end
			S_Lead_Out12: begin
				
				
				//Back to read
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
				Y_guys <= Y_guys + 1'b1;

				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				B_Odd_buf <= B_Odd_buf + Mult_result4;
				B_Even_buf <= B_Even_buf + Mult_result3;
				
				
			
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};
				
				M1State <= S_Lead_Out13;
			
			end
			S_Lead_Out13: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value

				
				Mult1_op_1 <= 32'sd21;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[0]};
				
				Mult2_op_1 <= 32'sd21;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[0]};
				
				Mult3_op_1 <= 32'sd21;
				Mult3_op_2 <= {24'd0 , Shift_Count_U[5]};
				
				Mult4_op_1 <= 32'sd21;
				Mult4_op_2 <= {24'd0 , Shift_Count_V[5]};
				
				R_Even_buf2 <= R_Even_buf;
				R_Odd_buf2 <= R_Odd_buf;
				
				G_Even_buf2 <= G_Even_buf;
				G_Odd_buf2 <= G_Odd_buf;
				
				B_Even_buf2 <= B_Even_buf;
				B_Odd_buf2 <= B_Odd_buf;
				
				
				M1State <= S_Lead_Out14;
			
			end
			S_Lead_Out14: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				
	
				
				//CHECKS IF WE NEED TO READ THE EVEN OR ODD VALUE IN THE PAIR
				//doesnt check the above even_odd_counter statement until 
				//next period
			
				//In this mux we're checking if we should add to the counter
				// the first time it should be updating for UV(6,7)
				// the next time it should stay at UV(6,7)
				
				
				//after lead-in case and first common case run, we need
				//to make sure we are still of U(4,5) i think we need to remove
				//this and go to the even odd conmparison thing to increment U
//				data_counterU <= data_counterU + 1'b1;
				
				// in the final case we are at oddevencoutner = 1, U157, col counter 78
				// oddevencounter = 0(updated in commoncase1), U158, col counter = 79
				
				
				Final_UPrime_Even <= Shift_Count_U[3];
				Final_VPrime_Even <= Shift_Count_V[3];
				
				Final_UPrime_Odd <= (Mult_result1 + Mult_result3 + UPrime_Odd + 32'sd128) >>> 8;
				Final_VPrime_Odd <= (Mult_result2 + Mult_result4 + VPrime_Odd + 32'sd128) >>> 8;
				
				UPrime_Odd <= 32'd0;
				VPrime_Odd <= 32'd0;
				
				M1State <= S_Lead_Out15;
			
			end
			S_Lead_Out15: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				
				//from leadin case we go from U4 -> U5
				//counter goes from 0 -> 1
//				even_odd_counter <= ~even_odd_counter; 
				//even odd counter goes to 1 so next 6 CC the UV address
				// will not update because we need to stay at UV(6,7) for
				// two reads
				
				//WRITE STATE
				SRAM_write_data[15:8] <= R_Even;
				SRAM_write_data[7:0] <= G_Even;
				
				Mult1_op_1 <= 32'sd76284;
				Mult1_op_2 <= {24'd0 , SRAM_read_data[15:8]} - 32'sd16; //Y0
				
				Mult2_op_1 <= 32'sd76284;
				Mult2_op_2 <= {24'd0 , SRAM_read_data[7:0]} - 32'sd16; //Y1
				
				Mult3_op_1 <= 32'sd104595;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd104595;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				M1State <= S_Lead_Out16;
			
			end
			S_Lead_Out16: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				R_Odd_buf <= Mult_result2 + Mult_result4;
				G_Odd_buf <= Mult_result2;
				B_Odd_buf <= Mult_result2;
				
				R_Even_buf <= Mult_result1 + Mult_result3;
				G_Even_buf <= Mult_result1;
				B_Even_buf <= Mult_result1;
				
				//WRITE STATE
				SRAM_write_data[15:8] <= B_Even;
				SRAM_write_data[7:0] <= R_Odd;
				
//				Mult1_op_1 <= -32'sd52;
//				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
//				
//				Mult2_op_1 <= -32'sd52;
//				Mult2_op_2 <= {24'd0 , Shift_Count_V[3]};
				
				Mult3_op_1 <= -32'sd25624;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd25624;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
//				Shift_Count_U[0] <= SRAM_read_data[7:0];
//				Shift_Count_U[1] <= Shift_Count_U[0];
//				Shift_Count_U[2] <= Shift_Count_U[1];
//				Shift_Count_U[3] <= Shift_Count_U[2];
//				Shift_Count_U[4] <= Shift_Count_U[3];
//				Shift_Count_U[5] <= Shift_Count_U[4];
				
				M1State <= S_Lead_Out17;
			
			end
			S_Lead_Out17: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
//				UPrime_Odd <= UPrime_Odd + Mult_result1;
//				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				//WRITE STATE
				SRAM_write_data[15:8] <= G_Odd;
				SRAM_write_data[7:0] <= B_Odd;
				
//				Mult1_op_1 <= 32'sd159;
//				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
//				
//				Mult2_op_1 <= 32'sd159;
//				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
				
				Mult3_op_1 <= -32'sd53281;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd53281;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
//				Shift_Count_V[0] <= SRAM_read_data[7:0];	
//				Shift_Count_V[1] <= Shift_Count_V[0];
//				Shift_Count_V[2] <= Shift_Count_V[1];
//				Shift_Count_V[3] <= Shift_Count_V[2];
//				Shift_Count_V[4] <= Shift_Count_V[3];
//				Shift_Count_V[5] <= Shift_Count_V[4];
				
				M1State <= S_Lead_Out18;
			
			end
			S_Lead_Out18: begin
				
				SRAM_we_n <= 1'b1;
				
//				UPrime_Odd <= UPrime_Odd + Mult_result1;
//				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				
				
				//data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				
				
//				Mult1_op_1 <= 32'sd159;
//				Mult1_op_2 <= {24'd0 , Shift_Count_U[2]};
//				
//				Mult2_op_1 <= 32'sd159;
//				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
//			
				Mult3_op_1 <= 32'sd132251;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd132251;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
				M1State <= S_Lead_Out19;
			
			end
			S_Lead_Out19: begin
				
				//Back to read
//				SRAM_we_n <= 1'b1;
//				SRAM_address <= Y_START_ADDRESS + data_counterY;
//				data_counterY <= data_counterY + 1'b1;
				
				
//				UPrime_Odd <= UPrime_Odd + Mult_result1;
//				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				B_Odd_buf <= B_Odd_buf + Mult_result4;
				B_Even_buf <= B_Even_buf + Mult_result3;
				
				
			
//				Mult1_op_1 <= -32'sd52;
//				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
//				
//				Mult2_op_1 <= -32'sd52;
//				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};

				M1State <= S_Lead_Out20;
			
			end
			S_Lead_Out20: begin
				
//				SRAM_we_n <= 1'b1;
//				SRAM_address <= U_START_ADDRESS + data_counterU;
			
//				UPrime_Odd <= UPrime_Odd + Mult_result1;
//				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value

				
//				Mult1_op_1 <= 32'sd21;
//				Mult1_op_2 <= {24'd0 , Shift_Count_U[0]};
//				
//				Mult2_op_1 <= 32'sd21;
//				Mult2_op_2 <= {24'd0 , Shift_Count_V[0]};
//				
//				Mult3_op_1 <= 32'sd21;
//				Mult3_op_2 <= {24'd0 , Shift_Count_U[5]};
//				
//				Mult4_op_1 <= 32'sd21;
//				Mult4_op_2 <= {24'd0 , Shift_Count_V[5]};
				
				R_Even_buf2 <= R_Even_buf;
				R_Odd_buf2 <= R_Odd_buf;
				
				G_Even_buf2 <= G_Even_buf;
				G_Odd_buf2 <= G_Odd_buf;
				
				B_Even_buf2 <= B_Even_buf;
				B_Odd_buf2 <= B_Odd_buf;
				
				M1State <= S_Lead_Out21;
			
			end
			S_Lead_Out21: begin
				
//				SRAM_we_n <= 1'b1;
//				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				//CHECKS IF WE NEED TO READ THE EVEN OR ODD VALUE IN THE PAIR
				//doesnt check the above even_odd_counter statement until 
				//next period
			
				//In this mux we're checking if we should add to the counter
				// the first time it should be updating for UV(6,7)
				// the next time it should stay at UV(6,7)
				
				
				//after lead-in case and first common case run, we need
				//to make sure we are still of U(4,5) i think we need to remove
				//this and go to the even odd conmparison thing to increment U
//				data_counterU <= data_counterU + 1'b1;
				
				// in the final case we are at oddevencoutner = 1, U157, col counter 78
				// oddevencounter = 0(updated in commoncase1), U158, col counter = 79
				
				
//				Final_UPrime_Even <= Shift_Count_U[3];
//				Final_VPrime_Even <= Shift_Count_V[3];
//				
//				Final_UPrime_Odd <= (Mult_result1 + Mult_result3 + UPrime_Odd + 32'sd128) >>> 8;
//				Final_VPrime_Odd <= (Mult_result2 + Mult_result4 + VPrime_Odd + 32'sd128) >>> 8;
				
//				UPrime_Odd <= 32'd0;
//				VPrime_Odd <= 32'd0;
				
				M1State <= S_Lead_Out22;
			
			end
			S_Lead_Out22: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
				
				//from leadin case we go from U4 -> U5
				//counter goes from 0 -> 1
//				even_odd_counter <= ~even_odd_counter; 
				//even odd counter goes to 1 so next 6 CC the UV address
				// will not update because we need to stay at UV(6,7) for
				// two reads
				
				//WRITE STATE
				SRAM_write_data[15:8] <= R_Even;
				SRAM_write_data[7:0] <= G_Even;
				
//				Mult1_op_1 <= 32'sd76284;
//				Mult1_op_2 <= {24'd0 , SRAM_read_data[15:8]} - 32'sd16; //Y0
//				
//				Mult2_op_1 <= 32'sd76284;
//				Mult2_op_2 <= {24'd0 , SRAM_read_data[7:0]} - 32'sd16; //Y1
//				
//				Mult3_op_1 <= 32'sd104595;
//				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
//				
//				Mult4_op_1 <= 32'sd104595;
//				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				M1State <= S_Lead_Out23;
			
			end
			S_Lead_Out23: begin
				
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
//				R_Odd_buf <= Mult_result2 + Mult_result4;
//				G_Odd_buf <= Mult_result2;
//				B_Odd_buf <= Mult_result2;
//				
//				R_Even_buf <= Mult_result1 + Mult_result3;
//				G_Even_buf <= Mult_result1;
//				B_Even_buf <= Mult_result1;
				
				//WRITE STATE
				SRAM_write_data[15:8] <= B_Even;
				SRAM_write_data[7:0] <= R_Odd;
				
//				Mult1_op_1 <= -32'sd52;
//				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
//				
//				Mult2_op_1 <= -32'sd52;
//				Mult2_op_2 <= {24'd0 , Shift_Count_V[3]};
				
//				Mult3_op_1 <= -32'sd25624;
//				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
//				
//				Mult4_op_1 <= -32'sd25624;
//				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
//				Shift_Count_U[0] <= SRAM_read_data[7:0];
//				Shift_Count_U[1] <= Shift_Count_U[0];
//				Shift_Count_U[2] <= Shift_Count_U[1];
//				Shift_Count_U[3] <= Shift_Count_U[2];
//				Shift_Count_U[4] <= Shift_Count_U[3];
//				Shift_Count_U[5] <= Shift_Count_U[4];
				
				
				
				M1State <= S_Lead_Out24;
			
			end
			S_Lead_Out24: begin
				
//				G_Odd_buf <= G_Odd_buf + Mult_result4;
//				G_Even_buf <= G_Even_buf + Mult_result3;
				
				//WRITE STATE
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				
				//rgb data count should go up everytime we write
				
				SRAM_write_data[15:8] <= G_Odd;
				SRAM_write_data[7:0] <= B_Odd;
				
				//NO LONGER DOING INTERPOLATION, SHIFT COUNTER DONT MATTER
//				Mult1_op_1 <= 32'sd159;
//				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
//				
//				Mult2_op_1 <= 32'sd159;
//				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
				
//				Mult3_op_1 <= -32'sd53281;
//				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
//				
//				Mult4_op_1 <= -32'sd53281;
//				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				//to indicate what row we are on
				row_counter <= row_counter + 8'd1;
				
				M1State <= S_Lead_Out25;
				
				//increment 
			
			end
			S_Lead_Out25: begin
				
				SRAM_we_n <= 1'b1;
				//SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				//data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write A PAIR OF RGB VALUES
				
//				UPrime_Odd <= UPrime_Odd + Mult_result1;
//				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
//				G_Odd_buf <= G_Odd_buf + Mult_result4;
//				G_Even_buf <= G_Even_buf + Mult_result3;
				
				//WRITE STATE
		
				
//				Mult1_op_1 <= 32'sd159;
//				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
//				
//				Mult2_op_1 <= 32'sd159;
//				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
				
//				Mult3_op_1 <= -32'sd53281;
//				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
//				
//				Mult4_op_1 <= -32'sd53281;
//				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				data_counterU <= data_counterU + 1'b1;
				data_counterV <= data_counterV + 1'b1;
				
				
				
				//M1State <= S_Lead_Out26;
				
				//ADD AN IF STATEMENT SO THAT WHEN ALL THE ROWS ARE DONE WE 
				//STOP 
				
				if (row_counter == 8'd240) begin
					
					M1_Stop <= 1'b1;
					
				end
				else begin
				
					M1State <= S_M1_IDLE;
				
				end
			
			end
			
			/*
			S_Lead_Out26: begin
				
				//FINISH WRITING STATE
				
				SRAM_we_n <= 1'b1;
				M1State <= S_M1_IDLE;
				
			
			end
			
			
			
			
			
			
			
			
			
			
		
		/*
			
			USE BELOW FOR WHEN CHOOSING WHICH UV DATA TO READ (ODD OR EVEN)
		
				if (even_odd_counter % 2 == 0) begin
				
					Shift_Count_U[0] <= SRAM_read_data[7:0];
					
				end else begin
				
					Shift_Count_U[0] <= SRAM_read_data[15:0];	
					
				end
		
		
			USE BELOW FOR WHEN CHOOSING TO INCREASE UV COUNTERS
			
				if (even_odd_counter % 2 == 0) begin
					
					data_counterU <= data_counterU;
				
				end else begin
				
					data_counterU <= data_counterU + 1'b1;
									
				end
		
		*/
		
		endcase
	end
end
endmodule
