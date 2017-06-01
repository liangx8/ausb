#include <stdint.h>
#include <C8051F320.h>
#include "usb_config.h"
#include "usb_desc.h"
#include "registers.h"
#include "usb_struct.h"
#include "usb_request.h"
#include "function.h"



#define MULRDY   5

// 引脚定义

#define LED1     P1_0
#define LED2     P1_1
#define LED3     P1_2
#define LED4     P3_0

//#define LED1  P2_2
//#define LED2  P2_3

#define DEV_DEFAULT     0

#define strprint(str) printstr( sizeof(str),str)

// 变量定义
DEVICE_STATUS    gDeviceStatus;
EP0_COMMAND      gEp0Command;


void init_uart(void)
{
  // 8 bit ignore stop, ignore 9th bit
  SCON0 = 0b00010000;
  
  // 115200 baudrates
  TH1   = 0xcc;
  //TL1   = 0xcc;
  TCON  = 0b01000000;
  TMOD  = 0b00100000;
  CKCON = 0b11111100;
  XBR0  = 0x01 ;
  //P0MDOUT = 0b00010000;
  //P0MDIN  = 0b00110000;
}
void power_init(void)
{
  // default value
  // 设置USB设备是否自供电
  //REG0CN = 0;
}
void init_io(void)
{
  // set led
  P3MDIN = 1;
  // set push-pull
  P3MDOUT  = 1;
  P1MDIN = 0b00000111;
  P1MDOUT  = 0b00000111;
  // All led off
  P1       = 0;
  P2MDIN   = 0xff;
  P2MDOUT  = 0b00001100;
  P0SKIP   = 0b11001111;
  P1SKIP   = 0xff;
  P2SKIP   = 0xff;
}
void init(void){
  // 时钟和电压
  PCA0MD &= 0b10111111;
  // 使用 12000000Hz
  // IFCN1:0=11 sysclk derived from internal oscillator divided by 1
  VDM0CN = 0b10000000;
  // 等待电压稳定
  OSCICN = 0b10000011;
  while(!(OSCICN & 0b01000000));
  XBR0 = 0;
  XBR1 = 0x40; // enable cross bar
}
void init_usb(void){
  // clock setting
  uint8_t delay=100;
  //OSCICN |= 0x03;
  CLKMUL = 0x80;
  while(--delay);
  CLKMUL = 0xc0;
  while(CLKMUL & (1 << MULRDY));
  CLKSEL = 0;
  //CLKSEL = 2;
}
void usb_start(void){
  UWRITE_BYTE(POWER,8);
  UWRITE_BYTE(IN1IE,0x0f);
  UWRITE_BYTE(OUT1IE,0x0f);
  UWRITE_BYTE(CMIE,4);
  //USB0XCN = 0b11000000;
  USB0XCN = 0b11100000;
  UWRITE_BYTE(CLKREC,0x80);
  UWRITE_BYTE(POWER,0);
  //mov		USB0XCN,#0
}
void debug(void);
void input_callback(uint8_t c)
{
	switch(c){
	case '1':
		usb_start();
		break;
	case '2':
		USB0XCN=0;
		break;
	case '0':
		EA=0;
		break;
	case '9':
		EA=1;
		break;
	case 'a': debug();
	printbuf(16,(uint8_t*)16);
	}
}
// for uart
void uart_poll(void)
{
	if(RI0){
		uint8_t b;
		RI0=0;
		b=SBUF0;
		SBUF0=b;
		while(!TI0);
		TI0=0;
		input_callback(b);
	}
	uart_cycle();
}
void main(void){
  uint16_t ts;

  init_io();
  init();
  init_usb();
  init_uart();
  init_display();
  
  LED1=1;
  LED2=0;
	LED3=1;
	LED4=1;  


  for(uint8_t i=0;i<40;i++){
	  WORD temp;
	  temp.c[1]=0;
	while(temp.i++){
		if (temp.c[1] ==0xff){
			LED3 = !LED3;
			LED2 = !LED2;
			break;
		}
	}
  }
	LED1=0;
	LED4=0;  

  //  usb_start();
  // EUSB0 = 1
  EIE1 = 0b00000010;
  EA = 1;
  while(1) {
	  uart_poll();
	  if(ts==0){
		LED2 = !LED2;
		LED3 = !LED3;
	  }
	  ts++;
  }
}
void usb_reset(void);
void usb_endpoint0(void);
void fifo_read(uint8_t, uint16_t, uint8_t *);
void fifo_write(uint8_t, uint16_t, uint8_t *);
// 对于中断， __using 好像没用
void usb_int(void)  __interrupt(8) __using(1) {
  uint8_t cmint;
  uint8_t in1int;
  uint8_t out1int;

/*
  __asm__ ("push psw");
  __asm__ ("push acc");
  __asm__ ("push dpl");
  __asm__ ("push dph");
  __asm__ ("push b");
  __asm__ ("setb rs1");
  __asm__ ("clr  rs0");
*/
 
  UREAD_BYTE(CMINT,cmint);
  UREAD_BYTE(IN1INT,in1int);
  UREAD_BYTE(OUT1INT,out1int);
  if(cmint & rbRSTINT){
	// usb reset event
	checkpoint(0x10);
	usb_reset();
  }
  if(in1int & rbEP0){
	// endpoint0 event
	checkpoint(0x11);
	usb_endpoint0();
  }
  if(in1int & rbIN1){
	// endpoint1 in
	checkpoint(0x12);
  }
  if(out1int & rbOUT2){
	  checkpoint(0x13);
	// endpoint2 out
  }
  //UWRITE_BYTE(E0CSR,rbDATAEND | rbINPRDY);
  checkpoint(0x99);
  /*
  __asm__ ("pop b");
  __asm__ ("pop dph");
  __asm__ ("pop dpl");
  __asm__ ("pop acc");
  __asm__ ("pop psw");
  __asm__ ("reti"); //for naked function
  */
}


void usb_reset(void)
{
  uint8_t i, bPower = 0;
  uint8_t * pDevStatus;

  // Reset device status structure to all zeros (undefined)
  pDevStatus = (uint8_t *)&gDeviceStatus;
  for (i=0;i<sizeof(DEVICE_STATUS);i++){
	*pDevStatus++ = 0x00;
  }
  //UWRITE_BYTE(POWER,0);
  //strprint(msg_usb_reset);
  // Set device state to default
  gDeviceStatus.bDevState = DEV_DEFAULT;
  UWRITE_BYTE(POWER,0x81);

}

void get_descriptor_request(void)
{
	
	switch(gEp0Command.wValue.c[1]){
		case DSC_DEVICE: // 1
		UWRITE_BYTE(E0CSR,rbSOPRDY);
		fifo_write(0,18,gDescriptor);
		UWRITE_BYTE(E0CSR,rbINPRDY);
		break;
		case DSC_CONFIG: // 2
		UWRITE_BYTE(E0CSR,rbSOPRDY);
		fifo_write(0,9,gDescriptorCfg1);
		//UWRITE_BYTE(E0CSR,rbDATAEND | rbINPRDY);
		UWRITE_BYTE(E0CSR,rbINPRDY);
		checkpoint(0x20);
		break;
		case DSC_QUALIFIER: // ignore qualifier descriptor
//		UWRITE_BYTE(E0CSR,rbSOPRDY);
//		fifo_write(0,10,gDescriptorQualifier);
//		UWRITE_BYTE(E0CSR,rbDATAEND | rbINPRDY);
		checkpoint(0x21);
		break;
	}
	
}
void set_address(void)
{
	//uint8_t r;
	UWRITE_BYTE(FADDR,gEp0Command.wValue.c[0]);
	UWRITE_BYTE(E0CSR,rbSOPRDY);
	//while(!(r & 0x80)) UREAD_BYTE(FADDR,r);
	//UWRITE_BYTE(E0CSR,rbSOPRDY | rbDATAEND);
}
void usb_endpoint0(void)
{
   uint8_t bCsr1;
   
   UWRITE_BYTE(INDEX, 0);                 // Target ep0
   UREAD_BYTE(E0CSR, bCsr1);
   printhex(bCsr1);
   if(bCsr1 & rbSUEND){
	 UWRITE_BYTE(E0CSR,rbSSUEND);
   }
   if (bCsr1 & rbSTSTL){                  // If last state requested a stall
                                          // Clear Sent Stall bit (STSTL)
      UWRITE_BYTE(E0CSR, 0);
   }

   // Handle incoming packet
   if (bCsr1 & rbOPRDY){
	   
		fifo_read(0,8,(uint8_t *)&gEp0Command);
		printbuf(8,(uint8_t*)&gEp0Command);

	 if(gEp0Command.bmRequestType & CMD_MASK_DIR){
		 // data in (device -> host)
		 switch(gEp0Command.bRequest){
			 case GET_STATUS:
			 checkpoint(0x31);break;
			 case GET_DESCRIPTOR:
			 get_descriptor_request();
			 checkpoint(0x32);
			 break;
			 case GET_CONFIGURATION:
			 checkpoint(0x33);break;
			 case GET_INTERFACE:
			 checkpoint(0x34);break;
			 case SYNCH_FRAME:
			 checkpoint(0x35);break;
			 default:
			 checkpoint(0x36);
			 
			 break;
			 // not support
		 }
		 
	 } else {
		 // data out (host -> device)
		 switch(gEp0Command.bRequest){
			 case SET_ADDRESS:
			 set_address();
			 checkpoint(0x41);break;
			 case SET_FEATURE:
			 checkpoint(0x42);break;
			 case CLEAR_FEATURE:
			 checkpoint(0x43);break;
			 case SET_CONFIGURATION:
			 checkpoint(0x44);break;
			 case SET_INTERFACE:
			 checkpoint(0x45);break;
			 case SET_DESCRIPTOR:
			 checkpoint(0x46);break;
			 default:
			 checkpoint(0x47);break;
		 }
	 }
	 //UWRITE_BYTE(E0CSR,rbSOPRDY);
   } else {
		UWRITE_BYTE(E0CSR,rbSOPRDY);
		fifo_write(0,0,0);
		UWRITE_BYTE(E0CSR,rbDATAEND | rbINPRDY);
	   checkpoint(0x50);
	   
   }
}


//
// Return Value : None
// Parameters   : 
// 1) BYTE bEp
// 2) UINT uNumBytes
// 3) BYTE * pData
//
// Read from the selected endpoint FIFO
//
//-----------------------------------------------------------------------------
void fifo_read(uint8_t bEp, uint16_t uNumBytes, uint8_t * pData)
{
   uint8_t TargetReg;
   uint16_t i;

   // If >0 bytes requested,
   if (uNumBytes) {
      TargetReg = FIFO_EP0 + bEp;         // Find address for target
                                          // endpoint FIFO

      USB0ADR = (TargetReg & 0x3F);       // Set address (mask out bits7-6)
      USB0ADR |= 0xC0;                    // Set auto-read and initiate
                                          // first read

      // Unload <NumBytes> from the selected FIFO
      for(i=0;i<uNumBytes-1;i++)
      {
         while(USB0ADR & 0x80);           // Wait for BUSY->'0' (data ready)
         pData[i] = USB0DAT;              // Copy data byte
      }


      while(USB0ADR & 0x80);              // Wait for BUSY->'0' (data ready)
      pData[i] = USB0DAT;                 // Copy data byte
      USB0ADR = 0;                        // Clear auto-read
   }
}

//-----------------------------------------------------------------------------
// FIFOWrite
//-----------------------------------------------------------------------------
//
// Return Value : None
// Parameters   : 
// 1) BYTE bEp
// 2) UINT uNumBytes
// 3) BYTE * pData
//
// Write to the selected endpoint FIFO
//
//-----------------------------------------------------------------------------
void fifo_write (uint8_t bEp, uint16_t uNumBytes, uint8_t * pData)
{
   uint8_t TargetReg;
   uint16_t i;

   // If >0 bytes requested,
   if (uNumBytes)
   {
      TargetReg = FIFO_EP0 + bEp;         // Find address for target
                                          // endpoint FIFO

      while(USB0ADR & 0x80);              // Wait for BUSY->'0'
                                          // (register available)
      USB0ADR = (TargetReg & 0x3F);       // Set address (mask out bits7-6)

      // Write <NumBytes> to the selected FIFO
      for(i=0;i<uNumBytes;i++)
      {
         USB0DAT = pData[i];
         while(USB0ADR & 0x80);           // Wait for BUSY->'0' (data ready)
      }
   }
}
