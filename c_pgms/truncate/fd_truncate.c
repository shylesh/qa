#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <fcntl.h>

int main ()
{
        int     ret = -1;
        int     fd  = -1;
        char   *str = "This is a string";
        char    pwd[255] = {0, };

        fd = open ("test_file", O_RDWR);
        if (fd == -1) {
                       fprintf (stderr, "ERROR: open failed on the file test_file (%s)",
                        strerror (errno));
        }
        ret = ftruncate (fd, 10);
        if (ret == -1) {
                fprintf (stderr, "ERROR: truncate failed on the file %s (%s)",
                         pwd, strerror (errno));
        }

        if (fd > 0)
                close (fd);
}
