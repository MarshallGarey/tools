#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char **argv) {
	unsigned int multiplier = 1;
	unsigned int sleep_at_beginning = 5;
	long max_mem_eat = -1;
	long curr_mem_eaten = 0;
	long usleep_time = 100;
	long pid = getpid();
	int num_children = 250;
	printf("my pid: %ld\n", pid);
	fflush(stdout);
	if (argc > 1) {
		multiplier=atoi(argv[1]);
	}
	// Fork 10 times.
	for (int i = 0; i < num_children; ++i) {
		pid = fork();
		if (pid == -1) { // failure
			printf("failed to fork\n");
			exit(0);
		} else if (pid == 0) { // child
			break;
		} else { // parent
			if (num_children <= 100)
				printf("child pid = %ld\n", pid);
		}
	}
	if (pid != 0) { // parent
		printf("sleep for %u seconds before starting, eat %u kB every "
		       "%f ms, eat a maximum of %ld kB (-1 means no max)\n",
		       sleep_at_beginning,
		       multiplier,
		       (double)usleep_time / 1000.0,
		       max_mem_eat);
	}
	sleep(sleep_at_beginning);
	if (pid != 0) { // parent
		printf("start eating memory\n");
		fflush(stdout);
	}
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
		usleep(usleep_time);
	}
	return 0;
}
