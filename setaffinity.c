/*
 * setaffinity.c
 *
 * A test program for using sched_setaffinity() to escape from the normal cpu
 * binding done by the task/affinity plugin.
 */

#define _GNU_SOURCE
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/sysinfo.h>
#include <unistd.h>

void _print_affinity(cpu_set_t *mask)
{
	uint64_t cpu_mask = 0;
	uint64_t ncores = get_nprocs();
	for (int i = 0; i < ncores; ++i) {
		if (CPU_ISSET(i, mask)) {
		    cpu_mask |= 1 << i;
		}
	}
	printf("0x%lu\n", cpu_mask);
}

int _get_affinity(cpu_set_t *mask)
{
	int rc = sched_getaffinity(0, sizeof(cpu_set_t), mask);
	if (rc) {
		printf("Error calling sched_getaffinity(), %m\n");
		return rc;
	}
	return 0;
}

int main()
{
	/*printf("Have %d procs configured and %d procs available\n",
	       get_nprocs_conf(), get_nprocs());*/

	cpu_set_t mask;

	printf("Current affinity: ");
	if (_get_affinity(&mask))
		return -1;
	_print_affinity(&mask);

	CPU_ZERO(&mask);
	CPU_SET(1, &mask);
	CPU_SET(2, &mask);
	printf("set affinity to: ");
	_print_affinity(&mask);
	int rc = sched_setaffinity(0, sizeof(cpu_set_t), &mask);
	if (rc) {
		printf("Error calling sched_getaffinity(), %m\n");
		return rc;
	}

	CPU_ZERO(&mask);
	if (_get_affinity(&mask))
		return -1;
	printf("New affinity: ");
	_print_affinity(&mask);

	printf("\nSleeping now for 60 seconds...\n");
	fflush(stdout);
	sleep(60);
	return 0;
}
