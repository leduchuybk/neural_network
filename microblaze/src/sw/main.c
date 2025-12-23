#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xuartlite_l.h"

#include "dataValues.h"

#include "xaxidma.h"
#include "xparameters.h"

#define MNIST_BASEADDR 0x44A00000

XAxiDma myDma;

void end_simulation() {
    XUartLite_SendByte(0x40600000, 0x04);
}

void main()
{

	init_platform();

	u32 status;
	int detectDigit;
	print("Run demo\n");
	// Initialize DMA
	XAxiDma_Config *myDmaConfig;
	myDmaConfig = XAxiDma_LookupConfig(XPAR_AXI_DMA_0_BASEADDR);
	status = XAxiDma_CfgInitialize(&myDma, myDmaConfig);
	if(status != XST_SUCCESS){
		print("DMA failed\n");
		end_simulation();
	}
	// Create a DMA transaction from MM to Stream
	status = XAxiDma_SimpleTransfer(&myDma, (u32)dataValues,28*28*4,XAXIDMA_DMA_TO_DEVICE);
	if(status != XST_SUCCESS){
		print("DMA transaction failed\n");
		end_simulation();
	}
	while (!Xil_In32(MNIST_BASEADDR+0x18));
	detectDigit = Xil_In32(MNIST_BASEADDR+0x08); //read value
	printf("Detect value: %d ", detectDigit);
	if (detectDigit != result) {
		print("Wrong");
	} else {
		print("True");
	}
	end_simulation();
}
