/*
Date: 	Fri, 10 Nov 2006 16:16:27 +0300
From: "Igor A. Valcov" <viaprog@gmail.com>

Date:   Tue  10 May 2011 17:28:10
From: "Raghavendra Bhat" <raghavendrambk@gmail.com>
*/

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#define __BYTES		8192
#define __FILES	        30000
#define N		30000

char	buf [__BYTES];

void open_write_sync_close (int32_t num_files, int32_t iterations);
void delete_files (char *dirname, int32_t num_files);

int main (int argc, char *argv[])
{
        int32_t num_files = 0;
        int32_t iterations = 0;
        char *tail = NULL;
        long tmp = 0;
        int  ret = -1;

        num_files = __FILES;
        iterations = N;

        if (argc > 1) {
                tmp = strtol (argv[1], &tail, 0);
                if (tmp < 0) {
                        fprintf (stderr, "number of files cannot be -ve\n");
                        goto out;
                }

                num_files = (int32_t)tmp;
                iterations = num_files;
        }

        printf ("%d\n", num_files);

        open_write_sync_close (num_files, iterations);
        ret = 0;

out:
        return ret;
}


void
open_write_sync_close (int32_t num_files, int32_t iterations)
{
        char fname[4096];
	int nFiles[num_files];
	int f, i;
        int32_t ret = -1;
        char *dirname = "sync_field";
        char *entries_path = NULL;

	/* Fill buf */
	for (i = 0; i < __BYTES; i++)
		buf [i] = i % 128;

        entries_path = getcwd (entries_path, 255); 
        strcat (entries_path, dirname);

        /* Create the directory in which test are conducted */
        ret = mkdir (dirname, 0755);
        if (ret == -1) {
                fprintf (stderr, "cannot create directory (%s)\n",
                         strerror (errno));
                goto out;
        }

	/* Create and open files */
	for (f = 0; f < num_files; f++) {
		sprintf (fname, "%s/file-%d", dirname, f);
		nFiles [f] = open(fname, O_WRONLY | O_CREAT | O_TRUNC, 0644);
                printf("\r fd [%d] = %d", f, nFiles[f]);
	}

        /* Write to the files opened */
	for (i = 0; i < iterations; i++) {
		printf("\r%d/%d	 ", i, iterations);
		fflush(stdout);
		for (f = 1; f < num_files; f++)
			write(nFiles[f], buf, __BYTES);
	}
	printf("\n");
	printf("syncing\n");

        /* sync the data */
	for (f = 0; f < num_files; f++) {
		fsync(nFiles [f]);
		close(nFiles [f]);
	}

        /* delete the files created and the directory whete tests
           are conducted */
        delete_files (dirname, num_files);
        rmdir (dirname);

out:
        return;
}

void
delete_files (char *dirname, int32_t num_files)
{
        int32_t i = -1;
        char name[4096];

        for (i = 0; i < num_files; i++) {
                snprintf (name, 4096, "%s/file-%d", dirname, i);
                unlink (name);
        }
}
