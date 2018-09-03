module SD(
    input      rst_n,
    input      SD_CLK,
    input      SD_IN,
    output     SD_OUT
    );
    reg       SD_OUT,next_SD_OUT;
    reg[5:0]  tx_cnt,next_tx_cnt;
    reg[5:0]  state,next_state;
    reg[5:0]  cmp,next_cmp;
    reg[47:0] data,next_data;
    parameter idle        = 0;
    parameter send_cmd0_r = 1;
    parameter send_wait   = 2;

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
wire[5:0] state_r = tb.DUT.sd_initial.state;
    always@(negedge SD_CLK or negedge rst_n)begin
        if(!rst_n)begin
            SD_OUT <= 1'b1;
            tx_cnt <= 0;
            state  <= idle;
            cmp    <= 0;
            data   <= 0;
        end
        else begin
            SD_OUT <= next_SD_OUT;
            tx_cnt <= next_tx_cnt;
            state  <= next_state;
            cmp    <= next_cmp;
            data   <= next_data;
        end
    end
    always@(*)begin
        next_SD_OUT = SD_OUT;
        next_tx_cnt = tx_cnt - |tx_cnt;
        next_cmp    = cmp;
        next_data   = data;
        case(state)
            idle:begin
                if(state_r==4'b0010)begin
                    next_state  = send_cmd0_r;
                    next_tx_cnt = 48;
                    next_data   = `DATA_R1_CMD0;
                    next_cmp    = state_r;
                    next_SD_OUT = 1;
                end
                else if(state_r==waita)begin
                    next_state  = send_cmd0_r;
                    next_tx_cnt = 48;
                    next_data   = `DATA_R7_CMD8;
                    next_cmp    = state_r;
                    next_SD_OUT = 1;
                end
                else if(state_r==send_cmd55&(|tb.DUT.sd_initial.cnt))begin
                    next_state  = send_cmd0_r;
                    next_tx_cnt = 48;
                    next_data   = `DATA_R1_CMD55;
                    next_cmp    = state_r;
                    next_SD_OUT = 1;                  
                end
                else if(state_r==send_acmd41&(|tb.DUT.sd_initial.cnt))begin
                    next_state  = send_cmd0_r;
                    next_tx_cnt = 48;
                    next_data   = `DATA_R1_ACMD41;
                    next_cmp    = state_r;
                    next_SD_OUT = 1;                  
                end
                else begin
                    next_state = idle;
                end
            end
            send_cmd0_r:begin
                if(|tx_cnt)begin
                    next_SD_OUT = data[tx_cnt-1];
                end
                else begin
                    SD_OUT     = 1'b1;
                    next_state = send_wait;
                end
            end
            send_wait:begin
                if(cmp!==state_r)begin
                    next_state = idle;
                end
            end
        endcase
    end
    always@(*)begin
         if(tb.DUT.sd_initial.init_o)begin
             #0.1 $display("################SD Card initial done!######################");
         end
    end
endmodule
