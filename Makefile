CC=gcc
PGMS=mc-mapping latency bandwidth fps mlp pagetype devmem2 hrt

all: $(PGMS)

hrt: hrt.c
	$(CC) $< -O2 -o $@ -lrt
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
