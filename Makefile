CC=/home/zpwu/Desktop/P4080/P4080-Install/QorIQ1/freescale-2010.09/bin/powerpc-linux-gnu-gcc

all: latency latency-det latency-loop bandwidth fps

latency: latency.c
	$(CC) latency.c -O2 -o latency -lrt

latency-det: latency-reorder.c
	$(CC) latency-reorder.c -O2 -o latency-reorder -lrt

latency-loop: latency-loop.c
	$(CC) latency-loop.c -O2 -o latency-loop -lrt

bandwidth: bandwidth.c
	$(CC) bandwidth.c -O2 -o bandwidth -lrt

fps: fps.c
	$(CC) fps.c -O2 -o fps -lrt

deadline: deadline.c dl_syscalls.c
	$(CC) deadline.c dl_syscalls.c -O2 -o $@ -lrt
clean:
	rm *.o *~ latency bandwidth fps
