#include <stdint.h>
__code uint8_t gDescriptor[]={
   18,                        // bLength
   0x01,                      // bDescriptorType
   0x00, 0x02,                // bcdUSB (lsb first)
   0x03,                      // bDeviceClass
   0x00,                      // bDeviceSubClass
   0x00,                      // bDeviceProtocol
   64,                        // bMaxPacketSize0
   0x64, 0x89,                // idVendor (lsb first)
   0x03, 0x00,                // idProduct (lsb first)
   0x00, 0x00,                // bcdDevice (lsb first)
   0x00,                      // iManufacturer
   0x00,                      // iProduct
   0x00,                      // iSerialNumber
   0x01                      // bNumConfigurations
};
__code uint8_t gDescriptorCfg1[]={
   0x09,                      // Length
   0x02,                      // Type
   0x20, 0x00,                // TotalLength (lsb first)
   0x01,                      // NumInterfaces
   0x01,                      // bConfigurationValue
   0x00,                      // iConfiguration
   0x80,                      // bmAttributes (no remote wakeup)
   0x0F                       // MaxPower (*2mA)
};
__code uint8_t gDescriptorQualifier[]={
	0x0a,                     // Length
	0x06,                     // Type
	0x00, 0x02,               // bcdUSB
	0x00,                     // bDeviceClass
	0x00,                     // bDeviceSubClass
	0,                        // bDeviceProtocol
	64,                       // bMaxPacketSize
	1,                        // bNumConfigurations
	0                         // bReserved
};