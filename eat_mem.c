/*
 * eat_mem.c
 *
 * My memory eater program.
 */
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

static long usleep_time = 100;

static void _print_usage()
{
	printf("\nThis program allocates and never free's a configurable amount of memory every %ld microseconds until either the program exits due to out of memory or the program ate the configurable maximum amount of memory.\n",
	       usleep_time);
	printf("\nUsage:\n\n");
	printf("./eat_mem [multiplier] [max] [sleep time]\n");
	printf("\n  multiplier - how much memory to eat each interval (KB). Default = 1 KB");
	printf("\n  max - the maximum amount of memory to eat (KB). Default = INFINITY (no limit)");
	printf("\n  sleep time - how long to sleep before starting to eat memory (seconds). Default = 5 seconds.");
	printf("\n\nEach argument is optional.\n");
}

int main(int argc, char **argv)
{
	printf("my pid: %d\n", getpid());
	fflush(stdout);

	unsigned int multiplier = 1;
	unsigned int sleep_at_beginning = 2;
	long max_mem_eat = -1;
	long curr_mem_eaten = 0;

	if (argc > 1) {
		if (strstr("help", argv[1])) {
			_print_usage();
			exit(0);
		}
		multiplier=atoi(argv[1]);
	}
	if (argc > 2) {
		max_mem_eat=atoi(argv[2])*1000;
	}
	if (argc > 3) {
		sleep_at_beginning=atoi(argv[3]);
	}

	printf("max_mem_eat=%ld\n", max_mem_eat);
	printf("sleep %u seconds before starting, eat %u kB every %f ms ",
	       sleep_at_beginning, multiplier, (double)usleep_time / 1000.0);
	if (max_mem_eat == -1) {
		printf("until out of memory\n");
	} else {
		printf("up to %f KB\n", (double)max_mem_eat / 1000.0);
	}
	fflush(stdout);
	sleep(sleep_at_beginning);
	printf("start eating memory\n");
	fflush(stdout);
	const unsigned int alloc_mem = 1000*multiplier;
	while (1) {
		// calloc 1kB * multiplier at a time
		char *ptr = calloc(alloc_mem,sizeof *ptr);
		// need to actually use the memory so it's in ram, not just
		// virtual memory space
		for (unsigned int i = 0; i < alloc_mem; ++i) {
			ptr[i] = 'a';
		}
		curr_mem_eaten += alloc_mem * sizeof *ptr;
		// if max_mem_eat was specified, don't eat more memory than the
		// value of max_mem_eat
		if (max_mem_eat > 0 && curr_mem_eaten >= max_mem_eat) {
			printf("Ate %.0f kB, stop eating memory and spin forever.\n",
			       (double)curr_mem_eaten / 1000.0);
			fflush(stdout);
			while(1) sleep(1);
		}
		usleep(usleep_time);
	}
	return 0;
}
