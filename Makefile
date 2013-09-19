#CC=$(HOME)/QorIQ-DPAA-SDK-20110609-systembuilder/freescale-2010.09/bin/powerpc-linux-gnu-gcc
#CC=clang

all: latency latency-det bandwidth fps mlp latency-mlp pagetype devmem2

mlp: mlp.c
	$(CC) mlp.c -O2 -o mlp -lrt -g
latency-mlp: latency-mlp.cpp
	$(CXX) latency-mlp.cpp -O0 -o latency-mlp -lrt
latency: latency.c
	$(CC) latency.c -O2 -o latency -lrt

latency-det: latency-reorder.c
	$(CC) latency-reorder.c -O2 -o latency-reorder -lrt

latency-loop: latency-loop.c
	$(CC) latency-loop.c -O2 -o latency-loop -lrt

bandwidth: bandwidth.c
	$(CC) bandwidth.c -O2 -o bandwidth -lrt -g

fps: fps.c
	$(CC) fps.c -O2 -o fps -lrt

deadline: deadline.c dl_syscalls.c
	$(CC) deadline.c dl_syscalls.c -O2 -o $@ -lrt

pagetype: pagetype.c
	$(CC) $< -O2 -o $@ -lrt -g

clean:
	rm *.o *~ latency latency-mlp bandwidth fps mlp
