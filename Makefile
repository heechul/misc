#CC=$(HOME)/QorIQ-DPAA-SDK-20110609-systembuilder/freescale-2010.09/bin/powerpc-linux-gnu-gcc
#CC=clang

all: latency latency-det bandwidth fps mlp

mlp: mlp.c
	$(CC) mlp.c -O0 -o mlp -lrt -g

latency: latency.c
	$(CC) latency.c -O2 -o latency -lrt

latency-det: latency-det.c
	$(CC) latency-det.c -O2 -o latency-det -lrt

bandwidth: bandwidth.c
	$(CC) bandwidth.c -O2 -o bandwidth -lrt -g

fps: fps.c
	$(CC) fps.c -O2 -o fps -lrt

deadline: deadline.c dl_syscalls.c
	$(CC) deadline.c dl_syscalls.c -O2 -o $@ -lrt
clean:
	rm *.o *~ latency bandwidth fps mlp
