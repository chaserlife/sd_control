//COMMAND
`define CMD0   {8'h40,8'h00,8'h00,8'h00,8'h00,8'h95}  //CMD0,CRC 95
`define CMD8   {8'h48,8'h00,8'h00,8'h01,8'haa,8'h87}  //CMD8,CRC 87
`define CMD55  {8'h77,8'h00,8'h00,8'h00,8'h00,8'hff}  //CMD55,no need CRC
`define ACMD41 {8'h69,8'h40,8'h00,8'h00,8'h00,8'hff}  //CMD41,no need CRC
//`define CMD17  {8'h51,sec[31:24],sec[23:16],sec[15:8],sec[7:0],8'hff}//block read
`define CMD17  {8'h51,8'h0,8'h0,8'h0,8'h0,8'hff}//block read
//resp.
`define DATA_R1_CMD0   {8'h01,8'hff,8'hff,8'hff,8'hff,8'hff}//[47:40]=8'h01
`define DATA_R7_CMD8   {8'h7f,8'hff,8'hff,8'hf1,8'hff,8'hff}//[19:16]=4'h01
`define DATA_R1_CMD55  {8'h01,8'hff,8'hff,8'hff,8'hff,8'hff}//[47:40]=8'h01
`define DATA_R1_ACMD41 {8'h00,8'hff,8'hff,8'hff,8'hff,8'hff}//[47:40]=8'h00
`define FPGA
