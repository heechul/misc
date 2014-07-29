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
// random_shuffle example
#include <iostream>     // std::cout
#include <algorithm>    // std::random_shuffle
#include <vector>       // std::vector
#include <ctime>        // std::time
#include <cstdlib>      // std::rand, std::srand

#include <sched.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
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
#define MAX_MLP 32
#define PAGE_SIZE (2*1024*1024) /* Huge TLB */
#define DRAM_PAGE_SIZE (1<<13)  /* DRAM page size = 8KB */
#ifdef __arm__
#  define CACHE_LINE_SIZE 32
#else
#  define CACHE_LINE_SIZE 64
#endif

/**************************************************************************
 * Public Types
 **************************************************************************/

/**************************************************************************
 * Global Variables
 **************************************************************************/
#ifdef __arm__
static int g_mem_size = (4*1024*1024);
#else
static int g_mem_size = (16*1024*1024);
#endif
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


int main(int argc, char* argv[])
{
	struct sched_param param;
        cpu_set_t cmask;
	int num_processors;
	int cpuid = 0;

	int *memchunk = NULL;
	int opt, prio;
	int i,j,k,l;

	int repeat = 100;
	int mlp = 1;
	int use_hugepage = 0;
	int use_dev_mem = 0;
	struct timespec start, end;

	std::srand (0);
	std::vector<int> myvector;

	/*
	 * get command line options 
	 */
	while ((opt = getopt(argc, argv, "m:c:i:l:htx")) != -1) {
		switch (opt) {
		case 'm': /* set memory size */
			g_mem_size = 1024 * strtol(optarg, NULL, 0);
			break;
		case 'c': /* set CPU affinity */
			cpuid = strtol(optarg, NULL, 0);
			fprintf(stderr, "cpuid: %d\n", cpuid);
			num_processors = sysconf(_SC_NPROCESSORS_CONF);
			CPU_ZERO(&cmask);
			CPU_SET(cpuid % num_processors, &cmask);
			if (sched_setaffinity(0, num_processors, &cmask) < 0) {
				perror("error");
				exit(1);
			}
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
		case 'l': /* MLP */
			mlp = strtol(optarg, NULL, 0);
			fprintf(stderr, "MLP=%d\n", mlp);
			break;
                case 't':
			use_hugepage = (use_hugepage) ? 0: 1;
			break;
                case 'x':
			use_dev_mem = (use_dev_mem) ? 0: 1;
			break;
		}

	}


	srand(0);

	int ws = g_mem_size / CACHE_LINE_SIZE;

	clock_gettime(CLOCK_REALTIME, &start);
	// set some values:
	for (int i=0; i<ws; i++) myvector.push_back(i); 

	printf("WSIZE: %d mlp: %d\n", ws, mlp);

	for (l = 0; l < mlp; l++) {
		/* alloc memory. align to a page boundary */

		if (use_hugepage) {
			memchunk = (int *)mmap(0, 
					       g_mem_size*2,
					       PROT_READ | PROT_WRITE, 
					       MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, 
					       -1, 0);
		} else if (use_dev_mem) {
			int fd = open("/dev/mem", O_RDWR | O_SYNC);
			void *addr = (void *) (0x1000000080000000 + g_mem_size * l);
			
			if (fd < 0) {
				perror("Open failed");
				exit(1);
			}
			
			memchunk = (int *)mmap(0, g_mem_size,
					       PROT_READ | PROT_WRITE, 
					       MAP_SHARED, 
					       fd, (off_t)addr);
		} else {
			memchunk = (int *)malloc(g_mem_size);
			printf("Using malloc(), not very accurate\n");
		}

		if ((void *)memchunk == MAP_FAILED) {
			exit(1);
		}

		/* initialize data */
		memset(memchunk, 0, g_mem_size);

		// using built-in random generator:
		std::random_shuffle ( myvector.begin(), myvector.end() );

		for (i = 0; i < ws; i++) {
			int curr_idx = myvector[i] * CACHE_LINE_SIZE / 4;
			int next_idx = myvector[(i+1) % ws] * CACHE_LINE_SIZE / 4;
			memchunk[curr_idx] = next_idx;
			// printf("%8d\n", myvector[i]);
		}

		list[l] = memchunk; // &memchunk[l * CACHE_LINE_SIZE/4];
		next[l] = list[l][0];
		printf("list[%d]  0x%p\n", l, &list[l]);
	}

	assert (!(use_hugepage && use_dev_mem));
	if (use_hugepage) printf("Using hugetlb\n");
	else if (use_dev_mem) printf("Using /dev/mem (dangerous)\n");

#if 0
        param.sched_priority = 1;
        if(sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
		perror("sched_setscheduler failed");
        }
#endif

	clock_gettime(CLOCK_REALTIME, &end);
	printf("Init took %.0f us\n", (double) get_elapsed(&start, &end)/1000);


	clock_gettime(CLOCK_REALTIME, &start);
	/* actual access */
	int naccess = run(ws*repeat, mlp);

	clock_gettime(CLOCK_REALTIME, &end);

	int64_t nsdiff = get_elapsed(&start, &end);
	double  avglat = (double)nsdiff/naccess;

	printf("size: %d (%d KB)\n", g_mem_size, g_mem_size/1024);
	printf("duration %.0f ns, #access %d\n", (double)nsdiff, naccess);
	printf("bandwidth %.2f MB/s\n", (double)64*1000*naccess/nsdiff);

	return 0;
}
