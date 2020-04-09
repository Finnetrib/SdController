/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */
#include <stdio.h>
#include "platform.h"
#include "ps7_init.h"
#include "xil_printf.h"
#include "xil_types.h"
#include "sleep.h"

int main()
{
    init_platform();
    ps7_post_config();

    /** Counter for duration operation */
    int32_t cntrDuration = 0x00;
    int32_t durationRead = 0x00;
    int32_t durationWrite = 0x00;
    int32_t durationErase = 0x00;

    /** Status of operation */
    int32_t status = 0x00;

    /** Sector address */
    uint32_t SectorAddress = 0x00;

    /** Data read */
    uint32_t DataR = 0x00;

    /** Counter for test data */
    uint32_t cntrData = 0x00;

    /** Max */
    uint32_t MaxErase = 0x01;
    uint32_t MaxWrite = 0x01;
    uint32_t MaxRead = 0x01;

    xil_printf("Sd card test loaded\n\r");

    /** Write */
    for (SectorAddress = 0; SectorAddress < 1048576; SectorAddress ++)
    {
		if ((SectorAddress % 1024) == 0)
		{
			xil_printf("Data write to %d sector \n\r", SectorAddress);
		}

		/** Set address */
		Xil_Out32(0x43c00008, SectorAddress);

		/** Set command */
		Xil_Out32(0x43c00004, 2);

		/** Write data to PL */
		for (int32_t i = 0; i < 1024; i++)
		{
			Xil_Out32(0x43c00014, cntrData);
			cntrData++;
		}

		/** Start */
		Xil_Out32(0x43c00000, 1);

		/** Wait end of operation */
		for (;;)
		{
			status = Xil_In32(0x43c0000c);
			if (status == 0x01 || status == 0x03)
			{
				if (status == 0x03)
				{
					xil_printf("Error in write \n\r");
				}
				break;
			}
			else
			{
				cntrDuration++;
				usleep(100);
			}
		}

		/** Duration operation */
		durationWrite += cntrDuration;

		if (cntrDuration > MaxWrite )
		{
			MaxWrite = cntrDuration;
		}

		cntrDuration = 0x00;

		/** Clear start */
		Xil_Out32(0x43c00000, 0);

		SectorAddress += 7;
	}

	cntrData = 0x00;

    /** Read */
	for (SectorAddress = 0; SectorAddress < 1048576; SectorAddress++)
	{
		if ((SectorAddress % 1024) == 0)
		{
			xil_printf("Data read from %d sector \n\r", SectorAddress);
		}

		/** Set address */
		Xil_Out32(0x43c00008, SectorAddress);

		/** Set command */
		Xil_Out32(0x43c00004, 1);

		/** Start */
		Xil_Out32(0x43c00000, 1);

		/** Wait end of operation */
		for (;;)
		{
			status = Xil_In32(0x43c0000c);
			if (status == 0x01 || status == 0x03)
			{
				 if (status == 0x03)
				{
					xil_printf("Error in read \n\r");
				}
				break;
			}
			else
			{
				cntrDuration++;
				usleep(100);
			}
		}

		/** Duration operation */
		durationRead += cntrDuration;

		 if (cntrDuration > MaxRead )
		 {
			 MaxRead = cntrDuration;
		 }

		cntrDuration = 0x00;

		/** Clear start */
		Xil_Out32(0x43c00000, 0);

		/** Read data from PL */
		for (int32_t i = 0; i < 1024; i++)
		{
			DataR = Xil_In32(0x43c0001c);
			if (DataR != cntrData)
			{
				xil_printf("Data corrupt! \n\r");
			}
			DataR = Xil_In32(0x43c00020);
			cntrData++;
		}

		SectorAddress += 7;
	}

	/** Erase */
	for (SectorAddress = 0; SectorAddress < 1048576; SectorAddress++)
	{
		if ((SectorAddress % 1024) == 0)
		{
			xil_printf("Data erase from %d sector \n\r", SectorAddress);
		}

		/** Set address */
		Xil_Out32(0x43c00008, SectorAddress);

		/** Set command */
		Xil_Out32(0x43c00004, 4);

		/** Start */
		Xil_Out32(0x43c00000, 1);

		/** Wait end of operation */
		for (;;)
		{
			status = Xil_In32(0x43c0000c);
			if (status == 0x01 || status == 0x03)
			{
				if (status == 0x03)
				{
					xil_printf("Error in write! \n\r");
				}
				break;
			}
			else
			{
				cntrDuration++;
				usleep(100);
			}
		}

		/** Duration operation */
		durationErase += cntrDuration;

		if (cntrDuration > MaxErase )
		{
			MaxErase = cntrDuration;
		}

		cntrDuration = 0x00;

		/** Clear start */
		Xil_Out32(0x43c00000, 0);

		SectorAddress += 7;
	}


    xil_printf("All duration write %x\n\r", durationWrite);
    xil_printf("All duration read %x\n\r", durationRead);
    xil_printf("All duration erase %x\n\r", durationErase);
    xil_printf("Write max %d\n\r", MaxWrite);
    xil_printf("Read max %d\n\r", MaxRead);
    xil_printf("Erase max %d\n\r", MaxErase);

    cleanup_platform();
    return 0;
}
