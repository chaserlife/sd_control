//COMMAND
`define CMD0   {8'h40,8'h00,8'h00,8'h00,8'h00,8'h95};  //CMD0,CRC 95
`define CMD8   {8'h48,8'h00,8'h00,8'h01,8'haa,8'h87};  //CMD8,CRC 87
`define CMD55  {8'h77,8'h00,8'h00,8'h00,8'h00,8'hff};  //CMD55,no need CRC
`define ACMD41 {8'h69,8'h40,8'h00,8'h00,8'h00,8'hff};  //CMD41,no need CRC

`define FPGA
