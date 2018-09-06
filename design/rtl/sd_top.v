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
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        SD_CLK <= 1'b0;
    end
    else begin
        SD_CLK <= ~SD_CLK;
    end
end
reg  SD_CLK1;
always@(posedge SD_CLK or negedge rst_n)begin
    if(!rst_n)begin
        SD_CLK1 <= 1'b0;
    end
    else begin
        SD_CLK1 <= ~SD_CLK1;
    end
end
reg  SD_CLK2;
always@(posedge SD_CLK1 or negedge rst_n)begin
    if(!rst_n)begin
        SD_CLK2 <= 1'b0;
    end
    else begin
        SD_CLK2 <= ~SD_CLK2;
    end
end
reg  SD_CLK3;
always@(posedge SD_CLK2 or negedge rst_n)begin
    if(!rst_n)begin
        SD_CLK3 <= 1'b0;
    end
    else begin
        SD_CLK3 <= ~SD_CLK3;
    end
end
sd_initial sd_initial(
     .rst_n     (rst_n        )
    ,.SD_CK     (SD_CK        )
    ,.SD_MISO   (SD_MISO      )

    ,.SD_CSn    (SD_CSn_init  )
    ,.SD_MOSI   (SD_MOSI_init )
    ,.init_ok   (init_o       )
    //.state     (),
    //.rx        ()
);
sd_read sd_read(
     .rst_n      (rst_n         )
    ,.SD_MISO    (SD_MISO       )
    ,.SD_CK     (SD_CK          )
    ,.SD_MOSI    (SD_MOSI_read  )
    ,.SD_CSn     (SD_CSn_read   )
    ,.init_o     (init_o        )
    ,.read_seq   (1'b1          )//TODO read_seq
);
assign SD_MOSI = SD_MOSI_init&SD_MOSI_read;
assign SD_CSn  = SD_CSn_init&SD_CSn_read;
assign SD_CK   = SD_CLK3;
endmodule
