module sd_write(
    input      rst_n,
    input      SD_CK,
    input      SD_MISO,
    output     SD_MOSI,
    output     SD_CSn,
    input      init_o,
    input      write_seq
);
parameter idle        = 0;
parameter write_cmd   = 1;
parameter wait_8clk   = 2;
parameter write_data  = 3;
parameter write_dummy = 4;
parameter write_done  = 5;
reg[5:0]          state,next_state;
reg[10:0]         tx_cnt,next_tx_cnt;
reg[512+8+16-1:0] data,next_data;
reg[10:0]         cnt,next_cnt;
reg               SD_CS,next_SD_CS;
reg[7:0]          rx;
reg[3:0]          rx_cnt;
reg               rx_valid;
reg               en;
reg SD_DATAIN,next_SD_DATAIN;
assign SD_MOSI    = SD_DATAIN;
assign SD_DATAOUT = SD_MISO;
always@(negedge SD_CK or negedge rst_n)begin
    if(!rst_n)begin
        state     <= 0;
        SD_CS     <= 1'b0;
        SD_DATAIN <= 1'b1;
        tx_cnt    <= 0;
        cnt       <= 0;
        data      <= 0;
    end
    else begin
        state     <= next_state;
        SD_CS     <= next_SD_CS;
        SD_DATAIN <= next_SD_DATAIN;
        tx_cnt    <= next_tx_cnt;
        cnt       <= next_cnt;
        data      <= next_data;
    end
end
always@(*)begin
    next_state     = state;
    next_SD_CS     = SD_CS;
    next_SD_DATAIN = SD_DATAIN;
    next_tx_cnt    = tx_cnt-|tx_cnt;
    next_cnt       = cnt-|cnt;
    next_data      = data;
    case(state)
        idle:begin
            next_SD_CS     = 1'b1;
            next_SD_DATAIN = 1'b1;
            if(!init_o)begin
                next_state = idle;
            end
            else if(write_seq)begin
                next_data   = `CMD24;
                next_tx_cnt = 48;
                next_state  = write_cmd;
            end
        end
        write_cmd:begin
            if(|tx_cnt)begin
                next_SD_CS     = 1'b0;
                next_SD_DATAIN = data[tx_cnt-1];
                next_state     = write_cmd;
            end
            else if(rx_valid)begin
                next_state     = wait_8clk;
                next_cnt       = 8;
                next_SD_DATAIN = 1'b1;
                next_SD_CS     = 1'b1;
            end
        end
        wait_8clk:begin
            if(~|cnt)begin
                next_state  = write_data;
                next_data   = {8'hfe,512'b0,16'hff_ff};
                next_tx_cnt = 8+512+16;
            end
        end
        write_data:begin
            if(|tx_cnt)begin
                next_SD_CS     = 1'b0;
                next_SD_DATAIN = data[tx_cnt-1];
            end
            else begin
                next_state     = write_dummy;
                next_cnt       = 16;
                next_SD_CS     = 1'b1;
                next_SD_DATAIN = 1'b1;
            end
        end
        write_dummy:begin
            if(~|cnt) next_state = write_done;
        end
        write_done:begin
        end
    endcase
end
always@(posedge SD_CK or negedge rst_n)begin
    if(!rst_n)begin
        rx <= 0;
    end
    else begin
        rx <= {rx[6:0],SD_DATAOUT};
    end
end
always@(posedge SD_CK or negedge rst_n)begin
    if(!rst_n)begin
        en       <= 1'b1;
        rx_cnt   <= 0;
        rx_valid <= 1'b0;
    end
    else if(!SD_DATAIN)begin
        rx_valid <= 1'b0;
        rx_cnt   <= 48;
    end
    else if(!SD_DATAOUT&!en)begin
        en <= 1'b1;
    end
    else if(en)begin
        rx_cnt <= rx_cnt - |rx_cnt;
        if(~|rx_cnt)begin
            rx_valid <= 1'b1;
        end
    end
    else begin
        en       <= 1'b0;
        rx_valid <= 1'b0;
    end
end
assign SD_CSn = SD_CS;
endmodule
