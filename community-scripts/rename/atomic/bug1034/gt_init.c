#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "gt.h"

static void
usage(char *progname)
{
	fprintf(stderr, "usage: %s node_count\n", progname);
	exit(1);
}

// rm -rf
static void
delete_tree(char *rootpath)
{
	int retval;
	struct stat statbuf;

	retval = lstat(rootpath, &statbuf);
	if (retval < 0) {
		return;
	}

	if (S_ISDIR(statbuf.st_mode)) {
		DIR *dir;
		struct dirent *dent;
		char pathbuf[PATH_MAX];

		dir = opendir(rootpath);
		while ((dent = readdir(dir)) != NULL) {
			if (0 == strcmp(".", dent->d_name)) {
				continue;
			}
			if (0 == strcmp("..", dent->d_name)) {
				continue;
			}
			snprintf(pathbuf, sizeof(pathbuf),
				"%s/%s", rootpath, dent->d_name);
			delete_tree(pathbuf);
		}
		closedir(dir);

		(void)rmdir(rootpath);
	} else {
		(void)unlink(rootpath);
	}
}

static void
create_subdir(char *dirpath)
{
	int i;

	mkdir(dirpath, 0775);

	for (i = 0; i < SUBDIR_FILES; i++) {
		char pathbuf[PATH_MAX];
		int fd;

		snprintf(pathbuf, sizeof(pathbuf),
			"%s/WA_RC_%d", dirpath, i);
		fd = open(pathbuf, O_RDWR|O_CREAT, 0664);
		write(fd, pathbuf, strlen(pathbuf));
		close(fd);
	}
}

static void
create_tree(char *rootpath, int node_count)
{
	int n;

	mkdir(rootpath, 0775);

	for (n = 1; n <= node_count; n++) {
		char pathbuf[PATH_MAX];
		int fd;

		snprintf(pathbuf, sizeof(pathbuf),
			"%s/%d", rootpath, n);
		mkdir(pathbuf, 0775);
		create_subdir(pathbuf);
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

	delete_tree(BASE_PATH);

	create_tree(BASE_PATH, node_count);

	exit(0);
}
