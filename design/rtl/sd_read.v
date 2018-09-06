module sd_read(
    input      rst_n,
    input      SD_CK,
    input      SD_MISO,
    output     SD_MOSI,
    output     SD_CSn,
    input      init_o,
    input      read_seq
);

reg[7:0] rx;
reg[3:0] rx_cnt;
reg      rx_valid;
reg      en;
reg SD_DATAIN,next_SD_DATAIN;
assign SD_MOSI    = SD_DATAIN;
assign SD_DATAOUT = SD_MISO;
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
        en     <= 1'b1;
        rx_cnt <= 0;
    end
    else if(!SD_DATAIN)begin
        rx_valid <= 1'b0;
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
reg[47:0] data,next_data;
reg[5:0]  state,next_state;
reg[9:0]  cnt,next_cnt;
parameter idle          = 6'h00;
parameter read_cmd      = 6'h01;
parameter read_cmd_resp = 6'h02;
parameter dummy         = 6'h03;
parameter read_start    = 6'h04;
parameter read          = 6'h05;
parameter read_done     = 6'h06;
reg[5:0] tx_cnt,next_tx_cnt;
reg      SD_CS,next_SD_CS;
always@(negedge SD_CK or negedge rst_n)begin
    if(!rst_n)begin
        state  <= idle;
        data   <= 0;
        tx_cnt <= 0;
        cnt <= 0;
    end
    else begin
        state  <= next_state;
        tx_cnt <= next_tx_cnt;
        data   <= next_data;
        cnt    <= next_cnt;
    end
end
always@(*)begin
    next_state  = state;
    next_data   = data;
    next_tx_cnt = tx_cnt - |tx_cnt;
    next_cnt    = cnt - |cnt;
    case(state)
        idle:begin
            SD_CS     = 1'b1;
            SD_DATAIN = 1'b1;
            if(!init_o)begin
                next_state = state;
            end
            else if(read_seq)begin
                next_state  = read_cmd;
                next_data   = `CMD17;
                next_tx_cnt = 48;
            end
        end
        read_cmd:begin
            next_SD_CS     = 1'b0;
            if(|tx_cnt)begin
                next_state     = read;
                next_SD_DATAIN = data[tx_cnt-1];
            end
            else begin
                next_SD_DATAIN = 1'b1;
                next_state     = read_cmd_resp;
                next_cnt       = 128;
            end
        end
        read_cmd_resp:begin
            if(|cnt)begin
                if(rx_valid&rx==8'h0)begin
                    next_state = dummy;
                    next_cnt   = 128;
                end
                else begin
                    next_state = read_cmd_resp;
                end
            end
            else begin//overtime
                next_state = idle;
                next_SD_CS = 1'b1;
            end
        end
        dummy:begin
            next_state  = |cnt ? dummy : read_start;
            next_tx_cnt = 8;
            next_data   = 8'hfe;
            
        end
        read_start:begin
            if(|tx_cnt)begin
                next_SD_DATAIN = data[tx_cnt-1];
            end
            else begin
                next_cnt = 512+16;
            end
        end
        read:begin//read and check crc
            if(|cnt)begin
                next_state = read;
            end
            else begin
                next_state = read_done;
            end
        end
        read_done:begin
            //next_state = idle;
        end
     endcase
end
assign SD_CSn     = SD_CS;
endmodule
