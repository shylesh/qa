/*
  this measures the ping-pong byte range lock latency. It is
  especially useful on a cluster of nodes sharing a common lock
  manager as it will give some indication of the lock managers
  performance under stress

  tridge@samba.org, February 2002

*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <getopt.h>
#include <sys/mman.h>
#include <limits.h>

static struct timeval tp1,tp2;

static int do_reads, do_writes, use_mmap;

struct file_info
{
        int fd;
        int num_locks;
};

typedef struct file_info file_info_t;

static void start_timer()
{
        gettimeofday(&tp1,NULL);
}

static double end_timer()
{
        gettimeofday(&tp2,NULL);
        return (tp2.tv_sec + (tp2.tv_usec*1.0e-6)) -
                (tp1.tv_sec + (tp1.tv_usec*1.0e-6));
}

/* lock a byte range in a open file */
static int lock_range(int fd, int offset, int len)
{
        struct flock lock;

        lock.l_type = F_WRLCK;
        lock.l_whence = SEEK_SET;
        lock.l_start = offset;
        lock.l_len = len;
        lock.l_pid = 0;

        return fcntl(fd,F_SETLKW,&lock);
}

/* unlock a byte range in a open file */
static int unlock_range(int fd, int offset, int len)
{
        struct flock lock;

        lock.l_type = F_UNLCK;
        lock.l_whence = SEEK_SET;
        lock.l_start = offset;
        lock.l_len = len;
        lock.l_pid = 0;

        return fcntl(fd,F_SETLKW,&lock);
}

/* run the ping pong test on fd */
static void ping_pong(void *info)
{
        file_info_t *info_file = NULL;
        unsigned count = 0;
        int i=0, loops=0;
        unsigned char *val;
        unsigned char incr=0, last_incr=0;
        unsigned char *p = NULL;
        int      fd  = -1;
        int      num_locks = -1;

        info_file = (file_info_t *)info;
        fd = info_file->fd;
        num_locks = info_file->num_locks;

        ftruncate(fd, num_locks+1);

        if (use_mmap) {
                p = mmap(NULL, num_locks+1, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
        }

        val = (unsigned char *)calloc(num_locks+1, sizeof(unsigned char));

        start_timer();

        lock_range(fd, 0, 1);
        i = 0;

        while (1) {
                if (lock_range(fd, (i+1) % num_locks, 1) != 0) {
                        printf("lock at %d failed! - %s\n",
                               (i+1) % num_locks, strerror(errno));
                }
                if (do_reads) {
                        unsigned char c;
                        if (use_mmap) {
                                c = p[i];
                        } else if (pread(fd, &c, 1, i) != 1) {
                                printf("read failed at %d\n", i);
                        }
                        incr = c - val[i];
                        val[i] = c;
                }
                if (do_writes) {
                        char c = val[i] + 1;
                        if (use_mmap) {
                                p[i] = c;
                        } else if (pwrite(fd, &c, 1, i) != 1) {
                                printf("write failed at %d\n", i);
                        }
                }
                if (unlock_range(fd, i, 1) != 0) {
                        printf("unlock at %d failed! - %s\n",
                               i, strerror(errno));
                }
                i = (i+1) % num_locks;
                count++;
                if (loops > num_locks && incr != last_incr) {
                        last_incr = incr;
                        printf("data increment = %u\n", incr);
                        fflush(stdout);
                }
                if (end_timer() > 1.0) {
                        printf("%8u locks/sec\r",
                               (unsigned)(2*count/end_timer()));
                        fflush(stdout);
                        start_timer();
                        count=0;
                }
                loops++;
        }
}

int
check_options_valid (char *data, int *value)
{
        int  ret  = 0;
	int len = 0;
	int i   = 0;
	char *endptr, *str;
	int old_errno;
	long  val = -1;

        old_errno = errno;
        errno = 0;
        str = data;

        val = strtol (str, &endptr, 10);
        /* Check for various possible errors */
        if ((errno == ERANGE && (val == LONG_MAX || val == LONG_MIN))
            || (errno != 0)) {
                fprintf (stderr, "%s", strerror (errno));
                ret = -1;
                goto out;
        }

        if (endptr == str) {
                fprintf(stderr, "No digits were found\n");
                ret = -1;
                goto out;
        }

        /* Not necessarily an error... */
        if (*endptr != '\0') {
                printf("Further characters after number: %s\n", endptr);
                ret = -1;
                goto out;
        }

        *value = val;
        ret = 0;
out:
        return ret;
}

int main(int argc, char *argv[])
{
        char *fname;
        int fd, num_locks, num_threads;
        int c;
        file_info_t *info_file = NULL;
        int zzzz = 600;
        int  ret  = 0;
        int   i   = 0;

        num_threads = 1;

        while ((c = getopt(argc, argv, "rwm")) != -1) {
                switch (c){
                case 'w':
                        do_writes = 1;
                        break;
                case 'r':
                        do_reads = 1;
                        break;
                case 'm':
                        use_mmap = 1;
                        break;
                default:
                        fprintf(stderr, "Unknown option '%c'\n", c);
                        exit(1);
                }
        }

        argv += optind;
        argc -= optind;

        if (argc < 2) {
                printf("ping_pong [options] <file> <num_locks> [num_threads] [run_time]\n");
                printf("           -r    do reads\n");
                printf("           -w    do writes\n");
                printf("           -m    use mmap\n");
                exit(1);
        }

        fname = argv[0];

        ret = check_options_valid (argv[1], &num_locks);
        if (ret < 0)
                return ret;

	if (argv[2]) {
                ret = check_options_valid (argv[2], &num_threads);
                if (ret < 0)
                        return ret;
        }

        if (argv[3]) {
                ret = check_options_valid (argv[3], &zzzz);
                if (ret < 0)
                        return ret;
        }

        if (num_threads <= 0) {
                fprintf (stderr, "number of threads cannot be -ve. Defaulting to 1\n");
                num_threads = 1;
        }

        if (num_threads >= num_locks) {
                fprintf (stderr, "number of threads (%d) should be lesser than"
                         " the number of locks (%d)\n", num_threads, num_locks);
                return -1;
        }

        if (zzzz < 0) {
                fprintf (stderr, "Cannot sleep for -ve seconds. Defaulting to 600\n");
                zzzz = 600;
        }

        pthread_t thread[num_threads];
        int       tid[num_threads];

        fd = open(fname, O_CREAT|O_RDWR, 0600);
        if (fd == -1) exit(1);

        info_file = calloc (1, sizeof (*info_file));
        if (!info_file) {
                ret = -1;
                goto out;
        }

        info_file->fd = fd;
        info_file->num_locks = num_locks;

	printf ("num_locks: %d, num_threads: %d, time: %d\n",
		num_locks, num_threads, zzzz);
        sleep (1);

        for (i = 0; i < num_threads ; i++) {
                tid[i] = pthread_create (&thread[i], NULL, (void *)ping_pong, (void *)info_file);
        }

	if (zzzz == 0) {
	        printf ("running indefinitely\n");
		for (i = 0; i < num_threads; i++)
		     pthread_join (thread[i], NULL);
		goto out;
	}

        sleep (zzzz);

 out:
        return ret;
}
