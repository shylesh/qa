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
#include <dirent.h>
#include <argp.h>
#include <libgen.h>

void * open_thread (void *);
void * fstat_thread (void *);
void * read_thread (void *);
void * write_truncate_thread (void *);
void * chown_thread (void *);
void * open_lock_close (void *);
void * opendir_and_readdir ();

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
//        char *dirname;
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
                pthread_mutex_lock (&info.mutex);                       \
                {                                                       \
                        info.num_open++;                                \
                }                                                       \
                pthread_mutex_unlock (&info.mutex);                     \
                fd = open (filename, flag, mode);                       \
                if (fd == -1) {                                         \
                        ret = -1;                                       \
                        goto out;                                       \
                } else {                                                \
                        pthread_mutex_lock (&info.mutex);               \
                        {                                               \
                                info.num_open_success++;                \
                        }                                               \
                        pthread_mutex_unlock (&info.mutex);             \
                }                                                       \
        } while (0);

#ifndef UNIX_PATH_MAX
#define UNIX_PATH_MAX 4096
#endif

typedef struct info {
        pthread_mutex_t mutex;
        unsigned long long num_open;
        unsigned long long num_open_success;
        unsigned long long flocks;
        unsigned long long flocks_success;
        unsigned long long fcntl_locks;
        unsigned long long fcntl_locks_success;
        unsigned long long read;
        unsigned long long read_success;
        unsigned long long write;
        unsigned long long write_success;
        unsigned long long fstat;
        unsigned long long fstat_success;
        unsigned long long truncate;
        unsigned long long truncate_success;
        unsigned long long chown;
        unsigned long long chown_success;
        unsigned long long opendir;
        unsigned long long opendir_success;
        unsigned long long readdir;
        unsigned long long readdir_success;
} info_t;

typedef struct
{
        char directory[UNIX_PATH_MAX];
        unsigned long long time;
} thread_config_t;

info_t info = {0,};
