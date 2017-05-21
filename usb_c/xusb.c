#include <stdint.h>
#include <C8051F320.h>
#include "usb_config.h"
#include "usb_desc.h"
#include "registers.h"
#include "usb_struct.h"
#define MULRDY   5

// 引脚定义
#define LED1     P3_0
#define LED2     P1_0
#define LED3     P1_1
#define LED4     P1_2




#define DEV_DEFAULT     0

// 变量定义
DEVICE_STATUS    gDeviceStatus;
EP0_COMMAND      gEp0Command;

void power_init(void)
{
  // default value
  // 设置USB设备是否自供电
  //REG0CN = 0;
}
void port_init(void)
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
}
void init(void){
  EA=0;
  // 时钟和电压
  PCA0MD &= 0b10111111;
  // 使用 12000000Hz
  // IFCN1:0=11 sysclk derived from internal oscillator divided by 1
  VDM0CN = 0b10000000;
  // 等待电压稳定
  OSCICN = 0b10000011;
  while(!(OSCICN & 0b01000000));
  XBR0 = 0;
  XBR1 =0x40; // enable cross bar
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
  CLKSEL = 2;
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
}
void main(void){
  init();
  init_usb();



  usb_start();
  // EUSB0 = 1
  EIE1 = 0b00000010;
  EA = 1;
  while(1);
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
  // Set device state to default
  gDeviceStatus.bDevState = DEV_DEFAULT;
}
void usb_endpoint0(void)
{
   uint8_t bCsr1, uTxBytes;

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
