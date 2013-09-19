#CC=$(HOME)/QorIQ-DPAA-SDK-20110609-systembuilder/freescale-2010.09/bin/powerpc-linux-gnu-gcc
# CC=clang
PGMS=mc-mapping latency bandwidth fps mlp pagetype devmem2
all: $(PGMS)

mlp: mlp.c
	$(CC) $< -O2 -o $@ -lrt -g
mc-mapping: mc-mapping.c
	$(CC) $< -O2 -o $@ -lrt -g
latency: latency.c
	$(CC) $< -O2 -o $@ -lrt -g
bandwidth: bandwidth.c
	$(CC) $< -O2 -o $@ -lrt -g
fps: fps.c
	$(CC) $< -O2 -o $@ -lrt -g

pagetype: pagetype.c
	$(CC) $< -O2 -o $@ -lrt -g
deadline: deadline.c dl_syscalls.c
	$(CC) deadline.c dl_syscalls.c -O2 -o $@ -lrt

clean:
	rm *.o *~ $(PGMS)
