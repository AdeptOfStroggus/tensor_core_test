`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2026 15:08:22
// Design Name: 
// Module Name: matMul2x2_int16
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


module matMul2x2_int16(
    input wire clk,
    input wire rst,

    input wire startCalc,
    input wire ignoreC,
    input wire signed [15:0] a00, a01, a10, a11,
    input wire signed [15:0] b00, b01, b10, b11,
    input wire signed [15:0] c00, c01, c10, c11,
    output reg signed [15:0] d00, d01, d10, d11,
    output reg valid
        
);

    reg isCalculating;
    reg [3:0] calcCounter;
    reg signed [15:0] a[0:1][0:1];
    reg signed [15:0] b[0:1][0:1];
    reg signed [15:0] c[0:1][0:1];
    wire signed [31:0] products [0:1][0:1][0:1];
    reg signed [33:0] dUnclipped[0:1][0:1];

    genvar i, j, k;

    localparam MULT_LATENCY = 3;
    localparam signed [15:0] MAX_VAL = 16'sh7FFF;
    localparam signed [15:0] MIN_VAL = 16'sh8000;

    generate
        for (i = 0; i < 2; i = i + 1) begin
            for (j = 0; j < 2; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    mult_gen_1  mult_gen_1_inst (
                        .CLK(clk),
                        .A(a[i][j]),
                        .B(b[j][k]),
                        .P(products[i][j][k])
                    );
                end
            end
        end
    endgenerate

    integer ia, ja, ka;
    always @(posedge clk ) begin
        if(rst == 1) begin
            for(ia = 0; ia < 2; ia = ia + 1) begin
                for(ja = 0; ja < 2; ja = ja + 1) begin
                    a[ia][ja] <= 0;
                    b[ia][ja] <= 0;
                    c[ia][ja] <= 0;
                    dUnclipped[ia][ja] <= 0;
                end 
            end
            isCalculating <= 0;
            calcCounter <= 0;
        end
        else begin
            if(startCalc == 1 && isCalculating == 0) begin
                isCalculating <= 1;
                a[0][0] <= a00;
                a[0][1] <= a01;
                a[1][0] <= a10;
                a[1][1] <= a11;

                b[0][0] <= b00;
                b[0][1] <= b01;
                b[1][0] <= b10;
                b[1][1] <= b11;

                if(ignoreC == 0) begin
                    c[0][0] <= c00;
                    c[0][1] <= c01;
                    c[1][0] <= c10;
                    c[1][1] <= c11;
                end
                else begin
                    c[0][0] <= 0;
                    c[0][1] <= 0;
                    c[1][0] <= 0;
                    c[1][1] <= 0;
                end
                calcCounter <= 0;
                valid <= 0;
            end
            else begin
                if(calcCounter < MULT_LATENCY + 1) begin
                    calcCounter <= calcCounter + 1;
                end 
                if(calcCounter == MULT_LATENCY + 1) begin
                    dUnclipped[0][0] <= products[0][0][0] + products[0][1][0] + c[0][0];
                    dUnclipped[0][1] <= products[0][0][1] + products[0][1][1] + c[0][1];
                    dUnclipped[1][0] <= products[1][0][0] + products[1][1][0] + c[1][0];
                    dUnclipped[1][1] <= products[1][0][1] + products[1][1][1] + c[1][1];
                    calcCounter <= calcCounter + 1;
                end
                else begin
                    valid <= 1;
                    isCalculating <= 0;

                    if(dUnclipped[0][0] > MAX_VAL) begin
                        d00 <= MAX_VAL;
                    end
                    else if(dUnclipped[0][0] < MIN_VAL) begin
                        d00 <= MIN_VAL;
                    end
                    else begin
                        d00 <= dUnclipped[0][0][15:0];
                    end

                    if(dUnclipped[0][1] > MAX_VAL) begin
                        d01 <= MAX_VAL;
                    end
                    else if(dUnclipped[0][1] < MIN_VAL) begin
                        d01 <= MIN_VAL;
                    end
                    else begin
                        d01 <= dUnclipped[0][1][15:0];
                    end


                    if(dUnclipped[1][0] > MAX_VAL) begin
                        d10 <= MAX_VAL;
                    end
                    else if(dUnclipped[1][0] < MIN_VAL) begin
                        d10 <= MIN_VAL;
                    end
                    else begin
                        d10 <= dUnclipped[1][0][15:0];
                    end


                    if(dUnclipped[1][1] > MAX_VAL) begin
                        d11 <= MAX_VAL;
                    end
                    else if(dUnclipped[1][1] < MIN_VAL) begin
                        d11 <= MIN_VAL;
                    end
                    else begin
                        d11 <= dUnclipped[1][1][15:0];
                    end


                end

                
                
            end
        end
    end


endmodule
