/*
   gcc reader.c -o reader -Wall
*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

int main(void)
{
	int fd;

	for (;;) {
		usleep(rand() % 1000);
		fd = open("dovecot.index", O_RDONLY);
		if (fd == -1) {
			perror("open(dovecot.index)");
			break;
		}
		close(fd);
	}
	return 0;
}
