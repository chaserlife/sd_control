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
        #10ms;
        $finish;
    end
    reg rst_n;
    initial begin
        `include "stimulus.v"
    end
    wire[3:0] state = !tb.DUT.init_o          ? tb.DUT.sd_initial.state :
                      !tb.DUT.read_ok         ? tb.DUT.sd_read.state :
                      !tb.DUT.write_ok        ? tb.DUT.sd_write.state :
                      0;
    SD_TOP DUT(
         .clk       (clk        )
        ,.rst_n     (rst_n      )
        ,.SD_CK     (SD_CK      )
        ,.SD_MOSI   (SD_MOSI    )
        ,.SD_MISO   (SD_MISO    )
    );

    SD SD(
         .rst_n(rst_n   )
        ,.SD_CLK(SD_CK  )
        ,.SD_IN (SD_MOSI)
        ,.SD_OUT(SD_MISO)
    );
endmodule
