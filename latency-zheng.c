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
#include <string.h>
#include <errno.h>
#include "list.h"

/**************************************************************************
 * Public Definitions
 **************************************************************************/
#define CACHE_LINE_SIZE 64
#define CACHE_LINE_BITS 6

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


int main(int argc, char* argv[])
{
	struct item *list;	
	struct list_head head;
	struct list_head *pos;
	struct timespec start, end;
	struct sched_param param;

	uint64_t nsdiff;
        cpu_set_t cmask;

	char *access_type;
	int repeat = 1;
	int cpuid = 0;
	int num_processors;

	unsigned int num_elements = 1024;
	unsigned int i;


	if (argc >= 2)
		num_elements = (strtol(argv[1], NULL, 0) * 1024) / CACHE_LINE_SIZE;

	if (argc >= 3)
		access_type = argv[2];

	if (argc >= 4)
		repeat = strtol(argv[3], NULL, 0);

	if (argc >= 5)
		cpuid = strtol(argv[4], NULL, 0);


/////////Set Processer Affinity//////////////////////////////////
	num_processors = sysconf(_SC_NPROCESSORS_CONF);
        CPU_ZERO(&cmask);
        CPU_SET(cpuid % num_processors, &cmask);
        sched_setaffinity(0, num_processors, &cmask);

#if 1
        param.sched_priority = 1;
        if(sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
		perror("sched_setscheduler failed");
        }
#endif
//////////////////////////////////////////////////////////////////



//////// Allocate Contiguous Region of Memory ///////////////////////////////////////////////	

	unsigned long size = (sizeof(struct item) * num_elements);	
	unsigned long offset = 0x40000000 + cpuid*size;

	int fd = -1;
	fd = open("/dev/mem", O_RDWR | O_SYNC);
	if(fd == -1) printf("ERROR Opening /dev/mem\n");
	

	list =(struct item *)mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, offset);
	if(list == NULL) printf("could not allocate memarea");


//	printf("offset=%lx\n",offset);
//	printf("size of struct item=%d\n", sizeof(struct item));
//	printf("addr: 0x%x   aligned?:%s\n", (unsigned)list, (((unsigned)list)%64==0)?"yes":"no");
////////////////////////////////////////////////////////////////////////////////////////////


//////// Initialize each element in LS to point to itself///////////////////////////////////
	
	INIT_LIST_HEAD(&head);
	
	for (i = 0; i < num_elements; i++) {
		list[i].data = i;
		list[i].in_use = 0;
		INIT_LIST_HEAD(&list[i].list);
	}
////////////////////////////////////////////////////////////////////////////////////////////


////////// Set the elements in linked list according to access types ///////////////////////

	if( strcmp(access_type,"Seq") == 0 ) {
		for(i=0; i < num_elements; i++) {
			list_add(&list[i].list, &head);
		}
	}
	else if( strcmp(access_type,"Row") == 0 ) {
		for(i=0; i < num_elements; i+=1024) {
			list_add(&list[i].list, &head);
		}
	}
	else if( strcmp(access_type,"Row2") == 0 ) {
		int row;
		for(i=0; i < 128; i++) {
			list_add(&list[i].list, &head);
			for(row=1; row < (num_elements/1024); row++) {
				list_add(&list[i+row*1024].list, &head);
			}
		}
	}
	else if( strcmp(access_type,"Bank") == 0 ) {
		for(i=(cpuid*128); i < num_elements; i+=1024) {
			list_add(&list[i].list, &head);
		}
	}
	else if( strcmp(access_type,"Perm") == 0 ) {

		i = num_elements;
		while (i > 0) {
			int idx;
			int j;		
			idx = rand() % num_elements;

			for (j = idx; j < idx + num_elements; j++) {
				int idx2 = j % num_elements;
				if (!list[idx2].in_use) {
					//printf("idx2=%d\n",idx);
					list_add(&list[idx2].list, &head);
					list[idx2].in_use = 1;
					i--;
					break;
				}
			}
		}
	}

/////////////////////////////////////////////////////////////////////////////////////////////


	
///////// Actual access /////////////////////////////////////////////////////////////////////

	int count;
	
	clock_gettime(CLOCK_REALTIME, &start);
	for (i = 0; i < repeat; i++) {
		count = 0;
		list_for_each(pos, &head) {
			struct item *tmp = list_entry(pos, struct item, list);
			count++;			
		}
	}
	clock_gettime(CLOCK_REALTIME, &end);

	nsdiff = get_elapsed(&start, &end);

	printf("duration %lldus\naverage %lldns\n", nsdiff/1000, nsdiff/count/repeat);
	//printf("count=%d\n",count);

////////////////////////////////////////////////////////////////////////////////////////////////

	
	return 0;

}
