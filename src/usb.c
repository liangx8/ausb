#include <stm32f1xx.h>
#include "common.h"
/*
    RM0008 page 167 table 29 USB
        As soon as the USB is enabled, these pins(DM/DP) are connected to the USB
        internal transceiver automatically.
        (还需要设置a11,a12的alternate function吗？)

*/

void usb_config(void)
{
    // USB clock enable
    BITBAND(RCC->APB1ENR)->bit[RCC_APB1ENR_USBEN_Pos]=1;
    // page 629 23.4.2 System and power-on reset
    // 这页的内容有描述上电如何设置USB,但是看不懂
    /*
    在系统和上电复位时，应用软件应执行的第一个操作
是为USB外设提供所有必需的时钟信号，然后取消断言
复位信号，以便能够访问其寄存器。 整个初始化序列是
以下描述。
    作为第一步，应用软件需要激活寄存器宏单元时钟和解除断言
使用由器件时钟提供的相关控制位的宏单元特定复位信号
管理逻辑
    之后，必须打开与USB收发器相关的设备的模拟部分
使用CNTR寄存器中的PDWN位，这需要特殊处理。 这个位是有意的
接通为端口收发器供电的内部参考电压。 这个电路有
定义的启动时间（数据表中指定的tSTARTUP），在此期间的行为
USB收发器未定义。 因此，在设置PDWN之后需要等待这一次
在移除USB部件上的复位条件之前（通过清除），CNTR寄存器中的位
CNTR寄存器中的FRES位）。 清除ISTR寄存器然后删除任何杂散
在启用任何其他宏单元操作之前挂起中断。
    在系统复位时，微控制器必须初始化所有需要的寄存器和数据包
缓冲区描述表，使USB外设能够正确生成中断和
数据传输。 必须根据以下内容初始化所有不特定于任何端点的寄存器
应用软件的需求（选择启用的中断，选择的数据包地址）
缓冲区等）。 然后，该过程将继续进行USB重置情况（另请参阅
段）。
    */
}
