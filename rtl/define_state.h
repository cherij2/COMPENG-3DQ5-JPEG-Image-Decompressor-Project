`ifndef DEFINE_STATE

// for top state - we have more states than needed
typedef enum logic [1:0] {
	S_IDLE,
	S_UART_RX,
	S_M1
} top_state_type;

typedef enum logic [1:0] {
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

typedef enum logic [3:0] {
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

typedef enum logic [4:0] {
	
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
	S_CommonCase1,
	S_CommonCase2,
	S_CommonCase3,
	S_CommonCase4,
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

parameter
	Y_START_ADDRESS = 18'd0,
	U_START_ADDRESS = 18'd38400,
	V_START_ADDRESS = 18'd57600,
	RGB_START_ADDRESS = 18'd146944;

parameter 
   VIEW_AREA_LEFT = 160,
   VIEW_AREA_RIGHT = 480,
   VIEW_AREA_TOP = 120,
   VIEW_AREA_BOTTOM = 360;

`define DEFINE_STATE 1
`endif
