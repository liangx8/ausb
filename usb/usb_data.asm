.include "usb.h"

.area HOME (CODE)
descriptor:
.db   18                        ; bLength
.db   0x01                      ; bDescriptorType
.db   0x10, 0x01                ; bcdUSB (lsb first)
.db   0x00                      ; bDeviceClass
.db   0x00                      ; bDeviceSubClass
.db   0x00                      ; bDeviceProtocol
.db   64                        ; bMaxPacketSize0
.db   0x89, 0x19                ; idVendor (lsb first)
.db   0x04, 0x06                ; idProduct (lsb first)
.db   0x00, 0x00                ; bcdDevice (lsb first)
.db   0x01                      ; iManufacturer
.db   0x02                      ; iProduct
.db   0x03                      ; iSerialNumber
.db   0x01                      ; bNumConfigurations

descriptor_cfg:

.db   0x09                      ; Length
.db   0x02                      ; Type
.db   0x29, 0x00                ; TotalLength (lsb first) 9 + 9 +9 +7 +7
.db   0x01                      ; NumInterfaces
.db   0x01                      ; bConfigurationValue
.db   0x04                      ; iConfiguration
.db   0x80                      ; bmAttributes (no remote wakeup)
.db   0x20                      ; MaxPower (*2mA)

   ; Begin Descriptor: Interface0, Alternate0
.db   0x09                      ; bLength
.db   0x04                      ; bDescriptorType
.db   0x00                      ; bInterfaceNumber
.db   0x00                      ; bAlternateSetting
.db   0x01                      ; bNumEndpoints
.db   0x03                      ; bInterfaceClass
.db   0x00                      ; bInterfaceSubClass
.db   0x00                      ; bInterfaceProcotol
.db   0x05                      ; iInterface
; HID Descriptor
.db   9							; bLength
.db   0x21						; bDescriptorType
.db   0x01,0x01					; bcdHID
.db   0							; bCountryCode
.db   1							; bNumDescriptors
.db   0x22						; bDescriptorType
.db   0x35,0x00					; wDescriptorLength(report)
; IN endpoint1
.db   7							; bLength
.db   5							; bDescriptorType
.db   0x81						; bEndpointAddress
.db   0x03						; bmAttributes
.db   0x0a,0					; MaxPacketSize
.db   10						; bInterval
; OUT endpoint1
.db   0x07                         ; bLength
.db   0x05                         ; bDescriptorType
.db   0x01                         ; bEndpointAddress
.db   0x03                         ; bmAttributes
.db   0x0a,0	                 	; MaxPacketSize (LITTLE ENDIAN)
.db   10                           ; bInterval


; 53 = 0x35
descriptor_hid_report:
.db    0x06, 0x00, 0xff              ; USAGE_PAGE (Vendor Defined Page 1)
.db    0x09, 0x01                    ; USAGE (Vendor Usage 1)
.db    0xa1, 0x01                    ; COLLECTION (Application)
.db    0x85, 0x01                    ;   REPORT_ID (1)
.db    0x95, 0x40                    ;   REPORT_COUNT (64)
.db    0x75, 0x08                    ;   REPORT_SIZE (8)
.db    0x26, 0xff, 0x00              ;   LOGICAL_MAXIMUM (255)
.db    0x15, 0x00                    ;   LOGICAL_MINIMUM (0)
.db    0x09, 0x01                    ;   USAGE (Vendor Usage 1)
.db    0x91, 0x02                    ;   OUTPUT (Data,Var,Abs)
.db    0x85, 0x02                    ;   REPORT_ID (2)
.db    0x95, 0x40                    ;   REPORT_COUNT (64)
.db    0x75, 0x08                    ;   REPORT_SIZE (8)
.db    0x26, 0xff, 0x00              ;   LOGICAL_MAXIMUM (255)
.db    0x15, 0x00                    ;   LOGICAL_MINIMUM (0)
.db    0x09, 0x01                    ;   USAGE (Vendor Usage 1)
.db    0x81, 0x02                    ;   INPUT (Data,Var,Abs)
.db    0x85, 0x03                    ;   REPORT_ID (3)
.db    0x95, 0x01                    ;   REPORT_COUNT (1)
.db    0x75, 0x08                    ;   REPORT_SIZE (8)
.db    0x26, 0xff, 0x00              ;   LOGICAL_MAXIMUM (255)
.db    0x15, 0x00                    ;   LOGICAL_MINIMUM (0)
.db    0x09, 0x01                    ;   USAGE (Vendor Usage 1)
.db    0xb1, 0x02                    ;   FEATURE (Data,Var,Abs)
.db    0xc0                          ; END_COLLECTION

strdesc:
.dw locale_zone,manufacturer,product,serial_number,configuration,interface

locale_zone:
.db	  4					; Length
.db   3					; Type
.db   9,4				; 第一个string descriptor,定义国家地区的代码



manufacturer:
.db	8					;bLength
.db	 0x03				; Type
.db	'X',0
.db	'X',0
.db	'D',0

product:
.db	16				;bLength
.db	 0x03				; Type
.db	'P',0
.db	'r',0
.db	'o',0
.db	'd',0
.db	'u',0
.db	'c',0
.db	't',0
serial_number:
.db	20				;bLength
.db	 0x03				; Type
.db	'S',0
.db	'N',0
.db	'N',0
.db	'6',0
.db	'4',0
.db	'8',0
.db	'9',0
.db	'1',0
.db	'9',0

configuration :
.db	28				;bLength
.db	 0x03				; Type
.db	'C',0
.db	'o',0
.db	'n',0
.db	'f',0
.db	'i',0
.db	'g',0
.db	'u',0
.db	'r',0
.db	'a',0
.db	't',0
.db	'i',0
.db	'o',0
.db	'n',0

interface:
.db	20				;bLength
.db	 0x03				; Type
.db	'I',0
.db	'n',0
.db	't',0
.db	'e',0
.db	'r',0
.db	'f',0
.db	'a',0
.db	'c',0
.db	'e',0