/*****************************************************************************************
 * HEIG-VD
 * Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
 * School of Business and Engineering in Canton de Vaud
 *****************************************************************************************
 * REDS Institute
 * Reconfigurable Embedded Digital Systems
 *****************************************************************************************
 *
 * File                 : avl_counter_test.h
 * Author               : Peter Podolec
 * Date                 : 17.02.2023
 *
 * Context              : CSF lab
 *
 *****************************************************************************************
 * Brief: Header file for Avalon component
 *
 *****************************************************************************************
 * Modifications :
 * Ver    Date        Engineer      Comments
 * 0.0    17.02.2023  PCC           Initial version.
 *
*****************************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <math.h>
#include <complex.h>
#include <stdbool.h>

// Base address
#define PHYS_ADDR   0xFF210000


// Adress offsets, avalon component register map
#define OFT_ID      0
#define OFT_CNT     1
#define OFT_CTRL    2
#define OFT_REG1    3
#define OFT_REG2    4
#define OFT_REG3    5
#define OFT_REG4    6

// Counter control values
#define CNT_RST     1
#define CNT_INC     2

#define NB_INC      10000

#define CONST_ID    0xD0D0C5F0

// Testcase prototypes
void test_id(void);
void test_counter(void);
void test_byteenable(void);
void test_read_write(void);

static int snd_fd;
static int rtsnd_fd;
static void *ioctrls;

int init_board()
{
    /* Ouverture du driver RTDM */
    rtsnd_fd = open("/dev/mem", O_RDWR);
    if (rtsnd_fd < 0) {
        perror("Opening /dev/mem");
        exit(EXIT_FAILURE);
    }

    snd_fd = rtsnd_fd;

    ioctrls = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, rtsnd_fd, PHYS_ADDR);
    if (ioctrls == MAP_FAILED) {
        perror("Mapping real-time sound file descriptor");
        exit(EXIT_FAILURE);
    }

    return 0;
}

int clean_board(void)
{
    close(rtsnd_fd);
    if (munmap(ioctrls, 4096) == -1) {
        perror("Unmapping");
        exit(EXIT_FAILURE);
    }
    return 0;
}

int main(int argc, char *argv[])
{
    if (argc < 1) {
        printf("Not enough arguments. Expected %s \n", argv[0]);
        return EXIT_SUCCESS;
    }

    if (init_board() != 0) {
        perror("Error at board initialization.");
        exit(EXIT_FAILURE);
    }

    printf("Init board successfull\n");

    test_id();
    test_counter();
    test_byteenable();
    test_read_write();

    clean_board();

    return EXIT_SUCCESS;
}

// Read the value at offset 0
void test_id(void)
{
    printf("\n\n------ ID test ------\n");

    uint32_t usr_id = *((uint32_t*)(ioctrls) + OFT_ID);

    if(usr_id != CONST_ID){
        printf("Error: Constant ID is not correct. Expected %x, got %x\n", CONST_ID, usr_id);
    }
}

// Test the counter
void test_counter(void)
{
    uint32_t counter_val = 0;
    printf("\n\n------ Counter test ------\n");

    // reset counter
    *((uint32_t*)(ioctrls) + OFT_CTRL) = CNT_RST;
    counter_val = *((uint32_t*)(ioctrls) + OFT_CNT);
    
    if(counter_val != 0){
        printf("Error: Counter reset failed. Expected 0, got %x\n", counter_val);
    }

    //some increments
    for(int i = 1; i <= NB_INC; i++)
    {
        *((uint32_t*)(ioctrls) + OFT_CTRL) = CNT_INC;
        counter_val = *((uint32_t*)(ioctrls) + OFT_CNT);
        if(counter_val != i){
            printf("Error: Counter value is not correct. Expected %d, got %x\n", i, counter_val);
        }
    }

    //reset counter
    *((uint32_t*)(ioctrls) + OFT_CTRL) = CNT_RST;
    counter_val = *((uint32_t*)(ioctrls) + OFT_CNT);
    
    if(counter_val != 0){
        printf("Error: Counter reset failed. Expected 0, got %x\n", counter_val);
    }

    //some bad value usage for control
    for(int i = 0; i < 1000; i += 5){
        *((uint32_t*)(ioctrls) + OFT_CTRL) = i;
        counter_val = *((uint32_t*)(ioctrls) + OFT_CNT);
        if(counter_val != 0){
            printf("Error: Counter value should not have changed with a bad control. Expected 0, got %x\n", counter_val);
        }
    }
}

// Test multiple byteenable configurations during Write
void test_byteenable(void)
{
    uint32_t reg1_val = 0;
    uint8_t offsets[4] = {OFT_REG1, OFT_REG2, OFT_REG3, OFT_REG4};
    printf("\n\n------ Byteenable test ------\n");

    // reset registers
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0;
        if(*((uint32_t*)(ioctrls) + offsets[i]) != 0){
            printf("Error: Register reset failed. Expected 0, got %x for register %d\n", *((uint32_t*)(ioctrls) + offsets[i]), i + 1);
        }
    }

    // byte enable of 0b0001
    for(int i = 0; i < 4; i++){
        *((uint8_t*)(ioctrls) + offsets[i]*4) = 0xFF;
        reg1_val = *((uint32_t*)(ioctrls) + offsets[i]);
        if(reg1_val != 0xFF){
            printf("Error BE: Register value is not correct. Expected %x, got %x for register %d\n", 0xFF, reg1_val, i + 1);
        } 
    }

    // reset registers
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0;
        if(*((uint32_t*)(ioctrls) + offsets[i]) != 0){
            printf("Error: Register reset failed. Expected 0, got %x for register %d\n", *((uint32_t*)(ioctrls) + offsets[i]), i + 1);
        }
    }

    // byte enable of 0b0010
    for(int i = 0; i < 4; i++){
        *((uint8_t*)(ioctrls) + offsets[i]*4 + 1) = 0xFF;
        reg1_val = *((uint32_t*)(ioctrls) + offsets[i]);
        if(reg1_val != 0xFF00){
            printf("Error BE: Register value is not correct. Expected %x, got %x for register %d\n", 0xFF00, reg1_val, i + 1);
        }
    }

    // reset registers
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0;
        if(*((uint32_t*)(ioctrls) + offsets[i]) != 0){
            printf("Error: Register reset failed. Expected 0, got %x for register %d\n", *((uint32_t*)(ioctrls) + offsets[i]), i + 1);
        }
    }

    // byte enable of 0b0100
    for(int i = 0; i < 4; i++){
        *((uint8_t*)(ioctrls) + offsets[i]*4 + 2) = 0xFF;
        reg1_val = *((uint32_t*)(ioctrls) + offsets[i]);
        if(reg1_val != 0xFF0000){
            printf("Error BE: Register value is not correct. Expected %x, got %x for register %d\n", 0xFF0000, reg1_val, i + 1);
        }
    }

    // reset registers
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0;
        if(*((uint32_t*)(ioctrls) + offsets[i]) != 0){
            printf("Error: Register reset failed. Expected 0, got %x for register %d\n", *((uint32_t*)(ioctrls) + offsets[i]), i + 1);
        }
    }

    // byte enable of 0b1000
    for(int i = 0; i < 4; i++){
        *((uint8_t* )(ioctrls) + offsets[i]*4 + 3) = 0xFF;
        reg1_val = *((uint32_t*)(ioctrls) + offsets[i]);
        if(reg1_val != 0xFF000000){
            printf("Error BE: Register value is not correct. Expected %x, got %x for register %d\n", 0xFF000000, reg1_val, i + 1);
        }
    }

    // reset registers
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0;
        if(*((uint32_t*)(ioctrls) + offsets[i]) != 0){
            printf("Error: Register reset failed. Expected 0, got %x for register %d\n", *((uint32_t*)(ioctrls) + offsets[i]), i + 1);
        }
    }

    // byte enable of 0b0011
    for(int i = 0; i < 4; i++){
        *((uint16_t*)(ioctrls) + offsets[i]*2) = 0xFFFF;
        reg1_val = *((uint32_t*)(ioctrls) + offsets[i]);
        if(reg1_val != 0xFFFF){
            printf("Error BE: Register value is not correct. Expected %x, got %x for register %d\n", 0xFFFF, reg1_val, i + 1);
        }
    }

    // reset registers
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0;
        if(*((uint32_t*)(ioctrls) + offsets[i]) != 0){
            printf("Error: Register reset failed. Expected 0, got %x for register %d\n", *((uint32_t*)(ioctrls) + offsets[i]), i + 1);
        }
    }

    // byte enable of 0b1100
    for(int i = 0; i < 4; i++){
        *((uint16_t*)(ioctrls) + offsets[i]*2 + 1) = 0xFFFF;
        reg1_val = *((uint32_t*)(ioctrls) + offsets[i]);
        if(reg1_val != 0xFFFF0000){
            printf("Error BE: Register value is not correct. Expected %x, got %x for register %d\n", 0xFFFF0000, reg1_val, i + 1);
        }
    }

    // reset registers
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0;
        if(*((uint32_t*)(ioctrls) + offsets[i]) != 0){
            printf("Error: Register reset failed. Expected 0, got %x for register %d\n", *((uint32_t*)(ioctrls) + offsets[i]), i + 1);
        }
    }

    // byte enable of 0b1111
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0xFFFFFFFF;
        reg1_val = *((uint32_t*)(ioctrls) + offsets[i]);
        if(reg1_val != 0xFFFFFFFF){
            printf("Error BE: Register value is not correct. Expected %x, got %x for register %d\n", 0xFFFFFFFF, reg1_val, i + 1);
        }
    }
}

// Test R/W registers
void test_read_write(void)
{
    uint8_t offsets[4] = {OFT_REG1, OFT_REG2, OFT_REG3, OFT_REG4};
    printf("\n\n------ Read/Write test ------\n");
    printf("some low values...\n");
    //reset registers
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0;
    }

    // some low values for reg1 and checking that there was no changes on other registers
    for(int i = 0; i < 100; i++){
        *((uint32_t*)(ioctrls) + offsets[0]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != i){
            printf("Error RW: Register value is not correct. Expected %d, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[0]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 3. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[1]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 3. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[2]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 3. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }

    //some low values for reg2 and checking that there was no changes on other registers
    for(int i = 0; i < 100; i++){
        *((uint32_t*)(ioctrls) + offsets[1]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != 99){
            printf("Error RW: Register value should not have changed with a write at address 4. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[1]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != i){
            printf("Error RW: Register value is not correct. Expected %d, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[1]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 4. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[2]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 4. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }

    //some low values for reg3 and checking that there was no changes on other registers
    for(int i = 0; i < 100; i++){
        *((uint32_t*)(ioctrls) + offsets[2]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != 99){
            printf("Error RW: Register value should not have changed with a write at address 5. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[1]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != 99){
            printf("Error RW: Register value should not have changed with a write at address 5. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[0]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != i){
            printf("Error RW: Register value is not correct. Expected %d, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[2]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 5. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }

    //some low values for reg4 and checking that there was no changes on other registers
    for(int i = 0; i < 100; i++){
        *((uint32_t*)(ioctrls) + offsets[3]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != 99){
            printf("Error RW: Register value should not have changed with a write at address 6. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[1]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != 99){
            printf("Error RW: Register value should not have changed with a write at address 6. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[0]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != 99){
            printf("Error RW: Register value should not have changed with a write at address 6. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[0]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != i){
            printf("Error RW: Register value is not correct. Expected %d, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }

    printf("some high values...\n");

    //reset registers
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0;
    }

    //some high values for reg1 and checking that there was no changes on other registers
    for(uint64_t i = 4294967195; i < 4294967195; i++){
        *((uint32_t*)(ioctrls) + offsets[0]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != i){
            printf("Error RW: Register value is not correct. Expected %Ld, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[0]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 3. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[1]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 3. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[2]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 3. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }

    //some high values for reg2 and checking that there was no changes on other registers
    for(uint64_t i = 4294967195; i < 4294967195; i++){
        *((uint32_t*)(ioctrls) + offsets[1]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != 4294967194){
            printf("Error RW: Register value should not have changed with a write at address 4. Expected %Ld, got %d for register %d\n", 4294967194, *((uint32_t*)(ioctrls) + offsets[1]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != i){
            printf("Error RW: Register value is not correct. Expected %Ld, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[1]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 4. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[2]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 4. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }

    //some high values for reg3 and checking that there was no changes on other registers
    for(uint64_t i = 4294967195; i < 4294967195; i++){
        *((uint32_t*)(ioctrls) + offsets[2]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != 4294967194){
            printf("Error RW: Register value should not have changed with a write at address 5. Expected %Ld, got %d for register %d\n", 4294967194, *((uint32_t*)(ioctrls) + offsets[1]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != 4294967194){
            printf("Error RW: Register value should not have changed with a write at address 5. Expected %Ld, got %d for register %d\n", 4294967194, *((uint32_t*)(ioctrls) + offsets[0]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != i){
            printf("Error RW: Register value is not correct. Expected %Ld, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[2]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 5. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }

    //some high values for reg4 and checking that there was no changes on other registers
    for(uint64_t i = 4294967195; i < 4294967195; i++){
        *((uint32_t*)(ioctrls) + offsets[3]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != 4294967194){
            printf("Error RW: Register value should not have changed with a write at address 6. Expected %Ld, got %d for register %d\n", 4294967194, *((uint32_t*)(ioctrls) + offsets[1]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != 4294967194){
            printf("Error RW: Register value should not have changed with a write at address 6. Expected %Ld, got %d for register %d\n", 4294967194, *((uint32_t*)(ioctrls) + offsets[0]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != 4294967194){
            printf("Error RW: Register value should not have changed with a write at address 6. Expected %Ld, got %d for register %d\n", 4294967194, *((uint32_t*)(ioctrls) + offsets[0]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != i){
            printf("Error RW: Register value is not correct. Expected %Ld, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }


    printf("some classic values...\n");
    //reset registers
    for(int i = 0; i < 4; i++){
        *((uint32_t*)(ioctrls) + offsets[i]) = 0;
    }

    //some standard values for reg1 and checking that there was no changes on other registers
    for(int i = 0; i < 1000000; i += 100){
        *((uint32_t*)(ioctrls) + offsets[0]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != i){
            printf("Error RW: Register value is not correct. Expected %d, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[0]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 3. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[1]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 3. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[2]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 3. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }

    //some standard values for reg2 and checking that there was no changes on other registers
    for(int i = 0; i < 1000000; i += 100){
        *((uint32_t*)(ioctrls) + offsets[1]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != 999900){
            printf("Error RW: Register value should not have changed with a write at address 4. Expected %d, got %d for register %d\n", 999900, *((uint32_t*)(ioctrls) + offsets[1]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != i){
            printf("Error RW: Register value is not correct. Expected %d, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[0]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 4. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[2]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 4. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }

    //some standard values for reg3 and checking that there was no changes on other registers
    for(int i = 0; i < 1000000; i += 100){
        *((uint32_t*)(ioctrls) + offsets[2]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != 999900){
            printf("Error RW: Register value should not have changed with a write at address 5. Expected %d, got %d for register %d\n", 999900, *((uint32_t*)(ioctrls) + offsets[1]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != 999900){
            printf("Error RW: Register value should not have changed with a write at address 5. Expected %d, got %d for register %d\n", 999900, *((uint32_t*)(ioctrls) + offsets[0]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != i){
            printf("Error RW: Register value is not correct. Expected %d, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[0]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != 0){
            printf("Error RW: Register value should not have changed with a write at address 5. Expected %d, got %d for register %d\n", 0, *((uint32_t*)(ioctrls) + offsets[3]), 4);
        }
    }

    //some standard values for reg4 and checking that there was no changes on other registers
    for(int i = 0; i < 1000000; i += 100){
        *((uint32_t*)(ioctrls) + offsets[3]) = i;
        if(*((uint32_t*)(ioctrls) + offsets[0]) != 999900){
            printf("Error RW: Register value should not have changed with a write at address 6. Expected %d, got %d for register %d\n", 999900, *((uint32_t*)(ioctrls) + offsets[1]), 1);
        }
        if(*((uint32_t*)(ioctrls) + offsets[1]) != 999900){
            printf("Error RW: Register value should not have changed with a write at address 6. Expected %d, got %d for register %d\n", 999900, *((uint32_t*)(ioctrls) + offsets[0]), 2);
        }
        if(*((uint32_t*)(ioctrls) + offsets[2]) != 999900){
            printf("Error RW: Register value should not have changed with a write at address 6. Expected %d, got %d for register %d\n", 999900, *((uint32_t*)(ioctrls) + offsets[0]), 3);
        }
        if(*((uint32_t*)(ioctrls) + offsets[3]) != i){
            printf("Error RW: Register value is not correct. Expected %d, got %d for register %d\n", i, *((uint32_t*)(ioctrls) + offsets[0]), 4);
        }
    }
}
