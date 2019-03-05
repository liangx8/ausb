#CC=d:/p/mcu_dev/sdcc/bin/sdcc
ARCH=arm-none-eabi

CC=${ARCH}-gcc
AS=${ARCH}-as
OBJCOPY=${ARCH}-objcopy
OBJDUMP=${ARCH}-objdump
SIZE=${ARCH}-size



ST_FLASH=st-flash
OUTPUT_FORMAT=ihex


LINKERSCRIPT=-T linkerscript.ld

INCLUDE=-I./
INCLUDE+= -I./cmsis
INCLUDE+= -I./cmsis_boot
INCLUDE+= -I./stm_lib/inc
INCLUDE+= -I./USB-FS-Device_Lib


DEFINE=-DSTM32F103C8
DEFINE+= -DSTM32F10X_MD
DEFINE+= -DUSE_STDPERIPH_DRIVER
DEFINE+= -D__ASSEMBLY__
DEFINE+= -DSYSCLK_FREQ_72MHz


CSOURCE=$(shell find -name "*.c")
ASOURCE=$(shell find -name "*.S")
ELF=main.elf
HEX=main.hex
BIN=main.bin
DISA_LIST=main.lst


OBJS=${CSOURCE:.c=.o} ${ASOURCE:.S=.o}

#PORT=-mcpu=cortex-m3  -mthumb # -mlittle-endian
PORT=-mcpu=cortex-m3 -mthumb # -mlittle-endian

OPTC=-O2
CFLAGS= ${PORT} ${OPTC} -Wall -Wa,-mimplicit-it=always ${INCLUDE} ${DEFINE}
LFLAGS= ${LINKERSCRIPT} ${PORT} -nostartfiles -nostdlib #--specs=nosys.specs
all:${HEX}
${BIN}:${ELF}
	${OBJCOPY} -O binary $< $@
${HEX}:${ELF}
	${OBJCOPY} -O ihex $< $@
${ELF}:${OBJS}
	${CC} -o $@ ${LFLAGS} ${OBJS} 
	${SIZE} $@
.c.o:
	${CC} ${CFLAGS} -c $< -o $@
.S.o:
	${AS} ${PORT} -g $< -o $@
disa:${DISA_LIST}
${DISA_LIST}:${HEX}
	${OBJDUMP} -marm -b ihex -M force-thumb -EL -D $< > $@

clean:
	rm -rf *.o ${ELF} ${HEX} ${DISA_LIST} ${BIN} *~
	find -name "*.o" -exec rm \{\} \;
burn:${HEX}
	${ST_FLASH} erase
	${ST_FLASH} --format ${OUTPUT_FORMAT} write $<
reset_mcu:
	${ST_FLASH} reset
