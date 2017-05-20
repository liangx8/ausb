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


void power_init(void)
{
  // default value
  // 设置USB设备是否自供电
  //REG0CN = 0;
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
  XBR1 =0x40;
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
// 对于中断， __using 好像没用
void usb_int(void)  __interrupt(8) __using(2) __naked{
  uint8_t cmint;
  uint8_t in1int;
  uint8_t out1int;
  // 主程序没有任何业务，因此不需要保存环境
  //__asm__ ("push psw");
  //__asm__ ("push acc");

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

  //__asm__ ("pop acc");
  //__asm__ ("pop psw");
  __asm__ ("reti \n"); //for naked function
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
}
