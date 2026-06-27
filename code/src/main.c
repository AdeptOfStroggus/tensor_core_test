#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "stdint.h"
#include "xil_io.h"
#include <stdlib.h>

#define ACCEL_BASE 0x41000000

#define T0_AR0 (ACCEL_BASE)
#define T0_AR1 (ACCEL_BASE + 0x04)
#define T0_BR0 (ACCEL_BASE + 0x08)
#define T0_BR1 (ACCEL_BASE + 0x0C)
#define T0_CR0 (ACCEL_BASE + 0x10)
#define T0_CR1 (ACCEL_BASE + 0x14)

#define T0_OR0 (ACCEL_BASE + 0x18)
#define T0_OR1 (ACCEL_BASE + 0x1C)

#define T0_CR (ACCEL_BASE + 0x20)
#define T0_SR (ACCEL_BASE + 0x24)

uint32_t packInt(uint16_t a, uint16_t b){
    return ((a & 0xFFFF) << 16) | (b & 0xFFFF);
}

int16_t unpackInt(uint32_t i, uint16_t* buf){
    buf[0] = (int16_t)(i & 0xFFFF0000) >> 16;
    buf[1] = (int16_t)(i & 0xFFFF);
}

typedef struct matrix_t{
    int16_t a00;
    int16_t a01;
    int16_t a10;
    int16_t a11;
} matrix_2x2_t;

typedef struct {
    matrix_2x2_t** blocks;
    uint8_t sizeX;
    uint8_t sizeY;
} matrix_blocks_t;

void MMAC(matrix_2x2_t* A, matrix_2x2_t* B, matrix_2x2_t* C, matrix_2x2_t* D, uint8_t ignore_c){
    uint32_t row_a0 = packInt(A->a00, A->a01);
    uint32_t row_a1 = packInt(A->a10, A->a11);
    uint32_t row_b0 = packInt(B->a00, B->a01);
    uint32_t row_b1 = packInt(B->a10, B->a11);
    uint32_t row_c0 = packInt(C->a00, C->a01);
    uint32_t row_c1 = packInt(C->a10, C->a11);


    Xil_Out32(T0_AR0, row_a0);
    Xil_Out32(T0_AR1, row_a1);
    Xil_Out32(T0_BR0, row_b0);
    Xil_Out32(T0_BR1, row_b1);

    if(ignore_c == 1) {
        Xil_Out32(T0_CR0, row_c0);
        Xil_Out32(T0_CR1, row_c1);
        Xil_Out32(T0_CR, 0x00000001);
    }
    else {
        Xil_Out32(T0_CR, 0x00000003);
    }

    

    uint32_t status = 0;
    
    while ((status & 0x00000001) == 0) {
        status = Xil_In32(T0_SR);
    }


    uint32_t row_o0 = Xil_In32(T0_OR0);
    uint32_t row_o1 = Xil_In32(T0_OR1);


    uint16_t buf[2] = {0,0};
    unpackInt(row_o0, buf);
    D->a00 = buf[0];
    D->a01 = buf[1];
    unpackInt(row_o1, buf);
    D->a10 = buf[0];
    D->a11 = buf[1];

}

uint8_t BlockMMUL(matrix_blocks_t* A, matrix_blocks_t* B, matrix_blocks_t* C){

    //Note - its supposed that memory for C is already allocated!

    if(A->sizeX == B->sizeY) {
        for(uint8_t i = 0; i < A->sizeY; i++)
        {
            for(uint8_t j = 0; j < B->sizeX; j++)
            {
                for(uint8_t k = 0; k < B->sizeY; k++)
                {
                    if(k == 0) {
                        MMAC(&A->blocks[i][k], &B->blocks[k][j], NULL, &C->blocks[i][j], 1);
                    }
                    else {
                        MMAC(&A->blocks[i][k], &B->blocks[k][j], &C->blocks[i][j], &C->blocks[i][j], 1);
                    }
                }
            }
        }
        return 0;
    }
    else {
        return 1; //Operation is not possible
    }
}


int main()
{
    init_platform();

    matrix_2x2_t A = {2, 3, -1, 4};
    matrix_2x2_t B = {5, 0, 2, -2};
    matrix_2x2_t C = {1, 1, 1, 1};
    matrix_2x2_t D = {0,0,0,0};

    MMAC(&A, &B, &C, &D, 0);

    print("Test1 completed");

    matrix_blocks_t AB;
    matrix_blocks_t BB;
    matrix_blocks_t CB;

    AB.blocks = calloc(16, sizeof(matrix_2x2_t*));
    BB.blocks = calloc(16, sizeof(matrix_2x2_t*));
    CB.blocks = calloc(16, sizeof(matrix_2x2_t*));
    for(int i = 0; i < 4; i++) {
        AB.blocks[i] = calloc(16, sizeof(matrix_2x2_t));
        BB.blocks[i] = calloc(16, sizeof(matrix_2x2_t));
        CB.blocks[i] = calloc(16, sizeof(matrix_2x2_t));
    }
    AB.sizeX = 16;
    AB.sizeY = 16;
    BB.sizeX = 16;
    BB.sizeY = 16;
    CB.sizeX = 16;
    CB.sizeY = 16;

    print("Memory allocated");
    for(int i = 0; i < 16; i++) {
        for (int j = 0; j < 16; j++){
            AB.blocks[i][j] = A;
        }
    }

     for(int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++){
            BB.blocks[i][j] = A;
        }
    }


    print("Memory Fiiled");
    BlockMMUL(&AB, &BB, &CB);

    print("Test2 completed");
    cleanup_platform();
    return 0;
}
