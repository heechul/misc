/**
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

/**************************************************************************
 * Included Files
 **************************************************************************/
#define _GNU_SOURCE             /* See feature_test_macros(7) */
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <inttypes.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/resource.h>
/**************************************************************************
 * Public Definitions
 **************************************************************************/

/**************************************************************************
 * Public Types
 **************************************************************************/

/**************************************************************************
 * Global Variables
 **************************************************************************/

#define CACHE_LINE_SIZE 64		//Cache Line size is 64 byte
#define ADDR_2ND_RANK 0x40000000	//The address of the 2nd Rank(1GB) of memory of 1st Mem Controller

int g_mem_size = 8192 * 1024;		//set default memory size
int g_indx = 0;				//global index used for accessing the array
int g_next = (CACHE_LINE_SIZE/4);	//incrementing the next element in the array(Sequtial Default)
int *g_mem_ptr = 0;			//pointer to allocated memory region

FILE *g_fd = NULL;			
char *g_label = NULL;

unsigned long long g_nread = 0;		//Number of bytes read
unsigned int g_start;			

/**************************************************************************
 * Public Function Prototypes
 **************************************************************************/

unsigned int get_usecs()
{
	static struct timeval  base;
	struct timeval         time;
	gettimeofday(&time, NULL);
	if (!base.tv_usec) {
		base = time;
	}
	if (base.tv_usec > time.tv_usec)
		return ((time.tv_sec - 1 - base.tv_sec) * 1000000 +
			(1000000 + time.tv_usec - base.tv_usec));
	else
		return ((time.tv_sec - base.tv_sec) * 1000000 +
			(time.tv_usec - base.tv_usec));
}

void quit(int param)
{
	float dur_in_sec;
	float bw;
	unsigned int dur = get_usecs() - g_start;
	dur_in_sec = (float)dur / 1000000;
	printf("g_nread(bytes read) = %lld\n", g_nread);
	printf("elapsed = %.2f sec (%u usec)\n", dur_in_sec, dur);
	bw = (float)g_nread / dur_in_sec / 1024 / 1024;
	printf("B/W = %.2f MB/s\n", bw);
	printf("average = %.2fns\n", ((float)dur*1000)/(g_nread/CACHE_LINE_SIZE));

	if (g_fd) {
		fprintf(g_fd, "%s %d\n", g_label, (int)bw);
		fclose(g_fd);
	}

	_exit(0);
}

int bench_read()
{
	int i;
	int sum = 0;    

	for ( i = g_indx; i < g_mem_size/4; i+=g_next ) {
		sum += g_mem_ptr[i];
		g_nread += CACHE_LINE_SIZE ;
	}
	return sum;
}

int bench_write()
{
	int i;	
	for ( i = g_indx; i < g_mem_size/4; i+=g_next ) {
		g_mem_ptr[i] = i;
		g_nread += CACHE_LINE_SIZE ;
	}
	return 1;
}

int bench_rdwr()
{
	int i;
	int sum = 0;    

	for ( i = g_indx; i < g_mem_size/4; i+=g_next ) {
		g_mem_ptr[i] = i;
		sum += g_mem_ptr[i];
		g_nread += CACHE_LINE_SIZE;
	}
	return sum;
}

enum access_type { READ, WRITE, RDWR };

int main(int argc, char *argv[])
{
	unsigned long long sum = 0;
	unsigned finish = 5;
	int cpuid = 0;
	int prio = 0;        
	int num_processors;
	int acc_type = READ;
	int opt;
	cpu_set_t cmask;

/*********************	Get Command Line Options  *****************/
	while ((opt = getopt(argc, argv, "m:a:n:t:c:p:f:l:")) != -1) {
		switch (opt) {
			//set memory size	
			case 'm':
				g_mem_size = 1024 * strtol(optarg, NULL, 0);
				break;
			//set access type
			case 'a':
				if (!strcmp(optarg, "read"))
					acc_type = READ;
				else if (!strcmp(optarg, "write"))
					acc_type = WRITE;
				else if (!strcmp(optarg, "rdwr"))
					acc_type = RDWR;
				else
					exit(1);
				break;
			//set access pattern
			case 'n':
				//Sequential
				if( strcmp(optarg,"Seq") == 0 ) {
					g_indx = 0;
					g_next = (CACHE_LINE_SIZE/4);				
				}
				//Same Bank
				else if( strcmp(optarg,"Row") == 0 ) {
					g_indx = 0;
					g_next = (CACHE_LINE_SIZE/4) * 1024;		
				}
				//Diff Bank
				else if( strcmp(optarg,"Bank") == 0 ) {
					g_indx = cpuid*128;
					g_next = (CACHE_LINE_SIZE/4) * 1024;
				}
				else
					exit(1);
				break;
			//set time in secs to run
			case 't':
				finish = strtol(optarg, NULL, 0);
				break;
			//set CPU affinity
			case 'c':
				cpuid = strtol(optarg, NULL, 0);
				num_processors = sysconf(_SC_NPROCESSORS_CONF);
				CPU_ZERO(&cmask);
				CPU_SET(cpuid % num_processors, &cmask);
				if (sched_setaffinity(0, num_processors, &cmask) < 0)
					perror("error");
				else
					fprintf(stderr, "assigned to cpu %d\n", cpuid);
				break;
			//set priority
			case 'p':
				prio = strtol(optarg, NULL, 0);
				if (setpriority(PRIO_PROCESS, 0, prio) < 0)
					perror("error");
				else
					fprintf(stderr, "assigned priority %d\n", prio);
				break;
			//set label
			case 'l':
				g_label = strdup(optarg);
				break;
			//set file descriptor
			case 'f':
				g_fd = fopen(optarg, "a+");
				if (g_fd == NULL) 
					perror("error");
				break;
		}
	}
/****************************************************************************/

/**************	Allocate Contiguous Region of Memory and Set Signals **************/
	
	//open virtual device memory file
	int fd = -1;
	fd = open("/dev/mem", O_RDWR | O_SYNC);
	if(fd == -1) printf("ERROR Opening /dev/mem\n");	

	//offset variable is used to allocate each cpu to a different offset from each other
	unsigned long offset = ADDR_2ND_RANK + cpuid*g_mem_size;

	//use mmap to allocate each cpu to the specific address in memory
	g_mem_ptr =(int *)mmap(NULL, g_mem_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, offset);
	if(g_mem_ptr == NULL) printf("could not allocate memarea");

	//print experiment info before starting
	printf("memsize=%d KB, type=%s, cpuid=%d\n",
	       g_mem_size/1024,
	       ((acc_type==READ) ?"read":
		(acc_type==WRITE)? "write" :
		(acc_type==RDWR) ? "rdwr" : "worst"),
		cpuid);
	printf("stop at %d\n", finish);

	//set signals to terminate once time has been reached
	signal(SIGINT, &quit);
	signal(SIGALRM, &quit);
	alarm(finish);

/****************************************************************************/

/*********************	Actual Access  *******************/
	g_start = get_usecs();
	while (1) {
		int sum = 0;
		switch (acc_type) {
		case READ:
			sum = bench_read();
			break;
		case WRITE:
			sum = bench_write();
			break;
		case RDWR:
			sum = bench_rdwr();
			break;
		}
	}
	printf("sum: %lld\n", sum);

/*********************************************************/
}



