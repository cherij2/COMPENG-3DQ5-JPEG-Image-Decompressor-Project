/*
11-9-23
Questions;
 - How many lead in/lead out cases do we need?
 - 

Notes:
 - Changed define_state to include common case states
 - need to add states into project.sv file
 - confirmthe number of lead in cases and add them so no errors show up on compilation


*/

/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

// This is the top module (same as experiment4 from lab 5 - just module renamed to "project")
// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA
module project (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_N_I,         // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[7:0] VGA_RED_O,              // VGA red
		output logic[7:0] VGA_GREEN_O,            // VGA green
		output logic[7:0] VGA_BLUE_O,             // VGA blue
		
		/////// SRAM Interface                    ////////////
		inout wire[15:0] SRAM_DATA_IO,            // SRAM data bus 16 bits
		output logic[19:0] SRAM_ADDRESS_O,        // SRAM address bus 18 bits
		output logic SRAM_UB_N_O,                 // SRAM high-byte data mask 
		output logic SRAM_LB_N_O,                 // SRAM low-byte data mask 
		output logic SRAM_WE_N_O,                 // SRAM write enable
		output logic SRAM_CE_N_O,                 // SRAM chip enable
		output logic SRAM_OE_N_O,                 // SRAM output logic enable
		
		/////// UART                              ////////////
		input logic UART_RX_I,                    // UART receive signal
		output logic UART_TX_O                    // UART transmit signal
);
	
logic resetn;

top_state_type top_state;

// For Push button
logic [3:0] PB_pushed;

// For VGA SRAM interface
logic VGA_enable;
logic [17:0] VGA_base_address;
logic [17:0] VGA_SRAM_address;

// For SRAM
logic [17:0] SRAM_address;
logic [15:0] SRAM_write_data;
logic SRAM_we_n;
logic [15:0] SRAM_read_data;
logic SRAM_ready;

// For UART SRAM interface
logic UART_rx_enable;
logic UART_rx_initialize;
logic [17:0] UART_SRAM_address;
logic [15:0] UART_SRAM_write_data;
logic UART_SRAM_we_n;
logic [25:0] UART_timer;

logic [6:0] value_7_segment [7:0];

//COLOURSPACE CONVERSION AND INTERPOLATION
logic [31:0] Y_Even;
logic [31:0] UPrime_Even;
logic [31:0] VPrime_Even;

logic [31:0] Y_Odd;
logic [31:0] UPrime_Odd;
logic [31:0] VPrime_Odd;

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

logic [17:0] even_odd_count;

interp_csc_states M1State;


// For error detection in UART
logic Frame_error;

// For disabling UART transmit
assign UART_TX_O = 1'b1;

assign resetn = ~SWITCH_I[17] && SRAM_ready;

// Push Button unit
PB_controller PB_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PB_signal(PUSH_BUTTON_N_I),	
	.PB_pushed(PB_pushed)
);

VGA_SRAM_interface VGA_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn),
	.VGA_enable(VGA_enable),
   
	// For accessing SRAM
	.SRAM_base_address(VGA_base_address),
	.SRAM_address(VGA_SRAM_address),
	.SRAM_read_data(SRAM_read_data),
   
	// To VGA pins
	.VGA_CLOCK_O(VGA_CLOCK_O),
	.VGA_HSYNC_O(VGA_HSYNC_O),
	.VGA_VSYNC_O(VGA_VSYNC_O),
	.VGA_BLANK_O(VGA_BLANK_O),
	.VGA_SYNC_O(VGA_SYNC_O),
	.VGA_RED_O(VGA_RED_O),
	.VGA_GREEN_O(VGA_GREEN_O),
	.VGA_BLUE_O(VGA_BLUE_O)
);

// UART SRAM interface
UART_SRAM_interface UART_unit(
	.Clock(CLOCK_50_I),
	.Resetn(resetn), 
   
	.UART_RX_I(UART_RX_I),
	.Initialize(UART_rx_initialize),
	.Enable(UART_rx_enable),
   
	// For accessing SRAM
	.SRAM_address(UART_SRAM_address),
	.SRAM_write_data(UART_SRAM_write_data),
	.SRAM_we_n(UART_SRAM_we_n),
	.Frame_error(Frame_error)
);

// SRAM unit
SRAM_controller SRAM_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(~SWITCH_I[17]),
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.SRAM_read_data(SRAM_read_data),		
	.SRAM_ready(SRAM_ready),
		
	// To the SRAM pins
	.SRAM_DATA_IO(SRAM_DATA_IO),
	.SRAM_ADDRESS_O(SRAM_ADDRESS_O[17:0]),
	.SRAM_UB_N_O(SRAM_UB_N_O),
	.SRAM_LB_N_O(SRAM_LB_N_O),
	.SRAM_WE_N_O(SRAM_WE_N_O),
	.SRAM_CE_N_O(SRAM_CE_N_O),
	.SRAM_OE_N_O(SRAM_OE_N_O)
);

assign SRAM_ADDRESS_O[19:18] = 2'b00;






always @(posedge CLOCK_50_I or negedge resetn) begin
	if (~resetn) begin
		top_state <= S_IDLE;
		
		M1State <= S_Lead_In1;
		
		UART_rx_initialize <= 1'b0;
		UART_rx_enable <= 1'b0;
		UART_timer <= 26'd0;
		
		VGA_enable <= 1'b1;
	
	end else begin

		// By default the UART timer (used for timeout detection) is incremented
		// it will be synchronously reset to 0 under a few conditions (see below)
		UART_timer <= UART_timer + 26'd1;

		case (top_state)
		S_IDLE: begin
			VGA_enable <= 1'b1;  
			if (~UART_RX_I) begin
				// Start bit on the UART line is detected
				UART_rx_initialize <= 1'b1;
				UART_timer <= 26'd0;
				VGA_enable <= 1'b0;
				top_state <= S_UART_RX;
			end
		end

		S_UART_RX: begin
			// The two signals below (UART_rx_initialize/enable)
			// are used by the UART to SRAM interface for 
			// synchronization purposes (no need to change)
			UART_rx_initialize <= 1'b0;
			UART_rx_enable <= 1'b0;
			if (UART_rx_initialize == 1'b1) 
				UART_rx_enable <= 1'b1;

			// UART timer resets itself every time two bytes have been received
			// by the UART receiver and a write in the external SRAM can be done
			if (~UART_SRAM_we_n) 
				UART_timer <= 26'd0;

			// Timeout for 1 sec on UART (detect if file transmission is finished)
			if (UART_timer == 26'd49999999) begin
				top_state <= S_IDLE;
				UART_timer <= 26'd0;
			end
		end
		
		
		default: top_state <= S_IDLE;

		endcase
		
		//COLOURSPACE AND INTERPOLATION

		case (M1State)
		
			S_Lead_In1 begin:
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
				data_counterU <= data_counterU + 1'b1;
				
				M1State <= S_Lead_In2;
			
			end
			
			S_Lead_In2 begin:
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				data_counterV <= data_counterV + 1'b1;
				
				M1State <= S_Lead_In3;
			
			end
			
			S_Lead_In3 begin:
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
			
				Shift_Count_U[1] <= SRAM_read_data[7:0];
				Shift_Count_U[0] <= SRAM_read_data[15:8];
				
				UOdd_Op[0] <= 32'd21 * SRAM_read_data[7:0];
				
				data_counterU <= data_counterU + 1'b1;
				
				M1State <= S_Lead_In4;
			
			end
			
			S_Lead_In4 begin:
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				Shift_Count_V[1] <= SRAM_read_data[7:0];
				Shift_Count_V[0] <= SRAM_read_data[15:8];		
			
				UOdd_Op[1] <= 32'd52 * Shift_Count_U[1];
				VOdd_Op[0] <= 32'd21 * SRAM_read_data[7:0];
				
				data_counterV <= data_counterV + 1'b1;
			
				M1State <= S_Lead_In5;
			
			end
			
			S_Lead_In5 begin:
			
				UOdd_Op[2] <= 32'd159 * Shift_Count_U[1];
				VOdd_Op[1] <= 32'd52 * Shift_Count_V[1];
			
				Shift_Count_U[2] <= Shift_Count_U[0];
				Shift_Count_U[3] <= Shift_Count_U[1];
				
				Shift_Count_U[1] <= SRAM_read_data[7:0];
				Shift_Count_U[0] <= SRAM_read_data[15:8];
				
				M1State <= S_Lead_In6;
				
			end
			
			S_Lead_In6 begin:
			
				UOdd_Op[3] <= 32'd159 * Shift_Count_U[2];
				VOdd_Op[2] <= 32'd159 * Shift_Count_V[0];
			
				Shift_Count_V[2] <= Shift_Count_V[0];
				Shift_Count_V[3] <= Shift_Count_V[1];
				
				Shift_Count_V[1] <= SRAM_read_data[7:0];
				Shift_Count_V[0] <= SRAM_read_data[15:8];
				
				M1State <= S_Lead_In7;
			
			end
			
			S_Lead_In7 begin:
			
				UOdd_Op[4] <= 32'd21 * Shift_Count_U[1];
				VOdd_Op[3] <= 32'd159 * Shift_Count_V[2];
			
				M1State <= S_Lead_In8;
			
			end
			
			S_Lead_In8 begin:
			
				UOdd_Op[5] <= 32'd52 * Shift_Count_U[0];
				VOdd_Op[4] <= 32'd21 * Shift_Count_V[1]; 
				
				M1State <= S_Lead_In9;
			
			end
			
			S_Lead_In9 begin:
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
			
				VOdd_Op[5] <= 32'd52 * Shift_Count_V[0];
				
				Shift_Count_U[4] <= Shift_Count_U[3];
				Shift_Count_U[5] <= Shift_Count_U[3];
				
				Shift_Count_V[4] <= Shift_Count_V[3];
				Shift_Count_V[5] <= Shift_Count_V[3];
				
				M1State <= S_Lead_In10;
			
			end
			
			S_Lead_In10 begin:
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
				//data_counterU <= data_counterU + 1'b1;
				// need to stay at U (4,5) so dont run this commented code
				
				UPrime_Even <= Shift_Count_U[3];
				VPrime_Even <= Shift_Count_V[3];

				UPrime_Odd <= (UOdd_Op[0] - UOdd_Op[1] + UOdd_Op[2] + UOdd_Op[3] - UOdd_Op[4] + UOdd_Op[5] + 32'd128) >> 8;
				VPrime_Odd <= (VOdd_Op[0] - VOdd_Op[1] + VOdd_Op[2] + VOdd_Op[3] - VOdd_Op[4] + VOdd_Op[5] + 32'd128) >> 8;
				
				M1State <= S_Lead_In11;
			
			end

			S_Lead_In11 begin: //CHANGE TO LEAD INS
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV; //received 2cc later
				//data_counterV <= data_counterV + 1'b1;
				// need to stay at V (4,5) so dont run this commented code
		
		
				//Y_Even[0] <= SRAM_read_data[7:0]; //Y0
				//Y_Odd[1] <= SRAM_read_data[15:8]; //Y1
				
				R_Odd_buf <= (32'd76284 * (SRAM_read_data[15:8] - 32'd16)) + (32'd104595 * (VPrime_Odd - 32'd128)); // 76284*Y1 + 104595*V1
				G_Odd_buf <= 32'd76284 * (SRAM_read_data[15:8] - 32'd16); //Y1
				B_Odd_buf <= 32'd76284 * (SRAM_read_data[15:8] - 32'd16);
				
				R_Even_buf <= (32'd76284 * (SRAM_read_data[7:0]- 32'd16)) + (32'd104595 * (VPrime_Even - 32'd128)); // 76284*Y0 + 104595*V0
				G_Even_buf <= 32'd76284 * (SRAM_read_data[7:0]- 32'd16); //Y0
				B_Even_buf <= 32'd76284 * (SRAM_read_data[7:0]- 32'd16);
				
				
				M1State <= S_Lead_In12;
				
			end
			
			S_Lead_In12 begin:
				
				
				UOdd_Op[1] <= 32'd52 * Shift_Count_U[3];
				VOdd_Op[1] <= 32'd52 * Shift_Count_V[3];
				
				G_Odd_buf <= G_Odd_buf - (32'd25624 * (UPrime_Odd - 32'd128));
				G_Even_buf <= G_Even_buf - (32'd25624 * (UPrime_Even - 32'd128));
				
				Shift_Count_U[1] <= Shift_Count_U[0];
				Shift_Count_U[2] <= Shift_Count_U[1];
				Shift_Count_U[3] <= Shift_Count_U[2];
				Shift_Count_U[4] <= Shift_Count_U[3];
				Shift_Count_U[5] <= Shift_Count_U[4];
				Shift_Count_U[0] <= SRAM_read_data[7:0];
				
				M1State <= S_Lead_In13;
			
			end
			
			S_Lead_In13 begin:
			
				UOdd_Op[2] <= 32'd159 * Shift_Count_U[3];
				VOdd_Op[2] <= 32'd159 * Shift_Count_V[2];
				
				G_Odd_buf <= G_Odd_buf - (32'd53281 * (VPrime_Odd - 32'd128));
				G_Even_buf <= G_Even_buf - (32'd53281 * (VPrime_Even - 32'd128));
				

				Shift_Count_V[1] <= Shift_Count_V[0];
				Shift_Count_V[2] <= Shift_Count_V[1];
				Shift_Count_V[3] <= Shift_Count_V[2];
				Shift_Count_V[4] <= Shift_Count_V[3];
				Shift_Count_V[5] <= Shift_Count_V[4];
				Shift_Count_V[0] <= SRAM_read_data[7:0];

				
				
				M1State <= S_Lead_In14;
			
			end
			
			S_Lead_In14 begin:
			
				UOdd_Op[3] <= 32'd159 * Shift_Count_U[2];
				VOdd_Op[3] <= 32'd159 * Shift_Count_V[2];
				
				B_Odd_buf <= B_Odd_buf + (32'd132251 * (UPrime_Odd - 32'd128));
				B_Even_buf <= B_Even_buf + (32'd132251 * (UPrime_Even - 32'd128));
				
				R_Even <= R_Even_buf >> 16;
				G_Even <= G_Even_buf >> 16;
				
				M1State <= S_Lead_In15;
			
			end
			
			S_Lead_In15 begin:
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
			
				UOdd_Op[4] <= 32'd52 * Shift_Count_U[1];
				VOdd_Op[4] <= 32'd52 * Shift_Count_V[1];
				
				B_Even <= B_Even_buf >> 16;
				R_Odd <= R_Odd_buf >> 16;
				
				M1State <= S_Lead_In16;
				
			end
			
			S_Lead_In16 begin:
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
				
				//Here we DONT increase data counter U because next time we need U(6,7)
				
			//	UOdd_Op[0] <= 32'd21 * Shift_Count_U[5];
			//	VOdd_Op[0] <= 32'd21 * Shift_Count_V[5];
				
			//	UOdd_Op[5] <= 32'd21 * Shift_Count_U[0];
			//	VOdd_Op[5] <= 32'd21 * Shift_Count_V[0];
				
				//delay in state table results in us having to do calc directly
				// in the uprime vprime odd calc
				
				G_Odd <= G_Odd_buf >> 16;
				B_Odd <= B_Odd_buf >> 16;
				
				UPrime_Even <= Shift_Count_U[3];
				VPrime_Even <= Shift_Count_V[3];
				
				UPrime_Odd <= (32'd21 * Shift_Count_U[5] - UOdd_Op[1] + UOdd_Op[2] + UOdd_Op[3] - UOdd_Op[4] + 32'd21 * Shift_Count_U[0] + 32'd128) >> 8;
				VPrime_Odd <= (32'd21 * Shift_Count_V[5] - VOdd_Op[1] + VOdd_Op[2] + VOdd_Op[3] - VOdd_Op[4] + 32'd21 * Shift_Count_V[0] + 32'd128) >> 8;
			
				even_odd_counter <= 18'b0;
			
				M1State <= S_CommonCase1;
				
				
				
			end
			
			S_CommonCase1 begin:
			
				SRAM_we_n <= 1'b1;
				SRAM_address <= V_START_ADDRESS + data_counterV;
				
				even_odd_counter <= even_odd_counter + 1'b1; 
				//even odd counter goes to 1 so next 6 CC the UV address
				// will not update because we need to stay at UV(6,7) for
				// two reads
				
				if (even_odd_counter % 2 == 0) begin
					
					data_counterV <= data_counterV;
				
				end else begin
				
					data_counterV <= data_counterV + 1'b1;
									
				end
				//In this mux we're checking if we should add to the counter
				// the first time it should be updating for UV(6,7)
				// the next time it should stay at UV(6,7) 
				
				R_Odd_buf <= (32'd76284 * (SRAM_read_data[15:8] - 32'd16)) + (32'd104595 * (VPrime_Odd - 32'd128)); // 76284*Y3 + 104595*V3
				G_Odd_buf <= 32'd76284 * (SRAM_read_data[15:8] - 32'd16); //Y3
				B_Odd_buf <= 32'd76284 * (SRAM_read_data[15:8] - 32'd16);
				
				R_Even_buf <= (32'd76284 * (SRAM_read_data[7:0] - 32'd16)) + (32'd104595 * (VPrime_Even - 8'd128)); // 76284*Y2 + 104595*V2
				G_Even_buf <= 32'd76284 * (SRAM_read_data[7:0] - 32'd16); //Y2
				B_Even_buf <= 32'd76284 * (SRAM_read_data[7:0] - 32'd16);
				
				
				M1State <= S_CommonCase2;
				
			end
			
			S_CommonCase2 begin:
				
				//WRITE STATE
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				SRAM_write_data[7:0] <= R_Even;
				SRAM_write_data[15:8] <= G_Even;
				
				UOdd_Op[1] <= 32'd52 * Shift_Count_U[3];
				VOdd_Op[1] <= 32'd52 * Shift_Count_V[3];
				
				G_Odd_buf <= G_Odd_buf - (32'd25624 * (UPrime_Odd - 32'd128));
				G_Even_buf <= G_Even_buf - (32'd25624 * (UPrime_Even - 32'd128));
				
				Shift_Count_U[1] <= Shift_Count_U[0];
				Shift_Count_U[2] <= Shift_Count_U[1];
				Shift_Count_U[3] <= Shift_Count_U[2];
				Shift_Count_U[4] <= Shift_Count_U[3];
				Shift_Count_U[5] <= Shift_Count_U[4];
				
				if (even_odd_counter % 2 == 0) begin
					
					Shift_Count_U[0] <= SRAM_read_data[7:0];
				
				end else begin
				
					Shift_Count_U[0] <= SRAM_read_data[15:0];
					
				end
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value
				
				M1State <= S_CommonCase3;
				
			end
			
			S_CommonCase3 begin:
				
				//WRITE STATE
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				SRAM_write_data[7:0] <= B_Even;
				SRAM_write_data[15:8] <= R_Odd;
				
				UOdd_Op[2] <= 32'd159 * Shift_Count_U[3];
				VOdd_Op[2] <= 32'd159 * Shift_Count_V[2];
				
				G_Odd_buf <= G_Odd_buf - (32'd53281 * (VPrime_Odd - 32'd128));
				G_Even_buf <= G_Even_buf - (32'd53281 * (VPrime_Even - 32'd128));
				
				Shift_Count_V[1] <= Shift_Count_V[0];
				Shift_Count_V[2] <= Shift_Count_V[1];
				Shift_Count_V[3] <= Shift_Count_V[2];
				Shift_Count_V[4] <= Shift_Count_V[3];
				Shift_Count_V[5] <= Shift_Count_V[4];
				
				if (even_odd_counter % 2 == 0) begin
					
					Shift_Count_V[0] <= SRAM_read_data[7:0];
				
				end else begin
				
					Shift_Count_V[0] <= SRAM_read_data[15:0];	

				end
				//if the even odd counter indicates ODD that means we have
				// gone thru once alr at this UV address so read ODD value
				
				M1State <= S_CommonCase4;
				
			end
			
			S_CommonCase4 begin:
				
				//WRITE STATE
				SRAM_we_n <= 1'b0;
				SRAM_address <= RGB_START_ADDRESS + data_counterRGB;
				data_counterRGB <= data_counterRGB + 1'b1;
				//rgb data count should go up everytime we write
				
				SRAM_write_data[7:0] <= G_Odd;
				SRAM_write_data[15:8] <= B_Odd;
				
				UOdd_Op[3] <= 32'd159 * Shift_Count_U[2];
				VOdd_Op[3] <= 32'd159 * Shift_Count_V[2];
				
				B_Odd_buf <= B_Odd_buf + (32'd132251 * (UPrime_Odd - 32'd128));
				B_Even_buf <= B_Even_buf + (32'd132251 * (UPrime_Even - 32'd128));
				
				R_Even <= R_Even_buf >> 16;
				G_Even <= G_Even_buf >> 16;
				
				M1State <= S_CommonCase5;
				
			end
			
			S_CommonCase5 begin:
				
				//Back to read
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_START_ADDRESS + data_counterY;
				data_counterY <= data_counterY + 1'b1;
				
				UOdd_Op[4] <= 32'd52 * Shift_Count_U[1];
				VOdd_Op[4] <= 32'd52 * Shift_Count_V[1];
				
				B_Even <= B_Even_buf >> 16;
				R_Odd <= R_Odd_buf >> 16;
				
				M1State <= S_CommonCase6;
				
			end
			
			S_CommonCase6 begin:
				
				SRAM_we_n <= 1'b1;
				SRAM_address <= U_START_ADDRESS + data_counterU;
				
				data_counterU <= data_counterU + 1'b1;
				
				if (even_odd_counter % 2 == 0) begin
					
					data_counterU <= data_counterU;
				
				end else begin
				
					data_counterU <= data_counterU + 1'b1;
									
				end
				//In this mux we're checking if we should add to the counter
				// the first time it should be updating for UV(6,7)
				// the next time it should stay at UV(6,7) 
				
				UOdd_Op[0] <= 32'd21 * Shift_Count_U[5];
				VOdd_Op[0] <= 32'd21 * Shift_Count_V[5];
				
				UOdd_Op[5] <= 32'd21 * Shift_Count_U[0];
				VOdd_Op[5] <= 32'd21 * Shift_Count_V[0];
				
				G_Odd <= G_Odd_buf >> 16;
				B_Odd <= B_Odd_buf >> 16;
				
				UPrime_Even <= Shift_Count_U[3];
				VPrime_Even <= Shift_Count_V[3];
				
				UPrime_Odd <= (32'd21 * Shift_Count_U[5] - UOdd_Op[1] + UOdd_Op[2] + UOdd_Op[3] - UOdd_Op[4] + 32'd21 * Shift_Count_U[0] + 32'd128) >> 8;
				VPrime_Odd <= (32'd21 * Shift_Count_V[5] - VOdd_Op[1] + VOdd_Op[2] + VOdd_Op[3] - VOdd_Op[4] + 32'd21 * Shift_Count_V[0] + 32'd128) >> 8;
				
				
				/*
				HAVE MUX TO EITHER CONTINUE TO CCASE 1
				OR TO LEAD OUT CASE. DEPENDENT ON DATA_COUNTER(?)
				*/
				
				
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

// for this design we assume that the RGB data starts at location 0 in the external SRAM
// if the memory layout is different, this value should be adjusted 
// to match the starting address of the raw RGB data segment
assign VGA_base_address = 18'd0;

// Give access to SRAM for UART and VGA at appropriate time
assign SRAM_address = (top_state == S_UART_RX) ? UART_SRAM_address : VGA_SRAM_address;

assign SRAM_write_data = (top_state == S_UART_RX) ? UART_SRAM_write_data : 16'd0;

assign SRAM_we_n = (top_state == S_UART_RX) ? UART_SRAM_we_n : 1'b1;

// 7 segment displays
convert_hex_to_seven_segment unit7 (
	.hex_value(SRAM_read_data[15:12]), 
	.converted_value(value_7_segment[7])
);

convert_hex_to_seven_segment unit6 (
	.hex_value(SRAM_read_data[11:8]), 
	.converted_value(value_7_segment[6])
);

convert_hex_to_seven_segment unit5 (
	.hex_value(SRAM_read_data[7:4]), 
	.converted_value(value_7_segment[5])
);

convert_hex_to_seven_segment unit4 (
	.hex_value(SRAM_read_data[3:0]), 
	.converted_value(value_7_segment[4])
);

convert_hex_to_seven_segment unit3 (
	.hex_value({2'b00, SRAM_address[17:16]}), 
	.converted_value(value_7_segment[3])
);

convert_hex_to_seven_segment unit2 (
	.hex_value(SRAM_address[15:12]), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(SRAM_address[11:8]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(SRAM_address[7:4]), 
	.converted_value(value_7_segment[0])
);

assign   
   SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
   SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
   SEVEN_SEGMENT_N_O[2] = value_7_segment[2],
   SEVEN_SEGMENT_N_O[3] = value_7_segment[3],
   SEVEN_SEGMENT_N_O[4] = value_7_segment[4],
   SEVEN_SEGMENT_N_O[5] = value_7_segment[5],
   SEVEN_SEGMENT_N_O[6] = value_7_segment[6],
   SEVEN_SEGMENT_N_O[7] = value_7_segment[7];

assign LED_GREEN_O = {resetn, VGA_enable, ~SRAM_we_n, Frame_error, UART_rx_initialize, PB_pushed};

endmodule
