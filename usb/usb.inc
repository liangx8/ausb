
;; bRequest codes for standard requests
GET_STATUS			.equ 0
CLEAR_FEATURE		.equ 1
SET_FEATURE			.equ 3
SET_ADDRESS			.equ 5
GET_DESCRIPTOR		.equ 6
SET_DESCRIPTOR		.equ 7
GET_CONFIGURATION	.equ 8
SET_CONFIGURATION	.equ 9
GET_INTERFACE		.equ 10
SET_INTERFACE		.equ 11
SYNCH_FRAME			.equ 12

;; bRequest codes for hid class-specific requests
GET_REPORT			.equ 0x01
GET_IDLE			.equ 0x02
GET_PROTOCOL		.equ 0x03
SET_REPORT			.equ 0x09
SET_IDLE			.equ 0x0a
SET_PROTOCOL		.equ 0x0b
; Standard Descriptor Types
DSC_DEVICE          .equ    0x01     ; Device Descriptor
DSC_CONFIG          .equ    0x02     ; Configuration Descriptor
DSC_STRING          .equ    0x03     ; String Descriptor
DSC_INTERFACE       .equ    0x04     ; Interface Descriptor
DSC_ENDPOINT        .equ    0x05     ; Endpoint Descriptor
DSC_QUALIFIER       .equ    0x06     ; Qualifier Descriptor
DSC_HID				.equ	0x21	 ; Hid descriptor
DSC_HIDREPORT		.equ	0x22     ; hid report


; EP0 packet byte map
bmRequestType		.equ 0
bRequest			.equ 1
wValue				.equ 2
wIndex				.equ 4
wLength				.equ 6

; bmRequestType
IN_DEVICE			.equ 0
IN_INTERFACE		.equ 1
IN_ENDPOINT			.equ 2

; wIndex
IN_EP1				.equ 0x81


EP_IDLE				.equ 0
EP_TX				.equ 1
EP_RX				.equ 2
EP_HALT				.equ 3
EP_STALL			.equ 4
EP_ADDRESS			.equ 5
