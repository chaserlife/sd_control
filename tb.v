`timescale 1ns/100ps
module tb;
    reg clk;
    initial begin
        clk = 0;
        forever begin
            #25 clk = ~clk;
        end
    end
    initial begin
        #1ms;
        $finish;
    end
    reg rst_n;
    initial begin
        `include "stimulus.v"
    end
    wire[3:0] state = tb.DUT.sd_initial.state;
    SD_TOP DUT(
         .clk       (clk        )
        ,.rst_n     (rst_n      )
        ,.SD_CLK    (SD_CLK     )
        ,.SD_DATAIN (SD_DATAIN  )
        ,.SD_DATAOUT(SD_DATAOUT )
    );

    SD SD(
         .rst_n(rst_n)
        ,.SD_CLK(SD_CLK)
        ,.SD_IN (SD_DATAIN  )
        ,.SD_OUT(SD_DATAOUT )
        ,.state_r(state)
    );
endmodule
