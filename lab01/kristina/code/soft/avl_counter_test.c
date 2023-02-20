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
    printf("Should be $YOUR_CONSTANT$ : %x\n", usr_id);
}

// Test the counter
void test_counter(void)
{
    uint32_t counter_val = 0;
    printf("\n\n------ Counter test ------\n");

    // reset counter
    printf("Reseting counter\n");
    *((uint32_t*)(ioctrls) + OFT_CTRL) = CNT_RST;
    counter_val = *((uint32_t*)(ioctrls) + OFT_CNT);
    printf("Counter value: %x\n", counter_val);

    printf("Incrementing counter %d times\n", NB_INC);
    for(int i = 1; i <= NB_INC; i++)
    {
        *((uint32_t*)(ioctrls) + OFT_CTRL) = CNT_INC;
        counter_val = *((uint32_t*)(ioctrls) + OFT_CNT);
        printf("Counter value: %x\n", counter_val);
    }
}

// Test multiple byteenable configurations during Write
void test_byteenable(void)
{
    uint32_t reg1_val = 0;
    printf("\n\n------ Byteenable test ------\n");

    // reset register
    printf("Reseting register 1\n");
    *((uint32_t*)(ioctrls) + OFT_REG1) = 0;
    reg1_val = *((uint32_t*)(ioctrls) + OFT_REG1);
    printf("Register 1 value: %x\n", reg1_val);

    // byteenable = 0b0001
    printf("Writing 0xCE with byteenable = 0b0001\n");
    *((uint8_t*)(ioctrls) + OFT_REG1*4) = 0xCE;
    reg1_val = *((uint32_t*)(ioctrls) + OFT_REG1);
    printf("Register 1 value: %x\n", reg1_val);

    // byteenable = 0b0010
    printf("Writing 0xFA with byteenable = 0b0010\n");
    *((uint8_t*)(ioctrls) + OFT_REG1*4 + 1) = 0xFA;
    reg1_val = *((uint32_t*)(ioctrls) + OFT_REG1);
    printf("Register 1 value: %x\n", reg1_val);

    // byteenable = 0b0100
    printf("Writing 0xFA with byteenable = 0b0100\n");
    *((uint8_t*)(ioctrls) + OFT_REG1*4 + 2) = 0xCE;
    reg1_val = *((uint32_t*)(ioctrls) + OFT_REG1);
    printf("Register 1 value: %x\n", reg1_val);

    // byteenable = 0b1000
    printf("Writing 0xFA with byteenable = 0b1000\n");
    *((uint8_t*)(ioctrls) + OFT_REG1*4 + 3) = 0xFA;
    reg1_val = *((uint32_t*)(ioctrls) + OFT_REG1);
    printf("Register 1 value: %x\n", reg1_val);

    // byteenable = 0b0011
    printf("Writing 0xCAFE with byteenable = 0b0011\n");
    *((uint16_t*)(ioctrls) + OFT_REG1*2) = 0xCAFE;
    reg1_val = *((uint32_t*)(ioctrls) + OFT_REG1);
    printf("Register 1 value: %x\n", reg1_val);

    // byteenable = 0b1100
    printf("Writing 0xCAFE with byteenable = 0b1100\n");
    *((uint16_t*)(ioctrls) + OFT_REG1*2 + 1) = 0xCAFE;
    reg1_val = *((uint32_t*)(ioctrls) + OFT_REG1);
    printf("Register 1 value: %x\n", reg1_val);
}

// Test R/W registers
void test_read_write(void)
{
    printf("\n\n------ Read/Write test ------\n");

    /* YOUR READ/WRITE TESTS*/
}
