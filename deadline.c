#define _GNU_SOURCE             /* See feature_test_macros(7) */
#include <time.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include "dl_syscalls.h"

int main(int argc, char *argv[])
{
	int nrun = 0;
	pid_t tid;
	struct timespec next;
	struct sched_param2 param2;
	int runtime_ns = 20*1000*1000;
	int period_ns = 100*1000*1000;
	struct timespec t;
	tid = getpid();
	t.tv_sec = 0; t.tv_nsec = period_ns;
	param2.sched_priority = 0;
	param2.sched_runtime = runtime_ns;
	param2.sched_deadline = 
		param2.sched_period = period_ns;
	if (sched_setscheduler2(tid, SCHED_DEADLINE, &param2) < 0) {
		perror("scheduler");
		exit(1);
	}
	clock_gettime(CLOCK_MONOTONIC, &next);  
	next.tv_sec++;  
	while (1) {  
		// clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &next, NULL);
		nrun++;  
		// printf("task: running cycle %d\n", nrun);  
		next.tv_sec ++;
	}   
}
