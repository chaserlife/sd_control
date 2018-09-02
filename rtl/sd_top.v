module SD_TOP(
    input      rst_n,
    input      clk,
    input      SD_DATAOUT,

    output reg SD_CLK,
    output reg SD_DATAIN,
    output reg SD_CS
);
//25M clock,MAIN clock 50M
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        SD_CLK <= 1'b0;
    end
    else begin
        SD_CLK <= ~SD_CLK;
    end
end
sd_initial(
    .rst_n     (rst_n     ),
    .SD_CLK    (SD_CLK    ),
    .SD_DATAOUT(SD_DATAOUT),

    .SD_CS     (SD_CS     ),
    .SD_DATAIN (SD_DATAIN ),
    .init_o    (),
    .state     (),
    .rx        ()
);

endmodule
