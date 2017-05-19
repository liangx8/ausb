#include <stdint.h>
#include <c8051f320.h>

// USB 寄存器定义

// USB registers
#define FADDR    0x00
#define POWER    0x01
#define IN1INT   0x02
#define OUT1INT  0x04
#define CMINT    0x06
#define IN1IE    0x07
#define OUT1IE   0x09
#define CMIE     0x0b
#define FRAMEL   0x0c
#define FRAMEH   0x0d
#define INDEX    0x0e
#define CLKREC   0x0f
#define E0CSR    0x11
#define EINCSRL  0x11
#define EINCSRH  0x12
#define EOUTCSRL 0x14
#define EOUTCSRH 0x15
#define E0CNT    0x16
#define EOUTCNTL 0x16
#define EOUTCNTH 0x17
#define FIFO0    0x20
#define FIFO1    0x21
#define FIFO2    0x22
#define FIFO3    0x23


// 引脚定义
#define PIN_BUTTON 5
#define BUTTON     P2_5
#define PIN_RED    2
#define RED_LED    P2_2
#define PIN_GREEN  3
#define GREEN_LED  P2_3
#define delay_5us for(uint8_t delay_tmp=0;delay_tmp<=10;delay_tmp++)
#define delay_50ms for(uint16_t delay_tmp=0;delay_tmp<50000;delay_tmp++)
// 变量定义
__bit usb_en;


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
  // io initialized
  P2MDIN  = (1 << PIN_RED) + (1 << PIN_GREEN) + (1 << PIN_BUTTON);
  P2MDOUT = 0xff-(1 << PIN_BUTTON);
  P2SKIP  = 0xff;
  P2 = 1 << PIN_BUTTON;
  XBR0 = 0;
  XBR1 =0x40;
}
void init_usb(void){
  // clock setting
  CLKMUL = 0x80;
  delay_5us;
  CLKMUL = 0xc0;
}
void wait_button(void){
  while(BUTTON);
  while(!BUTTON);
  delay_50ms;
}
void usb_write(uint8_t addr,uint8_t data){
  USB0ADR = addr;
  USB0DAT = data;
  while(USB0ADR & 0x80);
}
uint8_t usb_read(uint8_t addr){
  USB0ADR = addr | 0x80;
  while(USB0ADR & 0x80);
  return USB0DAT;
}
void usb_start(void){
  usb_write(POWER,8);
  usb_write(IN1IE,0x0f);
  usb_write(OUT1IE,0x0f);
  usb_write(CMIE,4);
  USB0XCN = 0b11000000;
  USB0XCN = 0b11100000;
  usb_write(CLKREC,0x80);
  usb_write(POWER,0);
}
void main(void){
  init();
  init_usb();

  // EUSB0 = 1
  EIE1 = 0b00000010;
  EA = 1;
  usb_en = 0;

  while(1){
	wait_button();
	usb_en = !usb_en;
	GREEN_LED = usb_en;
	if (usb_en){
	  // disable USB
	  USB0XCN =0;
	} else {
	  usb_start();
	}
  }
}

// 对于中断， __using 好像没用
void usb_int(void)  __interrupt(8) __using(2) __naked{
  uint8_t cmint;
  uint8_t in1int;
  uint8_t out1int;
  __asm__ ("push psw");
  __asm__ ("push acc");

  cmint = usb_read(CMINT);
  in1int = usb_read(IN1INT);
  out1int= usb_read(OUT1INT);

  __asm__ ("pop acc");
  __asm__ ("pop psw");
  __asm__ ("reti \n"); //for naked function
}
