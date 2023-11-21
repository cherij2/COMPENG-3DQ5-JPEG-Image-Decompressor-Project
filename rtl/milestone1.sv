
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
logic [31:0] Y_Even;
logic [31:0] UPrime_Even;
logic [31:0] VPrime_Even;

logic [31:0] Y_Odd;
logic [31:0] UPrime_Odd;
logic [31:0] VPrime_Odd;

logic [31:0] Final_UPrime_Odd;
logic [31:0] Final_VPrime_Odd;


logic [31:0] Shift_Count_U [5:0];
logic [31:0] Shift_Count_V [5:0];

//logic [7:0] Y_reg [1:0];

logic [31:0] UOdd_Op [5:0];
logic [31:0] VOdd_Op [5:0];

logic [17:0] data_counterU;
logic [17:0] data_counterV;
logic [17:0] data_counterY;
logic [17:0] data_counterRGB;
logic [17:0] data_counter;
logic even_odd_counter;

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

//logic [17:0] even_odd_count;


//Instantiate 4 Multipliers
logic [31:0] Mult1_op_1, Mult1_op_2, Mult2_op_1, Mult2_op_2, Mult3_op_1, Mult3_op_2, Mult4_op_1, Mult4_op_2;
logic [63:0] Mult_result_long1, Mult_result_long2, Mult_result_long3, Mult_result_long4;

always_comb begin

	assign Mult_result_long1 = Mult1_op_1 * Mult1_op_2;
	assign Mult_result_long2 = Mult2_op_1 * Mult2_op_2;
	assign Mult_result_long3 = Mult3_op_1 * Mult3_op_2;
	assign Mult_result_long4 = Mult4_op_1 * Mult4_op_2;

	assign Mult_result1 = Mult_result_long1[31:0];
	assign Mult_result2 = Mult_result_long2[31:0];
	assign Mult_result3 = Mult_result_long3[31:0];
	assign Mult_result4 = Mult_result_long4[31:0];
	
end

//Handle clipping and signed RGB stuff

assign R_Even = R_Even_buf2[31] ? 8'd0 : ( |R_Even_buf2[30:24] ? 8'd255 : R_Even_buf2[23:16] );
assign R_Odd = R_Odd_buf2[31] ? 8'd0 : ( |R_Odd_buf2[30:24] ? 8'd255 : R_Odd_buf2[23:16] );

assign B_Even = B_Even_buf2[31] ? 8'd0 : ( |B_Even_buf2[30:24] ? 8'd255 : B_Even_buf2[23:16] );
assign B_Odd = B_Odd_buf2[31] ? 8'd0 : ( |B_Odd_buf2[30:24] ? 8'd255 : B_Odd_buf2[23:16] );

assign G_Even = G_Even_buf2[31] ? 8'd0 : ( |G_Even_buf2[30:24] ? 8'd255 : G_Even_buf2[23:16] );
assign G_Odd = G_Odd_buf2[31] ? 8'd0 : ( |G_Odd_buf2[30:24] ? 8'd255 : G_Odd_buf2[23:16] );

interp_csc_states M1State;

always_ff @ (posedge Clock or negedge Resetn) begin

if (~Resetn) begin
		M1State <= S_M1_IDLE;
				
	
	end else begin

	case (M1State)

			S_M1_IDLE: begin
				if(M1_Enable == 1'b1) begin
					M1State <= S_Lead_In1;
				end
			end
		
			S_Lead_In1: begin
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
				data_counterU <= data_counterU + 1'b1;
				
				M1State <= S_Lead_In2;
			
			end
			
			S_Lead_In2: begin
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				data_counterV <= data_counterV + 1'b1;
				
				M1State <= S_Lead_In3;
			
			end
			
			S_Lead_In3: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
			
				Shift_Count_U[1] <= SRAM_read_data[7:0];
				Shift_Count_U[0] <= SRAM_read_data[15:8];
				
				Mult1_op_1 <= 32'sd21;
				Mult1_op_2 <= {24'd0 , SRAM_read_data[7:0]};
				
				//UOdd_Op[0] <= 32'd21 * SRAM_read_data[7:0];
				
				data_counterU <= data_counterU + 1'b1;
				
				M1State <= S_Lead_In4;
			
			end
			
			S_Lead_In4: begin
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				Shift_Count_V[1] <= SRAM_read_data[7:0];
				Shift_Count_V[0] <= SRAM_read_data[15:8];		
			
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= Shift_Count_U[1];
				
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
			
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
				
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
			
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[2]};
				
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
			
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
			
				//UOdd_Op[4] <= 32'd21 * Shift_Count_U[1];
				//VOdd_Op[3] <= 32'd159 * Shift_Count_V[2];
			
				M1State <= S_Lead_In8;
			
			end
			
			S_Lead_In8: begin
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
			
				Mult1_op_1 <= 32'sd21;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[0]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};
				
				Mult3_op_1 <= 32'sd21;
				Mult3_op_2 <= {24'd0 , Shift_Count_V[0]};
			
				//UOdd_Op[5] <= 32'd52 * Shift_Count_U[0];
				//VOdd_Op[4] <= 32'd21 * Shift_Count_V[1]; 
				
				M1State <= S_Lead_In9;
			
			end
			
			S_Lead_In9: begin
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2 + Mult_result3;
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
			
				//VOdd_Op[5] <= 32'd52 * Shift_Count_V[0]; DONE IN PREV STATE
				
				Shift_Count_U[4] <= Shift_Count_U[3];
				Shift_Count_U[5] <= Shift_Count_U[3];
				
				Shift_Count_V[4] <= Shift_Count_V[3];
				Shift_Count_V[5] <= Shift_Count_V[3];
				
				M1State <= S_Lead_In10;
			
			end
			
			S_Lead_In10: begin
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
				//data_counterU <= data_counterU + 1'b1;
				// need to stay at U (4,5) so dont run this commented code
				
				UPrime_Even <= Shift_Count_U[3];
				VPrime_Even <= Shift_Count_V[3];

				Final_UPrime_Odd <= (UPrime_Odd + 32'd128) >>> 8;
				Final_VPrime_Odd <= (VPrime_Odd + 32'd128) >>> 8;

				//UPrime_Odd <= (UOdd_Op[0] - UOdd_Op[1] + UOdd_Op[2] + UOdd_Op[3] - UOdd_Op[4] + UOdd_Op[5] + 32'd128) >>> 8;
				//VPrime_Odd <= (VOdd_Op[0] - VOdd_Op[1] + VOdd_Op[2] + VOdd_Op[3] - VOdd_Op[4] + VOdd_Op[5] + 32'd128) >>> 8;
				
				UPrime_Odd <= 32'd0;
				VPrime_Odd <= 32'd0;
				
				M1State <= S_Lead_In11;
			
			end

			S_Lead_In11: begin //CHANGE TO LEAD INS
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV; //received 2cc later
				//data_counterV <= data_counterV + 1'b1;
				// need to stay at V (4,5) so dont run this commented code
		
		
				//Y_Even[0] <= SRAM_read_data[7:0]; //Y0
				//Y_Odd[1] <= SRAM_read_data[15:8]; //Y1
				
				Mult1_op_1 <= 32'sd76284;
				Mult1_op_2 <= {24'd0 , SRAM_read_data[7:0]} - 32'sd16; //Y0
				
				Mult2_op_1 <= 32'sd76284;
				Mult2_op_2 <= {24'd0 , SRAM_read_data[15:8]} - 32'sd16; //Y1
				
				Mult3_op_1 <= 32'sd104595;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd21;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				//R_Odd_buf <= (32'd76284 * (SRAM_read_data[15:8] - 32'd16)) + (32'd104595 * (VPrime_Odd - 32'd128)); // 76284*Y1 + 104595*V1
				//G_Odd_buf <= 32'd76284 * (SRAM_read_data[15:8] - 32'd16); //Y1
				//B_Odd_buf <= 32'd76284 * (SRAM_read_data[15:8] - 32'd16);
				
				//R_Even_buf <= (32'd76284 * (SRAM_read_data[7:0]- 32'd16)) + (32'd104595 * (VPrime_Even - 32'd128)); // 76284*Y0 + 104595*V0
				//G_Even_buf <= 32'd76284 * (SRAM_read_data[7:0]- 32'd16); //Y0
				//B_Even_buf <= 32'd76284 * (SRAM_read_data[7:0]- 32'd16);
				
				
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
				
				//UOdd_Op[1] <= 32'd52 * Shift_Count_U[3];
				//VOdd_Op[1] <= 32'd52 * Shift_Count_V[3];
				
				Mult3_op_1 <= -32'sd25624;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd25624;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
				//G_Odd_buf <= G_Odd_buf - (32'd25624 * (UPrime_Odd - 32'd128));
				//G_Even_buf <= G_Even_buf - (32'd25624 * (UPrime_Even - 32'd128));
				
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
				VPrime_Odd <= UPrime_Odd + Mult_result2;
			
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
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= UPrime_Odd + Mult_result2;
			
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
			
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= UPrime_Odd + Mult_result2;
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
				
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
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
				//UPrime_Odd <= UPrime_Odd + Mult_result1 + Mult_result3;
				//VPrime_Odd <= UPrime_Odd + Mult_result2 + Mult_result4;
				
				UPrime_Even <= Shift_Count_U[3];
				VPrime_Even <= Shift_Count_V[3];
				
				Final_UPrime_Odd <= (Mult_result1 + Mult_result3 + UPrime_Odd + 32'd128) >>> 8;
				Final_VPrime_Odd <= (Mult_result2 + Mult_result4 + VPrime_Odd + 32'd128) >>> 8;
				
				//G_Odd <= G_Odd_buf >> 16;
				//B_Odd <= B_Odd_buf >> 16;
				
				even_odd_counter <= 1'b0;
				
				M1State <= S_CommonCase1;
			
			end
			
			S_CommonCase1: begin
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				even_odd_counter <= even_odd_counter + 1'b1; 
				//even odd counter goes to 1 so next 6 CC the UV address
				// will not update because we need to stay at UV(6,7) for
				// two reads
				
				if (even_odd_counter == 0) begin
					
					data_counterV <= data_counterV;
				
				end else begin
				
					data_counterV <= data_counterV + 1'b1;
									
				end
				//In this mux we're checking if we should add to the counter
				// the first time it should be updating for UV(6,7)
				// the next time it should stay at UV(6,7) 
				
				Mult1_op_1 <= 32'sd76284;
				Mult1_op_2 <= {24'd0 , SRAM_read_data[7:0]} - 32'sd16; //Y0
				
				Mult2_op_1 <= 32'sd76284;
				Mult2_op_2 <= {24'd0 , SRAM_read_data[15:8]} - 32'sd16; //Y1
				
				Mult3_op_1 <= 32'sd104595;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd21;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				
				M1State <= S_CommonCase2;
				
			end
			
			S_CommonCase2: begin
				
				R_Odd_buf <= Mult_result2 + Mult_result4;
				G_Odd_buf <= Mult_result2;
				B_Odd_buf <= Mult_result2;
				
				R_Even_buf <= Mult_result1 + Mult_result3;
				G_Even_buf <= Mult_result1;
				B_Even_buf <= Mult_result1;
				
				//WRITE STATE
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				SRAM_write_data[7:0] <= R_Even;
				SRAM_write_data[15:8] <= G_Even;
				
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
					
					Shift_Count_U[0] <= SRAM_read_data[7:0];
				
				end else begin
				
					Shift_Count_U[0] <= SRAM_read_data[15:0];
					
				end
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value
				
				M1State <= S_CommonCase3;
				
			end
			
			S_CommonCase3: begin
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				//WRITE STATE
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				SRAM_write_data[7:0] <= B_Even;
				SRAM_write_data[15:8] <= R_Odd;
				
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
					
					Shift_Count_V[0] <= SRAM_read_data[7:0];
				
				end else begin
				
					Shift_Count_V[0] <= SRAM_read_data[15:0];	

				end
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value
				
				M1State <= S_CommonCase4;
				
			end
			
			S_CommonCase4: begin
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= UPrime_Odd + Mult_result2;
			
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				//WRITE STATE
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				SRAM_write_data[7:0] <= G_Odd;
				SRAM_write_data[15:8] <= B_Odd;
				
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
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= UPrime_Odd + Mult_result2;
			
				B_Odd_buf <= B_Odd_buf + Mult_result4;
				B_Even_buf <= B_Even_buf + Mult_result3;
				
				//Back to read
				SRAM_we_n <= 1'b1;
			
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};
				
				
				M1State <= S_CommonCase6;
				
			end
			
			S_CommonCase6: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
				
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
				SRAM_address <= U_START_ADDRESS + data_counterU;
				data_counterU <= data_counterU + 1'b1;
				
				if (even_odd_counter == 0) begin
					
					data_counterU <= data_counterU;
				
				end else begin
				
					data_counterU <= data_counterU + 1'b1;
					even_odd_counter <= 1'b0;
									
				end
				
				UPrime_Even <= Shift_Count_U[3];
				VPrime_Even <= Shift_Count_V[3];
				
				Final_UPrime_Odd <= (Mult_result1 + Mult_result3 + UPrime_Odd + 32'd128) >>> 8;
				Final_VPrime_Odd <= (Mult_result2 + Mult_result4 + VPrime_Odd + 32'd128) >>> 8;
				
				if (data_counterU == 32'd79 && data_counterV == 32'd79) begin
				
					M1State <= S_Lead_Out1;
					
				
				end
				
				else begin
					
					M1State <= S_CommonCase1;
					
					//need to get from 158 to 159
					data_counterV <= data_counterV + 1'b1;
					data_counterU <= data_counterU + 1'b1;
					
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
				
				
				SRAM_we_n <= 1'b1;
				
				//WE REACHED FINAL PIXEL IN ROW WE CAN STOP INCREASING READ INDEX, 
				//data_counterV stays the same, we are reading '159' everytime

				
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				
				//EVEN ODD NOT NEEDED CUZ WE JUS NEED THE TOP VALUE IN THE SHIFT REGISTER,
				//DUPLICATE THAT VALUE EVERYTIME WE NEED TO CALUCLATE THE NEXT U'V' VALUE
				
				
//				even_odd_counter <= even_odd_counter + 1'b1; 
				//even odd counter goes to 1 so next 6 CC the UV address
				// will not update because we need to stay at UV(6,7) for
				// two reads
				
//				if (even_odd_counter == 0) begin
//					
//					data_counterV <= data_counterV;
//				
//				end else begin
//				
//					data_counterV <= data_counterV + 1'b1;
//									
//				end
				//In this mux we're checking if we should add to the counter
				// the first time it should be updating for UV(6,7)
				// the next time it should stay at UV(6,7) 
				
				Mult1_op_1 <= 32'sd76284;
				Mult1_op_2 <= {24'd0 , SRAM_read_data[7:0]} - 32'sd16; //Y0
				
				Mult2_op_1 <= 32'sd76284;
				Mult2_op_2 <= {24'd0 , SRAM_read_data[15:8]} - 32'sd16; //Y1
				
				Mult3_op_1 <= 32'sd104595;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd21;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				M1State <= S_Lead_Out2;
			
			end
			
			S_Lead_Out2: begin
				
				//accumulation or RGB calculations
				R_Odd_buf <= Mult_result2 + Mult_result4;
				G_Odd_buf <= Mult_result2;
				B_Odd_buf <= Mult_result2;
				
				R_Even_buf <= Mult_result1 + Mult_result3;
				G_Even_buf <= Mult_result1;
				B_Even_buf <= Mult_result1;
				
				//WRITE STATE
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				SRAM_write_data[7:0] <= R_Even;
				SRAM_write_data[15:8] <= G_Even;
				
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[3]};
				
				Mult3_op_1 <= -32'sd25624;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd25624;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
				
				//'159' being read every time
				Shift_Count_U[0] <= SRAM_read_data[15:0];
				Shift_Count_U[1] <= Shift_Count_U[0];
				Shift_Count_U[2] <= Shift_Count_U[1];
				Shift_Count_U[3] <= Shift_Count_U[2];
				Shift_Count_U[4] <= Shift_Count_U[3];
				Shift_Count_U[5] <= Shift_Count_U[4];
				
//				if (even_odd_counter == 0) begin
//					
//					Shift_Count_U[0] <= SRAM_read_data[7:0];
//				
//				end else begin
//				
//					Shift_Count_U[0] <= SRAM_read_data[15:0];	
//
//				end
				
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value
				
				
				M1State <= S_Lead_Out3;
			
			end
			S_Lead_Out3: begin
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= VPrime_Odd + Mult_result2;
				
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				//WRITE STATE
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				SRAM_write_data[7:0] <= B_Even;
				SRAM_write_data[15:8] <= R_Odd;
				
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[3]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
				
				Mult3_op_1 <= -32'sd53281;
				Mult3_op_2 <= Final_VPrime_Even - 32'sd128;
				
				Mult4_op_1 <= -32'sd53281;
				Mult4_op_2 <= Final_VPrime_Odd - 32'sd128;
				
				//same thing as U, reading '159' over and over again
				
				Shift_Count_V[0] <= SRAM_read_data[15:0];	
				Shift_Count_V[1] <= Shift_Count_V[0];
				Shift_Count_V[2] <= Shift_Count_V[1];
				Shift_Count_V[3] <= Shift_Count_V[2];
				Shift_Count_V[4] <= Shift_Count_V[3];
				Shift_Count_V[5] <= Shift_Count_V[4];
				
//				if (even_odd_counter == 0) begin
//					
//					Shift_Count_V[0] <= SRAM_read_data[7:0];
//				
//				end else begin
//				
//					Shift_Count_V[0] <= SRAM_read_data[15:0];	
//
//				end
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value
				
				
				M1State <= S_Lead_Out4;
			
			end
			S_Lead_Out4: begin
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= UPrime_Odd + Mult_result2;
			
				G_Odd_buf <= G_Odd_buf + Mult_result4;
				G_Even_buf <= G_Even_buf + Mult_result3;
				
				//WRITE STATE
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				SRAM_write_data[7:0] <= G_Odd;
				SRAM_write_data[15:8] <= B_Odd;
				
				Mult1_op_1 <= 32'sd159;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[2]};
				
				Mult2_op_1 <= 32'sd159;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[2]};
			
				Mult3_op_1 <= 32'sd132251;
				Mult3_op_2 <= Final_UPrime_Even - 32'sd128;
				
				Mult4_op_1 <= 32'sd132251;
				Mult4_op_2 <= Final_UPrime_Odd - 32'sd128;
			
			end
			S_Lead_Out5: begin
				
				UPrime_Odd <= UPrime_Odd + Mult_result1;
				VPrime_Odd <= UPrime_Odd + Mult_result2;
			
				B_Odd_buf <= B_Odd_buf + Mult_result4;
				B_Even_buf <= B_Even_buf + Mult_result3;
				
				//Back to read
				SRAM_we_n <= 1'b1;
			
				Mult1_op_1 <= -32'sd52;
				Mult1_op_2 <= {24'd0 , Shift_Count_U[1]};
				
				Mult2_op_1 <= -32'sd52;
				Mult2_op_2 <= {24'd0 , Shift_Count_V[1]};
				
				M1State <= S_Lead_Out6;
			
			end
			S_Lead_Out6: begin
				
				SRAM_we_n <= 1'b1;
				
				//Y ADDRESSES STILL NEED TO BE READ, LOOP WILL END ONCE
				//WE NO LONGER HAVE TO READ Y ADDRESSES
				//CHECK IF Y COUNTER = 159 ON STATE 7, FINAL PAIR OF Y VALUES
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
				
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
				
				M1State <= S_Lead_Out7;
			
			end
			S_Lead_Out7: begin
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
				//NO LONGER READING NEW U VALUES, '159' BEING REPEATED
//				data_counterU <= data_counterU + 1'b1;
				
//				if (even_odd_counter == 0) begin
//					
//					data_counterU <= data_counterU;
//				
//				end else begin
//				
//					data_counterU <= data_counterU + 1'b1;
//					even_odd_counter <= 1'b0;
//									
//				end
				
				UPrime_Even <= Shift_Count_U[3];
				VPrime_Even <= Shift_Count_V[3];
				
				Final_UPrime_Odd <= (Mult_result1 + Mult_result3 + UPrime_Odd + 32'd128) >>> 8;
				Final_VPrime_Odd <= (Mult_result2 + Mult_result4 + VPrime_Odd + 32'd128) >>> 8;
				
				//add some counter so that the number of times loop repeasts is < 3
				//if < 3, go to S_Lead_Out1, otherwise S_Lead_Out8
				if (data_counterY == 8'd159) begin
					M1State <= S_Lead_Out1;
				end
				
				else begin
					M1State <= S_Lead_Out8;
				end
				
			end
			
			//end of loop
			
			
			
			
			
			
			
			
			
			
			
			
			S_Lead_Out8: begin
				
				
				M1State <= S_Lead_Out9;
			
			end
			S_Lead_Out9: begin
				
				
				M1State <= S_Lead_Out10;
			
			end
			S_Lead_Out10: begin
				
				
				M1State <= S_Lead_Out11;
			
			end
			S_Lead_Out11: begin
				
				
				M1State <= S_Lead_Out12;
			
			end
			S_Lead_Out12: begin
				
				
				M1State <= S_Lead_Out13;
			
			end
			S_Lead_Out13: begin
				
				
				M1State <= S_Lead_Out14;
			
			end
			S_Lead_Out14: begin
				
				
				M1State <= S_Lead_Out15;
			
			end
			S_Lead_Out15: begin
				
				
				M1State <= S_Lead_Out16;
			
			end
			S_Lead_Out16: begin
				
				
				M1State <= S_Lead_Out17;
			
			end
			S_Lead_Out17: begin
				
				
				M1State <= S_Lead_Out18;
			
			end
			S_Lead_Out18: begin
				
				
				M1State <= S_Lead_Out19;
			
			end
			S_Lead_Out19: begin
				
				
				M1State <= S_Lead_Out20;
			
			end
			S_Lead_Out20: begin
				
				
				M1State <= S_Lead_Out21;
			
			end
			S_Lead_Out21: begin
				
				
				M1State <= S_Lead_Out22;
			
			end
			S_Lead_Out22: begin
				
				
				M1State <= S_Lead_Out23;
			
			end
			S_Lead_Out23: begin
				
				
				M1State <= S_Lead_Out24;
			
			end
			S_Lead_Out24: begin
				
				
				M1State <= S_Lead_Out25;
			
			end
			S_Lead_Out25: begin
				
				
				M1State <= S_Lead_In1;
			
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
