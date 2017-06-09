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
RELS = xusb.rel

all:${XUSB}.ihx
	cp $(XUSB).ihx $(XUSB).hex
	@echo "*** Done ***"

$(XUSB).ihx:${RELS}
	${SDLD} -m $@ ${RELS}

%.rel:%.asm
	${SDAS} -l -s -o $@ $<
clean:
	${RM} -rf *.hex *.obj *.eep *.map *.cof *.lst *~ *.ihx *.rel *.sym
