module sd_initial(
    input           rst_n,
    input           SD_CLK,
    input           SD_DATAOUT,

    output reg      SD_CS,
    output reg      SD_DATAIN,
    output reg      init_o,
    output reg[3:0] state
    output reg[47:0] rx
);

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

//receive sd data
always@(posedge SD_CLK)begin
   rx[47:0]    <= {rx[46:0],SD_DATAOUT};
end
reg en;//enalbe signal to start receive data
reg aa;//counter for reveive 48 data
//SD_OUT:---|___________________
//          |
//         start
//en    :___|---------------

always@(posedge SD_CLK or negedge rst_n)begin
    if(!en)begin
        en <= 1'b0;
    end
    else if(!SD_DATAOUT&!en)begin
        rx_valid <= 1'b0;
        en       <= 1'b1;
    end
    else if(en)begin
        if(aa<47)begin
            aa <= aa + 1'b1;
            rx_valid <= 1'b0;
        end
        else begin
            aa <= 0;
            en <= 1'b0;
            rx_valid <= 1'b1;
        end
    end
    else begin
        en       <= 1'b0;
        aa       <= 0;
        rx_valid <= 1'b0;
    end
end

//rst_n  :____|----------------------------------------
//counter:____|-------------------------------------|_____
//              counter 0->1024
//reset  :------------------------------------------|__________
//SD_CS  :----|_________________|--------------------|____
always@(negedge SD_CLK or negedge rst_n)begin
    if(!rst_n)begin
        counter <= 0;
        reset   <= 1'b1;
    end
    else if(counter <= 10'd1023)begin
        count <= counter + 1;
        reset <= 1'b1;
    end
    else begin
        reset <= 1'b0;
    end
end
always@(negedge SD_CLK or negedge rst_n)begin
    if(!rst_n)begin
        init_o     <= 1'b0;
        state      <= idle;
        SD_DATA_IN <= 1'b1;
    end
    else begin
        case(state)
            idle:begin
                if(reset)begin
                    init_o     <= 1'b0;
                    state      <= idle;
                    SD_DATA_IN <= 1'b1;
                    SD_CS      <= count < 512 ? 1'b0 : 1'b1;
                end
                else begin
                    init_o    <= 1'b0;
                    CMD0      <= {8'h40,8'h00,8'h00,8'h00,8'h00,8'h95};//SEND CMD0
                    SD_CS     <= 1'b1;
                    SD_DATAIN <= 1'b1;
                    state     <= send_cmd0;
                    cnt       <= 0;
                end
            end
            send_cmd0:begin
                SD_CS <= 1'b0;
                if(CMD0!=48'd0)begin
                    SD_DATAIN <= CMD[47];
                    CMD0      <= {CMD0[46:0],1'b0};
                end
                else begin
                    SD_DATAIN <= 1'b1;
                    state     <= wait_01;
                end
            end
            wait_01:begin
                SD_DATAIN <= 1'b1;
                if(rx_valid&rx[47:40]==8'h01)begin
                    SD_CS     <= 1'b1;
                    state     <= waitb;
                end
                else if(rx_valid&rx[47:40]!==8'h01)begin
                    SD_CS     <= 1'b1;
                    state     <= idle;
                end
            end
        endcase
    end
end


endmodule
