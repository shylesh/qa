#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <pthread.h>

int open_thread (void *);
int fstat_thread (void *);
int read_thread (void *);
int write_truncate_thread (void *);
int chown_thread (void *);
void open_lock_close (void *);

int thread1_ret;
int thread2_ret;
int thread3_ret;
int thread4_ret;
int thread5_ret;
int thread6_ret;
int thread7_ret;

struct open_attributes {
        char *filename;
        int flags;
        mode_t mode;
};

typedef struct open_attributes open_t;

struct fstat_attributes {
        int fd;
        struct stat *buf;
};

typedef struct fstat_attributes fstat_t;

struct open_fstat {
        open_t *open;
        fstat_t *fstat;
};

typedef struct open_fstat oft;

#define open_validate_error_goto(filename, flag, mode)   do {           \
                fd = open (filename, flag, mode);                       \
                if (fd == -1) {                                         \
                        fprintf (stderr, "%s: open error (%s)n", __FUNCTION__, \
                                 strerror (errno));                     \
                        ret = -1;                                       \
                        goto out;                                       \
                }                                                       \
        } while (0);
