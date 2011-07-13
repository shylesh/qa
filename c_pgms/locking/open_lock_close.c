#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define NUM_FILES 100000

void open_lock_close (char *name);
void delete_file (char *name);

int
main ()
{
        int ret = 0;
        char filename[256] = {0,};
        int i = 0;

        for (i = 1; i <= NUM_FILES ; i++) {
                snprintf (filename, sizeof (filename), "file-%d", i);
                open_lock_close (filename);
        }

        /* for (i = 1; i <= 100000; i++) { */
        /*         snprintf (filename, sizeof (filename), "file-%d", i); */
        /*         delete_file (filename); */
        /* } */

        return 0;
}

void
open_lock_close (char *name)
{
        int ret = 0;
        int fd = -1;
        struct flock lock;
        char *data = "This is a line";

        fd = open (name, O_CREAT|O_RDWR, 0644);
        if (fd == -1) {
                fprintf (stderr, "Error: cannot open the file %s (%s)\n", name,
                         strerror (errno));
                return;
        }

        lock.l_type = F_RDLCK;
        lock.l_whence = SEEK_SET;
        lock.l_start = 0;
        lock.l_len = 0;
        lock.l_pid = 0;

        ret = fcntl (fd, F_SETLK, &lock);
        if (ret == -1)
                fprintf (stderr, "Error: cannot lock the file %s (%s)\n", name,
                         strerror (errno));

        ret = flock (fd, LOCK_SH);
        if (ret == -1)
                fprintf (stderr, "Error: cannot flock the file %s (%s)\n", name,
                         strerror (errno));

        ret = write (fd, data, strlen (data));
        if (ret == -1)
                fprintf (stderr, "Error: cannot write the file %s (%s)\n", name,
                         strerror (errno));

        close (fd);

        return;
}

void
delete_file (char *name)
{
        int ret = 0;

        ret = unlink (name);
        if (ret < 0)
                fprintf (stderr, "Error: Cannot unlink the file %s (%s)\n",
                         name, strerror (errno));

        return;
}
