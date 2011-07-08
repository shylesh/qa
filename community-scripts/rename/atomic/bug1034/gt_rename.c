#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "gt.h"

static void
usage(char *progname)
{
	fprintf(stderr, "usage: %s node\n", progname);
	exit(1);
}

static void
touch_tree(char *rootpath, int node)
{
	char pathbuf[PATH_MAX];
	char databuf[PATH_MAX];
	int fd;
	int i;
	int retval;

	for (i = 0; i < SUBDIR_FILES; i++) {
		char tempbuf[PATH_MAX];

		snprintf(pathbuf, sizeof(pathbuf),
			"%s/%d/WA_RC_%d", rootpath, node, i);
		snprintf(tempbuf, sizeof(tempbuf),
			"%s/%d/WA_RC_%d.temp", rootpath, node, i);
		fd = open(tempbuf, O_RDWR|O_CREAT, 0644);
		if (0 > fd) {
			fprintf(stderr, "gt_rename: %s: open %s\n",
				strerror(errno), tempbuf);
			continue;
		}
		retval = write(fd, pathbuf, strlen(pathbuf));
		if (0 > retval) {
			fprintf(stderr, "gt_rename: %s: write %s\n",
				strerror(errno), pathbuf);
		} else if (retval != strlen(pathbuf)) {
			fprintf(stderr, "gt_rename: incomplete write: write %s\n",
				pathbuf);
		}
		close(fd);

		retval = rename(tempbuf, pathbuf);
		if (0 > retval) {
			fprintf(stderr, "gt_rename: %s rename %s\n",
				strerror(errno), pathbuf);
		}
	}
}

int
main(int argc, char **argv)
{
	char *arg_ptr;
	long node;

	if (argc != 2) {
		usage(argv[0]);
	}

	node = strtol(argv[1], &arg_ptr, 10);
	if (*arg_ptr != '\0') {
		usage(argv[0]);
	}

	while (1) {
		int snooze;

		touch_tree(BASE_PATH, node);

		snooze = CYCLE_TIME + random()%CYCLE_JITTER;
		usleep(1000*snooze);
	}

	exit(0);
}
