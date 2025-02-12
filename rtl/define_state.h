`ifndef DEFINE_STATE

// for top state - we have more states than needed
typedef enum logic [2:0] {
	S_IDLE,
	S_UART_RX,
	S_M1,
	S_M2
} top_state_type;

typedef enum logic [2:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [4:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

//MILESTONE 1
typedef enum logic [6:0] {
	
	S_M1_IDLE,
	S_Lead_In1,
	S_Lead_In2,
	S_Lead_In3,
	S_Lead_In4,
	S_Lead_In5,
	S_Lead_In6,
	S_Lead_In7,
	S_Lead_In8,
	S_Lead_In9,
	S_Lead_In10,
	S_Lead_In11,
	S_Lead_In12,
	S_Lead_In13,
	S_Lead_In14,
	S_Lead_In15,
	S_Lead_In16,
	S_Lead_In17,
	S_CommonCase1,
	S_CommonCase2, //19
	S_CommonCase3, //20
	S_CommonCase4, //21
	S_CommonCase5,
	S_CommonCase6,
	S_CommonCase7,
	S_Lead_Out1,
	S_Lead_Out2,
	S_Lead_Out3,
	S_Lead_Out4,
	S_Lead_Out5,
	S_Lead_Out6,
	S_Lead_Out7,
	S_Lead_Out8,
	S_Lead_Out9,
	S_Lead_Out10,
	S_Lead_Out11,
	S_Lead_Out12,
	S_Lead_Out13,
	S_Lead_Out14,
	S_Lead_Out15,
	S_Lead_Out16,
	S_Lead_Out17,
	S_Lead_Out18,
	S_Lead_Out19,
	S_Lead_Out20,
	S_Lead_Out21,
	S_Lead_Out22,
	S_Lead_Out23,
	S_Lead_Out24,
	S_Lead_Out25
	
	
} interp_csc_states;

//MILESTONE 2
typedef enum logic [6:0] {
	
	S_M2_IDLE,
	
	S_Read_Lead_In1,
	S_Read_Lead_In2,
	S_Read_Lead_In3,
	S_Read_CommonCase1,
	S_Read_CommonCase2, //19
	S_Read_CommonCase3, //20
	S_Read_CommonCase4, //21
	S_Read_CommonCase5,
	S_Read_CommonCase6,
	S_Read_CommonCase7,
	S_Read_CommonCase8,
	S_Read_Lead_Out1,
	
	T_Calc_Lead_In1,
	T_Calc_CommonCase1,
	T_Calc_CommonCase2,
	T_Calc_CommonCase3,
	T_Calc_CommonCase4,
	T_Calc_CommonCase5,
	T_Calc_CommonCase6,
	T_Calc_CommonCase7,
	T_Calc_CommonCase8,
	T_Calc_CommonCase9,
	T_Calc_CommonCase10,
	T_Calc_CommonCase11,
	T_Calc_CommonCase12,
	T_Calc_CommonCase13,
	T_Calc_CommonCase14,
	T_Calc_CommonCase15,
	T_Calc_CommonCase16,
	T_Calc_CommonCase17,
	T_Calc_Lead_Out1,
	
	S_Calc_Lead_In1,
	S_Calc_CommonCase1,
	S_Calc_CommonCase2,
	S_Calc_CommonCase3,
	S_Calc_CommonCase4,
	S_Calc_CommonCase5,
	S_Calc_CommonCase6,
	S_Calc_CommonCase7,
	S_Calc_CommonCase8,
	S_Calc_CommonCase9,
	S_Calc_CommonCase10,
	S_Calc_CommonCase11,
	S_Calc_CommonCase12,
	S_Calc_CommonCase13,
	S_Calc_CommonCase14,
	S_Calc_CommonCase15,
	S_Calc_CommonCase16,
	S_Calc_Lead_Out1,
	
	
	
	
	
	S_Lead_In1,
	
	
} inv_cos_states;


parameter
	Y_START_ADDRESS = 18'd0,
	U_START_ADDRESS = 18'd38400,
	V_START_ADDRESS = 18'd57600,
	RGB_START_ADDRESS = 18'd146944,
	
	Y_START_ADDRESS_M2 = 18'd76800,
	U_START_ADDRESS_M2 = 18'd153600, 
	V_START_ADDRESS_M2 = 18'd192000;

	

parameter 
   VIEW_AREA_LEFT = 160,
   VIEW_AREA_RIGHT = 480,
   VIEW_AREA_TOP = 120,
   VIEW_AREA_BOTTOM = 360;

`define DEFINE_STATE 1
`endif
