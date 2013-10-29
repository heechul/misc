/**
 * 
 *
 * Copyright (C) 2010  Heechul Yun <heechul@illinois.edu> 
 *
 * This file is distributed under the University of Illinois Open Source
 * License. See LICENSE.TXT for details.
 *
 */ 

/**************************************************************************
 * Conditional Compilation Options
 **************************************************************************/

/**************************************************************************
 * Included Files
 **************************************************************************/
#define _GNU_SOURCE             /* See feature_test_macros(7) */
#include <sched.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <sys/time.h>
#include <inttypes.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <assert.h>

/**************************************************************************
 * Public Definitions
 **************************************************************************/
#define PAGE_SIZE (2*1024*1024) /* Huge TLB */
#define DEFAULT_DRAM_PAGE_SHIFT 13  /* DRAM page size = 8KB */
#define CACHE_LINE_SIZE 64

#define FATAL do { fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", \
   __LINE__, __FILE__, errno, strerror(errno)); exit(1); } while(0)

#define MAX(a,b) ((a>b)?(a):(b))

/**************************************************************************
 * Public Types
 **************************************************************************/

/**************************************************************************
 * Global Variables
 **************************************************************************/
static int g_mem_size = 64 * PAGE_SIZE;
static int* list;
static int next;

/**************************************************************************
 * Public Function Prototypes
 **************************************************************************/
uint64_t get_elapsed(struct timespec *start, struct timespec *end)
{
	uint64_t dur;
	if (start->tv_nsec > end->tv_nsec)
		dur = (uint64_t)(end->tv_sec - 1 - start->tv_sec) * 1000000000 +
			(1000000000 + end->tv_nsec - start->tv_nsec);
	else
		dur = (uint64_t)(end->tv_sec - start->tv_sec) * 1000000000 +
			(end->tv_nsec - start->tv_nsec);

	return dur;

}

/**************************************************************************
 * Implementation
 **************************************************************************/
int run(int iter)
{
	int i;
	int cnt = 0;
	for (i = 0; i < iter; i++) {
		next = list[next];
		cnt ++;
	}
	return cnt;
}


int main(int argc, char* argv[])
{
	struct sched_param param;
        cpu_set_t cmask;
	int num_processors;
	int cpuid = 0;

	int *memchunk = NULL;
	int opt, prio;
	int i,j;

	int repeat = 1000;

	int offset = 0;

	int page_shift = DEFAULT_DRAM_PAGE_SHIFT;
	int fd = -1;

	void *addr = (void *) 0x1000000080000000;

	/*
	 * get command line options 
	 */
	while ((opt = getopt(argc, argv, "a:xb:o:m:c:i:l:h")) != -1) {
		switch (opt) {
		case 'b': /* bank offset */
			page_shift = strtol(optarg, NULL, 0);
			break;
		case 'o': /* bank offset */
			offset = strtol(optarg, NULL, 0);
			break;
		case 'm': /* set memory size */
			g_mem_size = 1024 * strtol(optarg, NULL, 0);
			break;
		case 'c': /* set CPU affinity */
			cpuid = strtol(optarg, NULL, 0);
			num_processors = sysconf(_SC_NPROCESSORS_CONF);
			CPU_ZERO(&cmask);
			CPU_SET(cpuid % num_processors, &cmask);
			if (sched_setaffinity(0, num_processors, &cmask) < 0)
				perror("error");
			else
				fprintf(stderr, "assigned to cpu %d\n", cpuid);
			break;
		case 'p': /* set priority */
			prio = strtol(optarg, NULL, 0);
			if (setpriority(PRIO_PROCESS, 0, prio) < 0)
				perror("error");
			else
				fprintf(stderr, "assigned priority %d\n", prio);
			break;
		case 'i': /* iterations */
			repeat = strtol(optarg, NULL, 0);
			fprintf(stderr, "repeat=%d\n", repeat);
			break;
		}

	}

	fd = open("/dev/mem", O_RDWR | O_SYNC);
	if (fd < 0) {
		perror("Open failed");
		exit(1);
	}

	/* alloc memory. align to a page boundary */
	memchunk = mmap(0,
			g_mem_size + (1<<page_shift),
			PROT_READ | PROT_WRITE, 
			MAP_SHARED, 
			fd, (off_t)addr);

	if (memchunk == MAP_FAILED) {
		perror("failed to alloc");
		exit(1);
	}

	/* initialize data */
	int off_idx = offset * (1<<page_shift) / 4;
	
	if ((1<<page_shift) >= PAGE_SIZE)
		off_idx ++;

	list = &memchunk[off_idx];
	for (i = 0; i < 32; i++) {
		int idx = i * PAGE_SIZE / 4;
		if (i == 31)
			list[idx] = 0;
		else
			list[idx] = (i+1) * PAGE_SIZE/4;
	}
	next = 0;
	printf("offset: %d, pshift: %d\n", offset, page_shift);

#if 0
        param.sched_priority = 10;
        if(sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
		perror("sched_setscheduler failed");
        }
#endif
	struct timespec start, end;

	clock_gettime(CLOCK_REALTIME, &start);

	/* actual access */
	int naccess = run(repeat);

	clock_gettime(CLOCK_REALTIME, &end);

	int64_t nsdiff = get_elapsed(&start, &end);
	double  avglat = (double)nsdiff/naccess;

	printf("size: %d (%d KB)\n", g_mem_size, g_mem_size/1024);
	printf("duration %ld ns, #access %d\n", nsdiff, naccess);
	printf("average latency: %ld ns\n", nsdiff/naccess);
	printf("bandwidth %.2f MB/s\n", (double)64*1000*naccess/nsdiff);

	return 0;
}
