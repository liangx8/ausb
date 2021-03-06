### USB CRC 算法

USB说明书中列举了两种生成多项式（generator polynomials）即除数多项式：一种是针对令牌包（tokens）的x5+x2+1，另一种是针对数据包的x16+x15+x2+1，由于余数要永远比除数小一阶的缘故，所以令牌（tokens）CRC是5bit组合，数据CRC是16bit组合。
两种CRC计算方法一样，步骤如下：

#### 步骤一：创建被除数：

D(x) = xdF(x) + xkL(x)；
其中D(x)是待创建的被除数多项式，d表示生成多项式即除数多项式的阶数（令牌包为5，数据包为16），F(x)为待检验的数据流（如令牌包检验中地址位和端口位组合的11位数据），是一个k-1阶多项式，k为数据流位数（如令牌包检验中k为11），L(x)表示系数为全1的d-1阶多项式（如令牌包检验中L(x)为x4+x3+x2+x+1）。
注意：F(x)必须是待检验的数据流由低位到高位顺序排列的（由USB低位到高位发送顺序决定）。如：对于addr 0x70, endpoint 4的CRC5，其F(x)流为00001110010，算的时候用该数据流左移5位即得0000111001000000然后加上xkL（x）即1111100000000000得到D(x)。而对于数据包0x00 0x01 0x02 0x03的CRC16，其F(x)流为00000000100000000100000011000000。

#### 步骤二：用生成多项式除“被除数”得到“余数”：

因为这里算法是一个简单的2模运算，不包含进位借位的，所以该除法可表示成简单的异或运算加位移运算。如对于CRC5的校验，D(x)是一个16bit二进制，生成多项式G(x)为x5+x2+1，可表示成100101，是一个6bit二进制。除法步骤如下：

1. D(x)的高6位与G(x)异或运算；得到一个新的D'(x)；

2. D'(x)左移一位，移掉MSB位，但右边不进位，即此时剩余15bit二进制，称为D''(x)；

3. D''(x)的高6位再与G(x)异或运算，然后再左移... ...重复前两步骤，直到D(x)的LSB 
位（最低位）也参与异或运算，此时得到一个4阶(d-1阶)多项式的余数R(x)。

#### 步骤三：对余数按位取反：

将得到的（d-1）bit二进制余数按位取反（即R(x)+L(x)运算），即可得到最终的CRC。

### 补充
在学习usb协议，一组usb上采到的数据，主机

	00000001 10010110 0100000 1000 11000
	sync pid(in) addr endp crc
	
接下来设备要发data包但不知道crc不知道怎么计算的，弄了好几天，到处查资料，搞得头晕脑胀的，最后终于用按博主说的方法得到了上面数据包正确的crc5，为方便其他人学习，举例验证计算过程如下

	01000001000 左移5位如下（addr&ednp）
	0100000100000000高5位加11111如下(有进位)
	0011100100000000与100101异或如下（100101与第一个1对齐）
	100101
	0111000
	100101
	0111010
	100101
	0111110
	100101
	0110110
	100101
	0100110
	100101
	000011000

得到结果11000（高位的0舍去，不足5位补0）
另一组数据0100000 1110 00110（addr endp crc）可以自己尝试验证
最后感谢博主分享，恩等我吧data的包发出去试试看主机有没有响应,以查看crc16按博主的方法计算有没有问题，
谢谢


C8051F320 USB

endpoint0 中断发生的情况
7      6      5     4     3       2     1      0
SSUEND SOPRDY SDSTL SUEND DATAEND STSTL INPRDY OPRDY

所有的控制传输必须以SETUP包开始，SETUP包类似于OUT包，

Endpoint0 IN Transactions
要求USB0传输数据给host的SETUP请求被收到时，1或者多个IN请求会被host发送出来。
   对于第一个IN传输，设备固件装载IN包到Endpoint0 FIFO,并且设置INPRDY位

1 数据包(OUT or SETUP) 已经收到并且loaded into ENDPOINT0 FIFO, OPRDY 位设置为1.
2 IN 数据包被成功从 Endpoint0 FIFO unload 并且传输到host, INPRDY 被硬件重置0
3 一次IN transaction 完成(this interrupt generated during the status stage of the transaction).
4 由于一次 protocal violation 导致的控制transaction 结束，硬件设置 STSTL ,
5 在软件设置DATAEND之前，一次控制传输结束，硬件设置 SUEND位1.

C程序，暂停开发
汇编程序
计算机可以认识设备.在windows CLEAR_FEATURE这一步不断重复。在LINUX下，会去到GET_REPORTER，暂时停止开发，
