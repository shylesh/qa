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

        getcwd (pwd, sizeof (pwd));

        strcat (pwd, "/test_file");

        ret = truncate (pwd, 10);
        if (ret == -1) {
                fprintf (stderr, "ERROR: truncate failed on the file %s (%s)",
                         pwd, strerror (errno));
        }
}
