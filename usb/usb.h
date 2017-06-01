
; function
.globl usb_start
;.globl fifo_iread
;.globl fifo_cwrite
.globl usb0_int
.globl init_usb



; data
.globl descriptor
.globl descriptor_cfg
.globl strdesc
.globl descriptor_hid_report
;; bRequest codes
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

; Standard Descriptor Types
DSC_DEVICE          .equ    0x01     ; Device Descriptor
DSC_CONFIG          .equ    0x02     ; Configuration Descriptor
DSC_STRING          .equ    0x03     ; String Descriptor
DSC_INTERFACE       .equ    0x04     ; Interface Descriptor
DSC_ENDPOINT        .equ    0x05     ; Endpoint Descriptor
DSC_QUALIFIER       .equ    0x06     ; Qualifier Descriptor
DSC_HIDREPORT		.equ	0x22     ; hid report

; EP0 packet byte map
bmRequestType		.equ 0
bRequest			.equ 1
wValue				.equ 2
wIndex				.equ 4
wLength				.equ 6
