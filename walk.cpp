/*
  $Id$
  find all usb devices
*/

#ifndef UNICODE
#define UNICODE		// 设定了这个以后。系统调用返回的字符串是UNICODE
#endif
#include <windows.h>
#include <stdio.h>
#include <setupapi.h>
#include <ddk/hidsdi.h>
#include <ddk/usbioctl.h>   // USB_NODE_INFORMATION
//#include <ddk/usbiodef.h> // GUID_DEVINTERFACE_USB_DEVICE
#include <clocale>

//#include <lusb0_usb.h>
void showError(DWORD errCode){
  LPTSTR lpMsg;
  if(!FormatMessage(
					/*
					  FORMAT_MESSAGE_ALLOCATE_BUFFER 由系统分配一个内存快。用存放返回的信息。
					  需要用LocalFree主动释放内存
					*/
					FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
					NULL,
					errCode,
					MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
					(LPTSTR)&lpMsg,
					0,
					NULL
					)){
	wprintf(L"format message failed with 0x%x\n",GetLastError());
	return;
  }
  wprintf(L"(%d)%s",errCode,lpMsg);
  LocalFree(lpMsg);

}
wchar_t *simple_conv(wchar_t *dst,const char *src){
  int i=0;
  while(src[i]){
	dst[i]=(wchar_t)src[i];
	i++;
  }
  dst[i]=0;
  return dst;
}
void walkthrough_hid(void){

  GUID hidGuid;
  HDEVINFO deviceInfoList;
  SP_DEVICE_INTERFACE_DATA deviceInfo;
  DWORD size;
  PSP_DEVICE_INTERFACE_DETAIL_DATA deviceDetails = NULL;
  HANDLE handle = INVALID_HANDLE_VALUE;
  HIDD_ATTRIBUTES deviceAttributes;

  HidD_GetHidGuid(&hidGuid);
  deviceInfoList=SetupDiGetClassDevs(&hidGuid,NULL,NULL,DIGCF_PRESENT | DIGCF_INTERFACEDEVICE);
  deviceInfo.cbSize = sizeof(deviceInfo);
  int idx=0;
  wprintf(L"==================== HID USB ==================\n");
  while(true){
	if(handle != INVALID_HANDLE_VALUE){
	  CloseHandle(handle);
	  handle = INVALID_HANDLE_VALUE;
	}
	if(!SetupDiEnumDeviceInterfaces(deviceInfoList,0,&hidGuid,idx++,&deviceInfo))
	  break; /* no more entries */
	wprintf(L"-----------------------------------------------------------\n");
	SetupDiGetDeviceInterfaceDetail(deviceInfoList, &deviceInfo, NULL, 0, &size,NULL);
	if(deviceDetails != NULL) free(deviceDetails);
	deviceDetails = (SP_DEVICE_INTERFACE_DETAIL_DATA*)malloc(size);
	deviceDetails->cbSize=sizeof(*deviceDetails);
	SetupDiGetDeviceInterfaceDetail(deviceInfoList,&deviceInfo,deviceDetails,size,&size,NULL);
	wprintf(L"HID PATH=\"%s\"\n",deviceDetails->DevicePath);
	handle = CreateFile(deviceDetails->DevicePath,
						GENERIC_READ|GENERIC_WRITE,
						FILE_SHARE_READ|FILE_SHARE_WRITE,
						NULL,
						OPEN_EXISTING,
						0,NULL);
	if (handle == INVALID_HANDLE_VALUE){
	  showError(GetLastError());
	  continue;
	}
	deviceAttributes.Size=sizeof(deviceAttributes);
	HidD_GetAttributes(handle,&deviceAttributes);
	//wchar_t *buff=new wchar_t[512];
	LPVOID buff=malloc(1024);
	wprintf(L"ATTRIBUTES: vid=0x%x pid=0x%x\n",
			deviceAttributes.VendorID,
			deviceAttributes.ProductID);
	if(!HidD_GetManufacturerString(handle,buff,1024)){
	  showError(GetLastError());
	}else {
	  wprintf(L"Manufacture name=%s\n",(wchar_t*)buff);
	}
	if(!HidD_GetProductString(handle,buff,1024)){
	  showError(GetLastError());
	} else {
	  wprintf(L"Product name= %s\n",(wchar_t*)buff);
	}
	if(!HidD_GetSerialNumberString(handle,buff,1024)){
	  showError(GetLastError());
	} else {
	  wprintf(L"Serial Number= %s\n",(wchar_t*)buff);
	}
	if(!HidD_GetPhysicalDescriptor(handle,buff,1024)){
	  showError(GetLastError());
	} else {
	  wprintf(L"Physical Descriptor= %s\n",(wchar_t *)buff);
	}

	if(!WriteFile(handle,(LPCVOID)buff,10,NULL,NULL)){
	  showError(GetLastError());
	} else {
	  wprintf(L"Wrote successful!\n");
	}
	if(!ReadFile(handle,buff,1,NULL,NULL)){
	  showError(GetLastError());
	} else {
	  wprintf(L"Read successful!\n");
	}
	CloseHandle(handle);


	//delete [] buff;
	free(buff);
  }
}

// 用缺省的定义编译报错，出处 ddk/usbiodef.h
const GUID GUID_DEVINTERFACE_USB_DEVICE = {0xA5DCBF10L, 0x6530, 0x11D2, {0x90, 0x1F, 0x00, 0xC0, 0x4F, 0xB9, 0x51, 0xED}};
void print_desc(HANDLE h){
  DWORD size;
  PBYTE buff=(PBYTE)malloc(512) ;
  USB_NODE_INFORMATION *usb_info = (USB_NODE_INFORMATION*)buff;
  USB_HUB_DESCRIPTOR *usb_desc = &(usb_info->u.HubInformation.HubDescriptor);
  if(!DeviceIoControl(h,IOCTL_USB_GET_NODE_INFORMATION,0,0,usb_info,512,&size,0)){
	showError(GetLastError());
  }else {
	if(usb_info->u.HubInformation.HubIsBusPowered){
	  wprintf(L"总线供电,");
	} else {
	  wprintf(L"  自供电,");
	}
	wprintf(L"Number of Ports: %d",usb_desc->bNumberOfPorts);
  }
  wprintf(L"\n");
  free(buff);
}
void all_usb(void){
  HDEVINFO devInfoList;
  SP_DEVICE_INTERFACE_DATA devInfoData;
  PSP_DEVICE_INTERFACE_DETAIL_DATA devDetails = NULL;
  devInfoData.cbSize=sizeof(SP_DEVINFO_DATA);
  //	PSP_DEVICE_INTERFACE_DETAIL_DATA pdevInterfaceDetailData = NULL;
  DWORD size;
  HANDLE handle;
  //ULONG propType;
  wprintf(L"==========================All USB=========================\n");
  devInfoList=SetupDiGetClassDevs(&GUID_DEVINTERFACE_USB_DEVICE,NULL,NULL,DIGCF_PRESENT|DIGCF_DEVICEINTERFACE);
  if(devInfoList == INVALID_HANDLE_VALUE){
	showError(GetLastError());
	return;
  }
  for(DWORD i=0;SetupDiEnumDeviceInterfaces(devInfoList,0,&GUID_DEVINTERFACE_USB_DEVICE,i,&devInfoData);i++){
	wprintf(L"---------------------------------------------------------\n");
	SetupDiGetDeviceInterfaceDetail(devInfoList, &devInfoData, NULL, 0, &size,NULL);
	if(devDetails != NULL ){
	  free(devDetails);
	}
	devDetails = (SP_DEVICE_INTERFACE_DETAIL_DATA*)malloc(size);
	devDetails->cbSize=sizeof(*devDetails);
	SetupDiGetDeviceInterfaceDetail(devInfoList,&devInfoData,devDetails,size,&size,NULL);
	wprintf(L"USB PATH=\"%s\"\n",devDetails->DevicePath);
	handle = CreateFile(devDetails->DevicePath,
						GENERIC_READ|GENERIC_WRITE,
						FILE_SHARE_READ|FILE_SHARE_WRITE,
						NULL,
						OPEN_EXISTING,
						0,NULL);
	if (handle == INVALID_HANDLE_VALUE){
	  showError(GetLastError());
	  continue;
	}
	print_desc(handle);


  }
  DWORD co=GetLastError();
  if(co!=ERROR_NO_MORE_ITEMS){
	showError(co);
  }
  SetupDiDestroyDeviceInfoList(devInfoList);

}
int main(int argc,char **argv){
  std::setlocale(LC_ALL,"");
  //	walk_usb();
  all_usb();
  walkthrough_hid();
}
