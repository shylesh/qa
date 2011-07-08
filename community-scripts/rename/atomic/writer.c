/*
   gcc writer.c -o writer -Wall
*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

int main(void)
{
	int fd_old, fd_new, ret;

	for (;;) {
		fd_old = open("dovecot.index", O_RDWR);
		if (fd_old == -1) {
			perror("open(dovecot.index");
			break;
		}

		usleep(rand() % 1000);
		fd_new = creat("dovecot.index.tmp", 0600);
		if (fd_new == -1) {
			perror("creat(dovecot.index.tmp)");
			break;
		}
		write(fd_new, "foo", 3);
		close(fd_new);

		ret = link("dovecot.index", "dovecot.index.backup.tmp");
		if (ret < 0) {
			perror("link(dovecot.index, dovecot.index.backup.tmp)");
			break;
		}
		if (rename("dovecot.index.backup.tmp", "dovecot.index.backup") < 0) {
			perror("rename(dovecot.index.backup.tmp, dovecot.index.backup)");
			break;
		}

		usleep(rand() % 1000);
		if (rename("dovecot.index.tmp", "dovecot.index") < 0) {
			perror("rename(dovecot.index.tmp, dovecot.index)");
			break;
		}
		usleep(rand() % 1000);
		close(fd_old);
	}
	return 0;
}
