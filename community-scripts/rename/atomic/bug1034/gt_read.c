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
#include <ctype.h>

#include "gt.h"

static void
usage(char *progname)
{
	fprintf(stderr, "usage: %s node_count\n", progname);
	exit(1);
}

static void
dump_data(char *buf, size_t buflen)
{
	int i;

	fprintf(stderr, "raw data:  ");
	for (i = 0; i < buflen; i++) {
		int c = buf[i];

		if (isgraph(c)) {
			fprintf(stderr, "%c", c);
		} else if (isspace(c)) {
		switch (c) {
		case ' ':
			fprintf(stderr, " ");
			break;
		case '\f':
			fprintf(stderr, "\f");
			break;
		case '\n':
			fprintf(stderr, "\n");
			break;
		case '\r':
			fprintf(stderr, "\r");
			break;
		case '\t':
			fprintf(stderr, "\t");
			break;
		case '\v':
			fprintf(stderr, "\v");
			break;
		default:
			fprintf(stderr, "\%03o", c);
			break;
		}
		} else {
			fprintf(stderr, "\%03o", c);
		}
	}
	fprintf(stderr, "\n");
}

static void
touch_tree(char *rootpath, int node_count)
{
	char pathbuf[PATH_MAX];
	char databuf[PATH_MAX];
	int fd;
	int node;
	int i;
	int retval;

	for (node = 1; node <= node_count; node++) {
		for (i = 0; i < SUBDIR_FILES; i++) {
			snprintf(pathbuf, sizeof(pathbuf),
				"%s/%d/WA_RC_%d", rootpath, node, i);
			fd = open(pathbuf, O_RDONLY);
			if (0 > fd) {
				fprintf(stderr, "gt_read: %s: open %s\n",
					strerror(errno), pathbuf);
				continue;
			}
			retval = read(fd, databuf, sizeof(databuf));
			close(fd);
			if (0 > retval) {
				fprintf(stderr, "gt_read: %s: read %s\n",
					strerror(errno), pathbuf);
			} else if (retval != strlen(pathbuf)) {
				fprintf(stderr,
					"gt_read: incomplete read: read %s\n",
					pathbuf);
			} else {
				databuf[retval] = '\0';
				if (0 != strcmp(pathbuf, databuf)) {
					fprintf(stderr,
						"gt_read: bad data: read %s\n",
						pathbuf);
					dump_data(databuf, strlen(pathbuf));
				}
			}
		}
	}
}

int
main(int argc, char **argv)
{
	char *arg_ptr;
	long node_count;

	if (argc != 2) {
		usage(argv[0]);
	}

	node_count = strtol(argv[1], &arg_ptr, 10);
	if (*arg_ptr != '\0') {
		usage(argv[0]);
	}

	while (1) {
		int snooze;

		touch_tree(BASE_PATH, node_count);

		snooze = CYCLE_TIME + random()%CYCLE_JITTER;
		usleep(1000*snooze);
	}

	exit(0);
}
