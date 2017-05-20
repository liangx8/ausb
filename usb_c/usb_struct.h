#ifndef _USB_STRUCT_H_
#define _USB_STRUCT_H_


#ifndef _WORD_DEF_
#define _WORD_DEF_
typedef union
{
  uint16_t i;
  uint8_t c[2];
} WORD;

typedef struct IF_STATUS {
   uint8_t bNumAlts;             // Number of alternate choices for this
                              // interface
   uint8_t bCurrentAlt;          // Current alternate setting for this interface
                              // zero means this interface does not exist
                              // or the device is not configured
   uint8_t bIfNumber;            // Interface number for this interface
                              // descriptor
   } IF_STATUS;
typedef IF_STATUS * PIF_STATUS;


// Configuration status - only valid in configured state
// This data structure assumes a maximum of 2 interfaces for any given
// configuration, and a maximum of 4 interface descriptors (including
// all alternate settings).
typedef struct DEVICE_STATUS {
   uint8_t bCurrentConfig;       // Index number for the selected config
   uint8_t bDevState;            // Current device state
   uint8_t bRemoteWakeupSupport; // Does this device support remote wakeup?
   uint8_t bRemoteWakeupStatus;  // Device remote wakeup enabled/disabled
   uint8_t bSelfPoweredStatus;   // Device self- or bus-powered
   uint8_t bNumInterf;           // Number of interfaces for this configuration
   uint8_t bTotalInterfDsc;      // Total number of interface descriptors for
                              // this configuration (includes alt.
                              // descriptors)
   uint8_t* pConfig;             // Points to selected configuration desc
   IF_STATUS IfStatus[MAX_IF];// Array of interface status structures
   } DEVICE_STATUS;
typedef DEVICE_STATUS * PDEVICE_STATUS;

// Control endpoint command (from host)
typedef struct EP0_COMMAND {
   uint8_t  bmRequestType;       // Request type
   uint8_t  bRequest;            // Specific request
   WORD  wValue;              // Misc field
   WORD  wIndex;              // Misc index
   WORD  wLength;             // Length of the data segment for this request
  } EP0_COMMAND;

// Endpoint status (used for IN, OUT, and Endpoint0)
typedef struct EP_STATUS {
   uint8_t  bEp;                 // Endpoint number (address)
   uint16_t  uNumBytes;           // Number of bytes available to transmit
   uint16_t  uMaxP;               // Maximum packet size
   uint8_t  bEpState;            // Endpoint state
   void *pData;               // Pointer to data to transmit
   WORD  wData;               // Storage for small data packets
   } EP_STATUS;
typedef EP_STATUS * PEP_STATUS;

// Descriptor structure
// This structure contains all usb descriptors for the device.
// The descriptors are held in array format, and are accessed with the offsets
// defined in the header file "usb_desc.h". The constants used in the
// array declarations are also defined in header file "usb_desc.h".
typedef struct DESCRIPTORS {
   uint8_t bStdDevDsc[STD_DSC_SIZE];
   uint8_t bCfg1[CFG_DSC_SIZE + IF_DSC_SIZE*CFG1_IF_DSC + EP_DSC_SIZE*CFG1_EP_DSC];
} DESCRIPTORS;







#endif   /* _WORD_DEF_ */
#endif   /* _USB_STRUCT_H_ */
