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
    SD_TOP DUT(
        .clk  (clk  ),
        .rst_n(rst_n)
    );
endmodule
