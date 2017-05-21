#include <stdint.h>
#include <C8051F320.h>
#include "usb_config.h"
#include "usb_desc.h"
#include "registers.h"
#include "usb_struct.h"
#include "uart_message.h"
#define MULRDY   5

// 引脚定义

//#define LED1     P1_0
//#define LED2     P1_1
#define LED3     P1_2
#define LED4     P3_0

#define LED1  P2_2
#define LED2  P2_3

#define DEV_DEFAULT     0

#define strprint(str) printstr( sizeof(str),str)

// 变量定义
DEVICE_STATUS    gDeviceStatus;
EP0_COMMAND      gEp0Command;

__code const char hex_table[]={'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'};

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
  P0MDOUT = 0b00010000;
  P0MDIN  = 0b00110000;
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
  //P3MDIN = 1;
  // set push-pull
  P3MDOUT  = 1;
  //P1MDIN = 0b00000111;
  P1MDOUT  = 0b00000111;
  // All led off
  LED1     = 0;
  P1       = 0b00000111;
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
  OSCICN |= 0x03;
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
  USB0XCN = 0b11000000;
  USB0XCN = 0b11100000;
  UWRITE_BYTE(CLKREC,0x80);
  UWRITE_BYTE(POWER,0);
  //mov		USB0XCN,#0
}
void fdcr(void)
{
	SBUF0='\n';
	while(!TI0);
	TI0=0;
	SBUF0='\r';
	while(!TI0);
	TI0=0;
}
void printstr(uint8_t len,__code char *str)
{
	uint8_t i;
	fdcr();
	for(i=0;i<len;i++){
		SBUF0=str[i];
		while(!TI0);
		TI0=0;
	}
}
void printbuf(uint8_t len,uint8_t *buf)
{
	uint8_t i;
	fdcr();
	for(i=0;i<len;i++){
		uint8_t b=buf[i] >> 4;
		if (i>0){
			SBUF0 = ' ';
			while(!TI0);
			TI0=0;
		}
		b = b & 0x0f;
		SBUF0 = hex_table[b];
		while(!TI0);
		TI0=0;
		b = buf[i] & 0x0f;
		SBUF0 = hex_table[b];
		while(!TI0);
		TI0=0;
	}
}
void input_callback(uint8_t c)
{
	switch(c){
		case '1':
		printstr(sizeof(msg_usb_start),msg_usb_start);
		usb_start();
		break;
		case '2':
		printstr(sizeof(msg_usb_stop),msg_usb_stop);
		USB0XCN=0;
		break;
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
}
void main(void){
  uint16_t temp=60000;
  init_io();
  init();
  init_usb();
  init_uart();
  
  LED1 =0;
  LED2 =0;

  //  usb_start();
  // EUSB0 = 1
  EIE1 = 0b00000010;
  EA = 1;
  LED1=1;
  LED2=1;
  while(1) uart_poll();
}
void usb_reset(void);
void usb_endpoint0(void);
void fifo_read(uint8_t, uint16_t, uint8_t *);
void fifo_write(uint8_t, uint16_t, uint8_t *);
// 对于中断， __using 好像没用
void usb_int(void)  __interrupt(8) __using(2) __naked{
  uint8_t cmint;
  uint8_t in1int;
  uint8_t out1int;
  __asm__ ("push psw");
  __asm__ ("setb rs1");
  __asm__ ("clr  rs0");
  __asm__ ("push acc");
  __asm__ ("push dpl");
  __asm__ ("push dph");

  UREAD_BYTE(CMINT,cmint);
  UREAD_BYTE(IN1INT,in1int);
  UREAD_BYTE(OUT1INT,out1int);
  if(cmint & rbRSTINT){
	// usb reset event
	usb_reset();
  }
  if(in1int & rbEP0){
	// endpoint0 event
	usb_endpoint0();
  }
  if(in1int & rbIN1){
	// endpoint1 in
  }
  if(out1int & rbOUT2){
	// endpoint2 out
  }
  __asm__ ("push dph");
  __asm__ ("push dpl");
  __asm__ ("pop acc");
  __asm__ ("pop psw");
  __asm__ ("reti"); //for naked function
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
  UWRITE_BYTE(POWER,0);
  strprint(msg_usb_reset);
  // Set device state to default
  gDeviceStatus.bDevState = DEV_DEFAULT;
}
void usb_endpoint0(void)
{
   uint8_t bCsr1, uTxBytes;
   strprint(msg_usb_endpoint0);
   UWRITE_BYTE(INDEX, 0);                 // Target ep0
   UREAD_BYTE(E0CSR, bCsr1);
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
