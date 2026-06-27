`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2026 15:48:45
// Design Name: 
// Module Name: matmul2x2_int16_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module matmul2x2_int16_tb(

    );

    reg clk;
    reg rst;

    reg startCalc;
    reg ignoreC;
    reg signed [15:0] a00, a01, a10, a11;
    reg signed [15:0] b00, b01, b10, b11;
    reg signed [15:0] c00, c01, c10, c11;
    wire signed [15:0] d00, d01, d10, d11;
    wire valid;

    matMul2x2_int16 uut(
        .clk(clk),
        .rst(rst),
        .startCalc(startCalc),
        .ignoreC(ignoreC),
        .a00(a00),
        .a01(a01),
        .a10(a10),
        .a11(a11),
        .b00(b00),
        .b01(b01),
        .b10(b10),
        .b11(b11),
        .c00(c00),
        .c01(c01),
        .c10(c10),
        .c11(c11),
        .d00(d00),
        .d01(d01),
        .d10(d10),
        .d11(d11),
        .valid(valid)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1;
        rst = 1; //reset active 
        startCalc = 0;
        #20 rst = 0; //reset low

        
        #5 //small delay after reset, otherwise it doesnt work :)

        begin //test 1
            ignoreC = 0;

            a00 = 1;
            a01 = 2;
            a10 = 3;
            a11 = 4;

            b00 = 4;
            b01 = 3;
            b10 = 2;
            b11 = 1;
            
            c00 = 5;
            c01 = 6;
            c10 = 7;
            c11 = 8;

        end

        #5 startCalc = 1; //start calc 1
        #5 startCalc = 0; 

        #100 //wait for calc 1 
        
        begin
            ignoreC = 0;

            a00 = 1;
            a01 = 2;
            a10 = 3;
            a11 = 4;

            b00 = -4;
            b01 = -3;
            b10 = -2;
            b11 = -1;
            
            c00 = -5;
            c01 = -6;
            c10 = -7;
            c11 = -8;

            
        end  
        
        #5 startCalc = 1; //start calc2
        #5 startCalc = 0;

        #100 //wait for calc2


        ignoreC = 1; //test 3

        #5 startCalc = 1;
        #5 startCalc = 0;

        #100

        begin
            ignoreC = 0;

            a00 = 1;
            a01 = 2;
            a10 = 3;
            a11 = 4;

            b00 = 32767;
            b01 = 1;
            b10 = 1;
            b11 = 32767;
            
            c00 = 0;
            c01 = 0;
            c10 = 0;
            c11 = 0;
        end //test4

        #5 startCalc = 1;
        #5 startCalc = 0;


        #100 $finish();

    end

endmodule
