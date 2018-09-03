module SD_TOP(
    input      rst_n,
    input      clk,
    input      SD_MISO,

    output     SD_CK,
    output     SD_MOSI,
    output     SD_CSn
);
//25M clock,MAIN clock 50M
reg  SD_CLK;
wire SD_CK;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        SD_CLK <= 1'b0;
    end
    else begin
        SD_CLK <= ~SD_CLK;
    end
end
sd_initial sd_initial(
     .rst_n     (rst_n     )
    ,.SD_CK     (SD_CK     )
    ,.SD_MISO   (SD_MISO   )

    ,.SD_CSn    (SD_CSn    )
    ,.SD_MOSI   (SD_MOSI   )
    //.init_o    (),
    //.state     (),
    //.rx        ()
);
assign SD_CK = SD_CLK;
endmodule
