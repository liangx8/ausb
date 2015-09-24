.PHONY: clean
CC=g++
FLAG=-Wall -g
CFLAG= -mwindows
#OBJS=main.o function.o
OBJS=walk.o

LFLAG=${FLAG} -lmingw32 -lhid -lsetupapi
#  -mwindows
all:main.exe
	@echo "*** Done ***"
main.exe:${OBJS}
	${CC} -o $@ ${OBJS} ${LFLAG}


clean:
	${RM} -rf *.o *.exe *~

.cpp.o:
	${CC} -c $< ${CFLAG}
