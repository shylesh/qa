#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#define UNIT_KB 1024ULL
#define UNIT_MB UNIT_KB*1024ULL
#define UNIT_GB UNIT_MB*1024ULL
#define UNIT_TB UNIT_GB*1024ULL
#define UNIT_PB UNIT_TB*1024ULL

#define UNIT_KB_STRING    "KB"
#define UNIT_MB_STRING    "MB"
#define UNIT_GB_STRING    "GB"
#define UNIT_TB_STRING    "TB"
#define UNIT_PB_STRING    "PB"

int
string2bytesize (const char *str, unsigned long long *n)
{
        unsigned long long value = 0ULL;
        char *tail = NULL;
        int old_errno = 0;
        const char *s = NULL;

        if (str == NULL || n == NULL)
        {
                errno = EINVAL;
                return -1;
        }

        for (s = str; *s != '\0'; s++)
        {
                if (isspace (*s))
                {
                        continue;
                }
                if (*s == '-')
                {
                        return -1;
                }
                break;
        }

        old_errno = errno;
        errno = 0;
        value = strtoull (str, &tail, 10);

        if (errno == ERANGE || errno == EINVAL)
        {
                return -1;
        }

        if (errno == 0)
        {
                errno = old_errno;
        }

        if (tail[0] != '\0')
        {
                if (strcasecmp (tail, UNIT_KB_STRING) == 0)
                {
                        value *= UNIT_KB;
                }
                else if (strcasecmp (tail, UNIT_MB_STRING) == 0)
                {
                        value *= UNIT_MB;
                }
                else if (strcasecmp (tail, UNIT_GB_STRING) == 0)
                {
                        value *= UNIT_GB;
                }
                else if (strcasecmp (tail, UNIT_TB_STRING) == 0)
                {
                        value *= UNIT_TB;
                }
                else if (strcasecmp (tail, UNIT_PB_STRING) == 0)
                {
                        value *= UNIT_PB;
                }

                else
                {
                        return -1;
                }
        }

        *n = value;

        return 0;
}

int main (int argc, char *argv[])
{
        int ret = -1;
        int fd  = -1;
        char  *buf = "This is a string";
        char  *filename = NULL;
        unsigned long long size = 0;

        if (argc < 2) {
                fprintf (stderr, "Usage:./a.out <filename>\n");
                return 2;
        }

        filename = argv[1];

        fd = open (filename, O_CREAT|O_RDWR, 0644);
        if (fd == -1) {
                fprintf (stderr, "OPEN: cannot open the file fff. (%s)",
                         strerror (errno));
                return 2;
        }

	if (argc < 3)
	        size = 5 * UNIT_GB;
	else
	        string2bytesize (argv[2], &size);

        ret = ftruncate (fd, size);
        if (ret == -1) {
                fprintf (stderr, "TRUNCATE: cannot truncate the file %s. (%s)",
                         filename, strerror (errno));
                goto out;
        }

        printf ("File got truncated tp %llu bytes. Sleeping for 22 seconds. "
                "Kill the brick.....\n", size);

        sleep (22);

        ret = lseek (fd, 1048576, SEEK_SET);
        if (ret == -1) {
                fprintf (stderr, "LSEEK: cannot seek to the offset file fff. "
                         "(%s)", strerror (errno));
                goto out;
        }

        ret = write (fd, buf, strlen (buf));
        if (ret == -1) {
                fprintf (stderr, "WRITE: cannot write to the  file fff. (%s)",
                         strerror (errno));
                goto out;
        }

        ret = 0;
out:
        if (fd)
                close (fd);

        return ret;
}
