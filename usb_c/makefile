CC=sdcc
TARGET=xusb
OBJS=${TARGET}.rel
CFLAGS= --model-small --nostdlib --acall-ajmp --no-xinit-opt
LFLAGS= --out-fmt-ihx
${TARGET}.ihx:${OBJS}
	${CC} -o $@ $< ${LFLAGS}
%.rel:%.c
	${CC} -c $< -o $@ ${CFLAGS}
clean:
	rm -rf *~ *.rel ${TARGET}.ihx ${TARGET}.asm *.lk *.lst *.map *.mem *.rst *.sym
