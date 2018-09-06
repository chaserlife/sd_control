//Author :Lim
//function:
//to initial SD Card
module sd_initial(
    input           rst_n,
    input           SD_CK,
    input           SD_MISO,
    output          SD_MOSI,
    output          SD_CSn,
    output          init_ok
    //output reg[3:0] state,
    //output reg[47:0] rx
);

`ifdef FPGA
parameter idle        =4'b0000; //idle
parameter send_cmd0   =4'b0001; //send cmd0
parameter wait_01     =4'b0010; //wait cmd0 resp.
parameter waitb       =4'b0011; //wait a time
parameter send_cmd8   =4'b0100; //send cmd8
parameter waita       =4'b0101; //wait cmd8 resp.
parameter send_cmd55  =4'b0110; //send cmd55
parameter send_acmd41 =4'b0111; //send acmd41
parameter init_done   =4'b1000; //initial done
parameter init_fail   =4'b1001; //initial fail
parameter dummy       =4'b1010; //dummy
`else

`endif

//receive sd data
reg      en;//enalbe signal to start receive data
reg[5:0] rx_cnt;//rx counter for reveive 48 data
reg      rx_valid;
reg[47:0]rx;

reg[5:0] state,next_state;
reg      init_o,next_init_o;
reg      SD_DATAIN,next_SD_DATAIN;
reg      SD_CS,next_SD_CS;
reg[5:0] tx_cnt,next_tx_cnt;
reg[47:0]data,next_data;
reg[9:0] cnt,next_cnt;
wire     SD_DATAOUT;
always@(posedge SD_CK or negedge rst_n)begin
    if(!rst_n)begin
        en       <= 1'b0;
        rx_valid <= 1'b0;
        rx_cnt   <= 0;
        rx       <= 48'hff_ff_ff_ff_ff_ff;
    end
    else begin
        if(!SD_DATAIN)begin
            rx <= 48'hff_ff_ff_ff_ff_ff;
            en <= 1'b0;
        end
        else if(!SD_DATAOUT&!en)begin
            rx[47:0] <= {rx[46:0],SD_DATAOUT};
            rx_valid <= 1'b0;
            en       <= 1'b1;
            rx_cnt   <= 47;
        end
        else if(en)begin
            rx_cnt   <= rx_cnt - |rx_cnt;
            if(|rx_cnt)begin
                rx[47:0] <= {rx[46:0],SD_DATAOUT};
            end
            else begin
                rx_valid <= 1'b1;
                en       <= 1'b0;
            end
        end
        else begin
            rx_valid <= 1'b0;
        end
    end
end

always@(negedge SD_CK or negedge rst_n)begin
    if(!rst_n)begin
        state     <= idle;
        init_o    <= 1'b0;
        SD_DATAIN <= 1'b1;
        SD_CS     <= 1'b1;
        tx_cnt    <= 0;
        data      <= 0;
        cnt       <= 0;
    end
    else begin
        state     <= next_state;
        init_o    <= next_init_o;
        SD_DATAIN <= next_SD_DATAIN;
        SD_CS     <= next_SD_CS;
        tx_cnt    <= next_tx_cnt;
        data      <= next_data;
        cnt       <= next_cnt;
    end
end
always@(*)begin
    next_state     = state;
    next_tx_cnt    = tx_cnt - |tx_cnt;
    next_init_o    = init_o;
    next_SD_DATAIN = SD_DATAIN;
    next_SD_CS     = SD_CS;
    next_data      = data;
    next_cnt       = cnt  - |cnt;
    case(state)
        idle:begin
            next_cnt       = 1023;
            next_SD_CS     = 1'b1;
            next_SD_DATAIN = 1'b1;
            next_init_o    = 1'b0;
            next_state     = dummy;
        end
        dummy:begin
            if(|cnt)begin
                next_state = dummy;
            end
            else begin
                next_SD_CS  = 1'b1;
                next_state  = send_cmd0;
                next_data   = `CMD0;
                next_tx_cnt = 48;
                next_cnt    = 0;
            end
        end
        send_cmd0:begin//send cmd0
            if(|tx_cnt)begin
                next_SD_CS     = 1'b0;
                next_SD_DATAIN = data[tx_cnt-1];
            end
            else begin
                next_SD_CS     = 1'b0;
                next_SD_DATAIN = 1'b1;
                next_state     = wait_01;
            end
        end
        wait_01:begin//cmd00 resp. 0x01
            if(rx_valid)begin
                next_SD_CS     = 1'b1;
                next_SD_DATAIN = 1'b1;
                if(rx[47:40]==8'h01)begin
                    next_state = waitb;
                    next_cnt   = 1023;
                end
                else begin
                    next_state = idle;
                end
            end
            else begin
                next_SD_CS     = 1'b0;
                next_SD_DATAIN = 1'b1;
            end
        end
        waitb:begin//dummy
            next_SD_CS     = 1'b1;
            next_SD_DATAIN = 1'b1;
            if(|cnt)begin
                next_state = waitb;
            end
            else begin
                next_state  = send_cmd8;
                next_data   = `CMD8;
                next_tx_cnt = 48;
            end
        end
        send_cmd8:begin//send cmd8
            next_SD_CS     = 1'b0;
            if(|tx_cnt)begin
                next_SD_DATAIN = data[tx_cnt-1];
                next_state     = send_cmd8;
            end
            else begin
                next_state     = waita;
                next_SD_DATAIN = 1'b1;
            end
        end
        waita:begin//cmd8 resp. SD2.0,support 2.7-3.6V supply
            if(rx_valid)begin
                if(rx[19:16]==4'b0001)begin
                    next_state  = send_cmd55;
                    next_data   = `CMD55;
                    next_tx_cnt = 48;
                end
                else begin
                    next_state = init_fail;
                end
            end
            else begin
                next_SD_CS     = 1'b1;
                next_SD_DATAIN = 1'b1;
                next_state     = waita;
            end
        end
        send_cmd55:begin
            next_SD_CS = 1'b0;
            if(|tx_cnt)begin
                next_SD_DATAIN = data[tx_cnt-1];
                next_state     = send_cmd55;
                next_cnt       = tx_cnt==1 ? 127 : cnt;
            end
            else if(|cnt)begin
               next_SD_DATAIN  = 1'b1;
               if(rx_valid&rx[47:40]==8'h01)begin//CMD55 resp.
                   next_state  = send_acmd41;
                   next_data   = `ACMD41;
                   next_tx_cnt = 48;
                   next_cnt    = 0;
               end
               else begin
                   next_state = send_cmd55;
               end
            end
            else begin
                next_state = init_fail;
            end
        end
        send_acmd41:begin
            next_SD_CS = 1'b0;
            if(|tx_cnt)begin
                next_SD_DATAIN = data[tx_cnt-1];
                next_state     = send_acmd41;
                next_cnt       = tx_cnt==1 ? 127 : cnt;
            end
            else if(|cnt)begin
                next_SD_DATAIN = 1'b1;
                if(rx_valid&rx[47:40]==8'h00)begin
                    next_state = init_done;
                end
                else begin
                    next_state = send_acmd41;
                end
            end
            else begin
                next_state = init_fail;
            end
        end
        init_done:begin
            next_init_o    = 1'b1;
            next_SD_CS     = 1'b1;
            next_SD_DATAIN = 1'b1;
        end
        init_fail:begin
            next_init_o    = 1'b0;
            next_SD_CS     = 1'b1;
            next_SD_DATAIN = 1'b1;
            next_state     = waitb;//resend cmd8,cmd55,cmd41
        end
        default:begin
            next_state     = idle;//sverilog 'x
            next_init_o    = 1'b0;
            next_SD_CS     = 1'b1;
            next_SD_DATAIN = 1'b1;
        end
    endcase
end
assign SD_DATAOUT = SD_MISO;
assign SD_MOSI    = SD_DATAIN;
assign SD_CSn     = SD_CS;
assign init_ok    = init_o;
endmodule
