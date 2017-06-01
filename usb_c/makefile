CC=sdcc
TARGET=xusb
OBJS=${TARGET}.rel descriptor.rel function.rel
CFLAGS= --model-small --nostdlib --acall-ajmp --no-xinit-opt
LFLAGS= --out-fmt-ihx
${TARGET}.ihx:${OBJS}
	${CC} -o $@ $(OBJS) ${LFLAGS}
%.rel:%.c
	${CC} -c $< -o $@ ${CFLAGS}
clean:
	rm -rf *~ *.rel ${TARGET}.ihx *.asm *.lk *.lst *.map *.mem *.rst *.sym
