
#include "thread_read_fstat.h"

main()
{
        int ret = -1;
        pthread_t thread1, thread2, thread3, thread4, thread5, thread6, thread7;
        char *message1 = "Thread 1";
        char *message2 = "Thread 2";
        char *message3 = "Thread 3";
        char *message4 = "Thread 4";
        char *message5 = "Thread 5";
        char *message6 = "Thread 6";
        char *message7 = "Thread 7";

        int  iret1, iret2, iter3, iter4, iter5, iter6, iter7;

        open_t *file = NULL;
        file = (open_t *)calloc(1,sizeof(*file));
        if (!file) {
                fprintf (stderr, "%s:out of memory\n",
                         strerror(errno));
                goto out;
        }

        file->filename = "thread_file";
        file->flags = O_CREAT | O_RDWR;
        file->mode = 0755;

        fstat_t *inode;
        inode = (fstat_t *)calloc(1,sizeof(*inode));
        if (!inode) {
                fprintf (stderr, "%s:out of memory\n",
                         strerror(errno));
                goto out;
        }

        inode->buf = (struct stat *)calloc(1,sizeof(struct stat));
        if (!inode->buf) {
                fprintf (stderr, "%s:Out of memory\n",
                         strerror(errno));
                goto out;
        }

        int fd_main = -1;

        oft *both;
        both = (oft *)calloc(1,sizeof(*both));
        if (!both) {
                fprintf (stderr, "%s:out of memory\n",
                         strerror(errno));
                goto out;
        }
        /* Create independent threads each of which will execute function */

        both->open = file;
        both->fstat = inode;
        iret1 = pthread_create (&thread1, NULL, (void *)open_thread, (void *) both);
        iret2 = pthread_create (&thread2, NULL, (void *)fstat_thread, (void *) both);
        iter3 = pthread_create (&thread3, NULL, (void *)read_thread, (void *)both);
        iter4 = pthread_create (&thread4, NULL, (void *)write_truncate_thread, (void *)both);
        iter5 = pthread_create (&thread5, NULL, (void *)chown_thread, (void *)both);
        iter6 = pthread_create (&thread6, NULL, (void *)write_truncate_thread, (void *)both);
        iter7 = pthread_create (&thread7, NULL, (void *)open_lock_close, (void *)both);

        /* Wait till threads are complete before main continues. Unless we  */
        /* wait we run the risk of executing an exit which will terminate   */
        /* the process and all threads before the threads have completed.   */

        pthread_join( thread1, NULL);
        pthread_join( thread2, NULL);
        pthread_join( thread3, NULL);
        pthread_join( thread4, NULL);
        pthread_join( thread5, NULL);
        pthread_join( thread6, NULL);
        pthread_join( thread7, NULL);

        printf ("%d\n", iret1);
        printf ("%d\n", iret2);
        printf ("%d\n", iter3);
        printf ("%d\n", iter4);
        printf ("%d\n", iter5);
        printf ("%d\n", iter6);
        printf ("%d\n", iter7);

        ret = 0;
out:
        if (both)
                free(both);
        if (inode->buf)
                free (inode->buf);
        if (inode)
                free (inode);
        if (file)
                free (file);

        return ret;
}

void
open_lock_close (void *tmp)
{
        oft *all = (oft *)tmp;
        open_t *file = NULL;
        file = all->open;
        fstat_t *inode = NULL;
        inode = all->fstat;
        int ret = 0;
        int fd = -1;
        struct flock lock;
        char *data = "This is a line";

        while (1) {
                fd = open (file->filename, file->flags, file->mode);
                if (fd == -1) {
                        fprintf (stderr, "%s=>Error: cannot open the file %s "
                                 "(%s)\n", __FUNCTION__, file->filename,
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
                        fprintf (stderr, "Error: cannot lock the file %s (%s)\n",
                                 file->filename, strerror (errno));

                ret = flock (fd, LOCK_SH);
                if (ret == -1)
                        fprintf (stderr, "Error: cannot flock the file %s (%s)\n",
                                 file->filename, strerror (errno));

                ret = write (fd, data, strlen (data));
                if (ret == -1)
                        fprintf (stderr, "Error: cannot write the file %s (%s)\n",
                                 file->filename, strerror (errno));

                lock.l_type = F_UNLCK;
                ret = fcntl (fd, F_SETLK, &lock);
                if (ret == -1)
                        fprintf (stderr, "Error: cannot unlock the file %s"
                                " (%s)\n", file->filename, strerror (errno));

                ret = flock (fd, LOCK_UN);
                if (ret == -1)
                        fprintf (stderr, "Error: cannot unlock the flock on "
                                 "the file %s (%s)\n", file->filename,
                                 strerror (errno));

                close (fd);
        }

        return;
}

int
open_thread(void *tmp)
{
        oft *all = (oft *)tmp;
        open_t *file = NULL;
        file = all->open;
        fstat_t *inode = NULL;
        inode = all->fstat;
        int ret = 0;
        int fd = -1;

        while (1) {
                if (fd = open (file->filename, file->flags, file->mode) == -1) {
                        fprintf(stderr, "%s:open error (%s)\n", __FUNCTION__,
                                strerror(errno));
                        ret = -1;
                        goto out;
                }

                close (fd);
        }
out:
        if (file)
                free(file);
        return ret;
}

int
fstat_thread(void *ptr)
{
        oft *all = (oft *)ptr;
        fstat_t *inode = NULL;
        open_t *file = NULL;
        int ret = 0;
        int fd = -1;

        file = all->open;
        inode = all->fstat;

        fd = open (file->filename, file->flags, file->mode);
        if (fd == -1) {
                fprintf (stderr, "%s: open error (%s)\n", __FUNCTION__,
                         strerror (errno));
                ret = -1;
                goto out;
        }

        while (1) {
                if (fstat(fd, inode->buf) == -1) {
                        fprintf (stderr, "%s:fstat error\n",
                                 strerror(errno));
                        ret = -1;
                        goto out;
                }
        }

out:

        close (fd);
        if (inode->buf)
                free (inode->buf);
        if (inode)
                free(inode);
        return ret;
}

int
read_thread (void *ptr)
{
        oft *all = NULL;
        int fd = -1;
        int ret = -1;
        fstat_t *stat = NULL;
        open_t *file = NULL;
        char buffer[4096];

        all = (oft *)ptr;
        stat = all->fstat;
        file = all->open;

        open_validate_error_goto(file->filename, file->flags, file->mode);

        while (1) {
                ret = read (fd, buffer, 22);
                if (ret == -1) {
                        fprintf (stderr, "%s: read error\n", strerror (errno));
                        goto out;
                }

                if (ret == EOF) {
                        lseek (fd, 0, SEEK_SET);
                }
        }

        ret = 0;
out:
        close (fd);
        return ret;
}

int
write_truncate_thread (void *ptr)
{
        oft *all = NULL;
        open_t *file = NULL;
        fstat_t *stat = NULL;
        int fd = -1;
        int ret = -1;
        char *buffer = "This is a multithreaded environment";
        unsigned int data = 0;
        int bytes_written = -1;

        all = (oft *)ptr;
        file = all->open;
        stat = all->fstat;

        fd = open (file->filename, file->flags | O_APPEND, file->mode);
        if (fd == -1) {
                fprintf (stderr, "%s: open error (%s)\n", __FUNCTION__,
                         strerror (errno));
                ret = -1;
                goto out;
        }

        while (1) {
                ret = write (fd, buffer, strlen (buffer));
                bytes_written = ret;
                if (ret == -1) {
                        fprintf (stderr, "%s: write error\n", strerror (errno));
                        goto out;
                }

                if ((data + bytes_written) >= 4096) {
                        ret = ftruncate (fd, 0);
                        if (ret == -1) {
                                fprintf (stderr, "%s: truncate error\n",
                                         strerror (errno));
                                goto out;
                        }

                        data = 0;
                } else
                        data = data + bytes_written;
        }

out:
        close (fd);
        return ret;
}

int
chown_thread (void *ptr)
{
        oft *all = NULL;
        fstat_t *stat = NULL;
        open_t *file = NULL;
        int ret = -1;
        int fd = -1;
        struct stat stat_buf;

        all = (oft *)ptr;
        stat = all->fstat;
        file = all->open;

        open_validate_error_goto(file->filename, file->flags, file->mode);

        while (1) {
                ret = fstat (fd, &stat_buf);
                if (ret == -1) {
                        fprintf (stderr, "%s: fstat error.(%s)",
                                 strerror (errno), __FUNCTION__);
                        goto out;
                }

                if (stat_buf.st_uid == 1315 && stat_buf.st_gid == 1315) 
                        ret = fchown (fd, 2222, 2222);
                else
                        ret = fchown (fd, 1315, 1315);

                if (ret == -1) {
                        fprintf (stderr, "%s: chown error\n", strerror (errno));
                        goto out;
                }
        }

        ret = 0;
out:
        close (fd);
        return ret;
}
