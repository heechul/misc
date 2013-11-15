/**
 * DRAM access latency measurement program
 *
 * Copyright (C) 2012  Heechul Yun <heechul@illinois.edu>
 *
 * This file is distributed under the University of Illinois Open Source
 * License. See LICENSE.TXT for details.
 *
 */

/**************************************************************************
 * Conditional Compilation Options
 **************************************************************************/
// #define USE_RDTSC 1

/**************************************************************************
 * Included Files
 **************************************************************************/

#define _GNU_SOURCE             /* See feature_test_macros(7) */
#include <sched.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <signal.h>
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
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>

#include "list.h"

/**************************************************************************
 * Public Definitions
 **************************************************************************/
#define CACHE_LINE_SIZE 64
#define CACHE_LINE_BITS 6
#define NUM_FRAMES 5

/**************************************************************************
 * Public Types
 **************************************************************************/

struct item {
	int data;
	int in_use;
	struct list_head list;
} __attribute__((aligned(CACHE_LINE_SIZE)));;

/**************************************************************************
 * Global Variables
 **************************************************************************/

int g_mem_size = 16384*1024;
volatile int quit_signal;


/**************************************************************************
 * Public Function Prototypes
 **************************************************************************/

#if USE_FTRACE
static void setup_ftrace_marker(void)
{
	struct stat st;
	char *files[] = {
		"/sys/kernel/debug/tracing/trace_marker",
		"/debug/tracing/trace_marker",
		"/debugfs/tracing/trace_marker",
	};
	int ret;
	int i;

	for (i = 0; i < (sizeof(files) / sizeof(char *)); i++) {
		ret = stat(files[i], &st);
		if (ret >= 0)
			goto found;
	}
	/* todo, check mounts system */
	return;
found:
	mark_fd = open(files[i], O_WRONLY);
}

static void ftrace_write(const char *fmt, ...)
{
	va_list ap;
	int n;
	int ret;

	if (mark_fd < 0)
		return;

	va_start(ap, fmt);
	n = vsnprintf(buff, BUFSIZ, fmt, ap);
	va_end(ap);

	ret = write(mark_fd, buff, n);
}
#else /* USE_FTRACE */
static void ftrace_write(const char *fmt, ...) {}
static void setup_ftrace_marker(void) {}
#endif

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

static __inline__ unsigned long rdtsc(void)
{
	unsigned a, d; 
	asm volatile("rdtsc" : "=a" (a), "=d" (d)); 
	return ((unsigned long)a) | (((unsigned long)d) << 32); 
}

static __inline__ unsigned long long rdtsc_v1(void)
{
	unsigned long long int x;
	__asm__ volatile (".byte 0x0f, 0x31" : "=A" (x));
	return x;
}

void usage(int argc, char *argv[])
{
	printf("Usage: $ %s [<option>]*\n\n", argv[0]);
	printf("-C: \n");
	printf("-s: turn serial access mode on\n");
	printf("-c: CPU to run.\n");
	printf("-i: iterations. 0 means intefinite. default=0\n");
	printf("-p: priority\n");
	printf("-h: help\n");
	printf("\nExamples: \n$ bandwidth -m 8192 -a read -t 1 -c 2\n  <- 8MB read for 1 second on CPU 2\n");
	exit(1);
}

void quit(int param)
{
	quit_signal = 1;
}

int main(int argc, char* argv[])
{
	struct item *list[NUM_FRAMES];
	int workingset_size = 1024;

	int i, j;
	struct list_head head[NUM_FRAMES];
	struct list_head *pos;
	double nsdiff;
	double avglat;
	uint64_t readsum = 0, cnt;
	int serial = 0;
	int cpuid = 0;

	int interval = 100;
	int repeat = 1;

	struct sched_param param;
        cpu_set_t cmask;
	int num_processors;
	int opt, prio;

	signal(SIGINT, &quit);

	/*
	 * get command line options 
	 */
	while ((opt = getopt(argc, argv, "sc:i:C:I:p:o:h")) != -1) {
		switch (opt) {
		case 's': /* set access type */
			serial = 1;
			break;
		case 'c': /* set CPU affinity */
			cpuid = strtol(optarg, NULL, 0);
			num_processors = sysconf(_SC_NPROCESSORS_CONF);
			CPU_ZERO(&cmask);
			CPU_SET(cpuid % num_processors, &cmask);
			if (sched_setaffinity(0, num_processors, &cmask) < 0) {
				perror("error");
				exit(1);
			} else
				fprintf(stderr, "assigned to cpu %d\n", cpuid);
			break;

		case 'p': /* set priority */
			prio = strtol(optarg, NULL, 0);
			if (setpriority(PRIO_PROCESS, 0, prio) < 0) {
				perror("error");
				exit(2);
			}else
				fprintf(stderr, "assigned priority %d\n", prio);
			break;
		case 'o': /* SCHED_BATCH */
			if (!strcmp(optarg, "batch")) {
				param.sched_priority = 0; 
				if(sched_setscheduler(0, SCHED_BATCH, &param) == -1) {
					perror("sched_setscheduler failed");
					exit(1);
				}
			} else if (!strcmp(optarg, "fifo")) {
				param.sched_priority = 1; 
				if(sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
					perror("sched_setscheduler failed");
					exit(1);
				}
			}
			break;
		case 'i': /* iterations */
			repeat = strtol(optarg, NULL, 0);
			fprintf(stderr, "repeat=%d\n", repeat);
			break;

		case 'I': /* interval (#of access) */
			interval = strtof(optarg, NULL);
			fprintf(stderr, "I(interval)=%d\n", interval);
			break;

		case 'h':
			usage(argc, argv);
			break;
		}
	}

	setup_ftrace_marker();

	workingset_size = g_mem_size / CACHE_LINE_SIZE;
	srand(0);



	/* allocate */
	for (i = 0; i < NUM_FRAMES; i++) {
		INIT_LIST_HEAD(&head[i]);
		list[i] = (struct item *)malloc(sizeof(struct item) 
					     * workingset_size + CACHE_LINE_SIZE);

		for (j = 0; j < workingset_size; j++) {
			list[i][j].data = j;
			list[i][j].in_use = 0;
			INIT_LIST_HEAD(&list[i][j].list);
		}
		// printf("%d 0x%x\n", list[i].data, &list[i].data);
	}
	fprintf(stderr, "allocated: wokingsetsize=%d entries\n", workingset_size);

	ftrace_write("PGM: begin permutation\n");
	/* initialize. TODO: random permutation algorithm */
	int *perm = (int *)malloc(workingset_size * sizeof(int));
	for (i = 0; i < workingset_size; i++)
		perm[i] = i;

	if (!serial) {
		for (i = 0; i < workingset_size; i++) {
			int tmp = perm[i];
			int next = rand() % workingset_size;
			perm[i] = perm[next];
			perm[next] = tmp;
		}
	}
	for (i = 0; i < NUM_FRAMES; i++) {
		for (j = 0; j < workingset_size; j++) {
			list_add(&list[i][perm[j]].list, &head[i]);
		}
	}
	ftrace_write("PGM: end permutation\n");

	/* actual access */
	nsdiff = 0; j = 0; i = 0; 
	quit_signal = 0;
	cnt = 0;
	ftrace_write("PGM: begin main loop\n");
	double tmpdiff = 0;
#if USE_RDTSC
	unsigned long start_cycle, dur_cycle;
	start_cycle = rdtsc();
	dur_cycle = rdtsc() - start_cycle;
	fprintf(stderr, "rdtsc() overhead: %ld cycles (%.2f ns)\n", 
		dur_cycle, (double)dur_cycle / 2.8 );
	start_cycle = rdtsc();
#else
	struct timespec start, end;
	clock_gettime(CLOCK_REALTIME, &start);
	clock_gettime(CLOCK_REALTIME, &end);
	fprintf(stderr, "clock_gettime() overhead: %ld ns\n", get_elapsed(&start, &end));
	clock_gettime(CLOCK_REALTIME, &start);
#endif
	while (1) {

		list_for_each(pos, &head[i % NUM_FRAMES]) {
			struct item *tmp = list_entry(pos, struct item, list);
			readsum += tmp->data;
			cnt++;
			if (cnt % interval == 0) {
#if USE_RDTSC
				dur_cycle = rdtsc() - start_cycle - 24;
				tmpdiff = (double)dur_cycle / 2.8;
#else
				clock_gettime(CLOCK_REALTIME, &end);
				tmpdiff = (double)get_elapsed(&start, &end);
#endif
				int64_t idx = cnt / interval;
				double  val = tmpdiff/1000;
				printf("%ld %.2f\n", idx, val);
				nsdiff += tmpdiff;

				if (cnt % (interval * repeat / 100) == 0)
					usleep(1000);
				// fprintf(stderr, "%ld %.2f\n", idx, val);
#if USE_RDTSC
				start_cycle = rdtsc();
#else
				clock_gettime(CLOCK_REALTIME, &start);
#endif
	
			}
			if (cnt / interval == repeat || quit_signal)
				goto out;
		}
	}
out:
	avglat = nsdiff/cnt;

	fprintf(stderr, "duration %.1fus\naverage %.0fns | ", 
		nsdiff/1000, avglat);
	fprintf(stderr, "bandwidth %.1f MB (%.1f MiB)/s\n", 
		(double)64*1000/avglat, 
		(double)64*1000000000/avglat/1024/1024);
	fprintf(stderr, "readsum  %lld\n", (unsigned long long)readsum);

	return 0;
}
