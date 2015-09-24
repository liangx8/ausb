.PHONY: clean

SDAS=sdas8051.exe
SDLD=sdld.exe -i

#CC=as31
#BATTERY TYPE 1:NIHM 2:LIPO

CFLAG=/COLUMNS /D:NO_UART:1 /D:BATTERY_TYPE:1

#TARGET = oneway35
#TARGET = phone_charger
#TARGET = heli35
#TARGET = test
XUSB=xusb

all:${XUSB}.ihx
	@echo "*** Done ***"

$(XUSB).ihx:${XUSB}.ref
	${SDLD} $@ $<

%.ref:%.asm
	${SDAS} -l -s -o $@ $<
clean:
	${RM} -rf *.hex *.obj *.eep *.map *.cof *.lst *~ *.ihx *.ref *.sym
