/**
 * 
 *
 * Copyright (C) 2013  Heechul Yun <heechul@illinois.edu> 
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
#include <string.h>
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
#define MAX_MLP 32
#define CHUNK_SIZE (2*1024*1024) /* Huge TLB */
#define CACHE_LINE_SIZE 64

#define FATAL do { fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", \
   __LINE__, __FILE__, errno, strerror(errno)); exit(1); } while(0)

/**************************************************************************
 * Public Types
 **************************************************************************/

/**************************************************************************
 * Global Variables
 **************************************************************************/
static int g_mem_size = 32 * CHUNK_SIZE;
static int* list[MAX_MLP];
static int next[MAX_MLP];

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
int run(int iter, int mlp)
{
	int i;
	int cnt = 0;
	for (i = 0; i < iter; i++) {
		switch (mlp) {
		case 32:
			next[31] = list[31][next[31]];
		case 31:
			next[30] = list[30][next[30]];
		case 30:
			next[29] = list[29][next[29]];
		case 29:
			next[28] = list[28][next[28]];
		case 28:
			next[27] = list[27][next[27]];
		case 27:
			next[26] = list[26][next[26]];
		case 26:
			next[25] = list[25][next[25]];
		case 25:
			next[24] = list[24][next[24]];
		case 24:
			next[23] = list[23][next[23]];
		case 23:
			next[22] = list[22][next[22]];
		case 22:
			next[21] = list[21][next[21]];
		case 21:
			next[20] = list[20][next[20]];
		case 20:
			next[19] = list[19][next[19]];
		case 19:
			next[18] = list[18][next[18]];
		case 18:
			next[17] = list[17][next[17]];
		case 17:
			next[16] = list[16][next[16]];
		case 16:
			next[15] = list[15][next[15]];
		case 15:
			next[14] = list[14][next[14]];
		case 14:
			next[13] = list[13][next[13]];
		case 13:
			next[12] = list[12][next[12]];
		case 12:
			next[11] = list[11][next[11]];
		case 11:
			next[10] = list[10][next[10]];
		case 10:
			next[9] = list[9][next[9]];
		case 9:
			next[8] = list[8][next[8]];
		case 8:
			next[7] = list[7][next[7]];
		case 7:
			next[6] = list[6][next[6]];
		case 6:
			next[5] = list[5][next[5]];
		case 5:
			next[4] = list[4][next[4]];
		case 4:
			next[3] = list[3][next[3]];
		case 3:
			next[2] = list[2][next[2]];
		case 2:
			next[1] = list[1][next[1]];
		case 1:
			next[0] = list[0][next[0]];
		}
		cnt += mlp;
	}
	return cnt;
}

int run_banks(int iter, int nbanks, int *bank)
{
	int i, j;
	int cnt = 0;

	for (i = 0; i < iter; i++) {
		for (j = 0; j < nbanks; j++) {
			next[bank[j]] = list[bank[j]][next[bank[j]]];
		}
		cnt += nbanks;
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
	int i,j, k;
	int banks[MAX_MLP] = {0};
	int repeat = 1000;

	int mlp = 1;

	int fd = -1;

	int use_hugepage = 1;
	/*
	 * get command line options 
	 */
	while ((opt = getopt(argc, argv, "b:m:c:p:i:ht")) != -1) {
		switch (opt) {
		case 'b': /* selected banks */
			printf("args: %s\n", optarg);
			char *tok = strtok(optarg, ","); 
			mlp = 0;
			while (tok) {
				banks[mlp++] = strtol(tok, NULL, 0);
				tok = strtok(NULL, ",");
			}
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
			// fprintf(stderr, "repeat=%d\n", repeat);
			break;
		case 't':
			use_hugepage = (use_hugepage) ? 0: 1;
			break;
		}
	}

	/* alloc memory. align to a page boundary */
	if (use_hugepage) {
		memchunk = mmap(0,
				g_mem_size,
				PROT_READ | PROT_WRITE, 
				MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, 
				fd, 0);
	} else {
		memchunk = malloc(g_mem_size);
	}

	if (memchunk == MAP_FAILED) {
		perror("failed to alloc");
		exit(1);
	}

#if 1
	/* initialize data. icecream, 1CH-1DIMM (16 banks) */
	int j_shift = 12, j_bits=2;
	int i_shift = 19, i_bits=2;
#else
	/* initialize data. icecream, 1CH-2DIMM (32 banks) */
	int j_shift = 12, i_bits=3;
	int i_shift = 20, j_bits=2;
#endif

	for (i = 0; i < 1<<i_bits; i++) {
		for (j = 0; j < 1<<j_bits; j++) {
			int idx = i * 4 + j;
			int off = (j << j_shift) | (i << i_shift);
			printf("%2d 0x%08x\n", idx, off);
			list[idx] = &memchunk[off/4];
			for (k = 0; k < g_mem_size / CHUNK_SIZE; k++) {
				int addr = (k * CHUNK_SIZE);
				int addr_next = (addr + CHUNK_SIZE) % g_mem_size;
				list[idx][addr/4] = addr_next/4;
			}
		}
	}

	printf("i_shift=%d(%d), j_shift=%d(%d), mlp: %d, use_hugepage = %d\n",
	       i_shift, i_bits, j_shift, j_bits, mlp, use_hugepage);
#if 0
        param.sched_priority = 10;
        if(sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
		perror("sched_setscheduler failed");
        }
#endif
	struct timespec start, end;

	clock_gettime(CLOCK_REALTIME, &start);

	/* actual access */
	// int naccess = run(repeat, mlp);
	int naccess = run_banks(repeat, mlp, banks);
	clock_gettime(CLOCK_REALTIME, &end);

	int64_t nsdiff = get_elapsed(&start, &end);
	double  avglat = (double)nsdiff/naccess;

	printf("size: %d (%d KB)\n", g_mem_size, g_mem_size/1024);
	printf("duration %.0f ns, #access %d\n", (double)nsdiff, naccess);
	printf("average latency: %.0f ns\n", (double)nsdiff/naccess);
	printf("bandwidth %.2f MB/s\n", (double)64*1000*naccess/nsdiff);

	return 0;
}
