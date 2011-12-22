
#include "thread_fops.h"

int
main(int argc, char *argv[])
{
        int ret = -1;
        pthread_t thread[10];
        char *message [] = {"Thread0", "Thread1", "Thread2", "Thread3",
                            "Thread4", "Thread5", "Thread6", "Thread7",
                            "Thread8", "Thread9",};
        char playground[1024] = {0,};
        struct stat stbuf = {0,};
        int  iter[10];
        int  i = 0;

        typedef void *(*thread_pointer)(void *);
        thread_pointer pointers_thread [] = {open_thread, fstat_thread,
                                             read_thread,
                                             write_truncate_thread,
                                             chown_thread,
                                             write_truncate_thread,
                                             open_lock_close,
                                             opendir_and_readdir,
                                             opendir_and_readdir,
        };

        open_t *file = NULL;
        file = (open_t *)calloc(1,sizeof(*file));
        if (!file) {
                fprintf (stderr, "%s:out of memory\n",
                         strerror(errno));
                goto out;
        }

        file->filename = "thread_file";
        //file->dirname = "test_dir";
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

        if (argc > 1)
                strncpy (playground, argv[1], strlen (argv[1]));
        else
                getcwd (playground, sizeof (playground));

        ret = stat (playground, &stbuf);
        if (ret == -1) {
                fprintf (stderr, "Error: %s: The playground directory %s "
                         "seems to have an error (%s)", __FUNCTION__,
                         playground, strerror (errno));
                goto out;
        }

        strcat (playground, "/playground");
        ret = mkdir (playground, 0755);
        if (ret == -1 && (errno != EEXIST) ) {
                fprintf (stderr, "Error: Error creating the playground ",
                         ": %s (%s)", playground, __FUNCTION__,
                         strerror (errno));
                goto out;
        }

        printf ("Switching over to the working directory %s\n", playground);
        ret = chdir (playground);
        if (ret == -1) {
                fprintf (stderr, "Error changing directory to the playground %s",
                         ". function (%s), %s", playground, __FUNCTION__,
                         strerror (errno));
                goto out;
        }

        mkdir ("test_dir", 0755);
        pthread_mutex_init (&info.mutex, NULL);
        /* Create independent threads each of which will execute function */

        both->open = file;
        both->fstat = inode;
        for (i = 0; i <= 6; i++) {
                iter[i] = pthread_create (&thread[i], NULL, pointers_thread[i],
                                          (void *)both);
        }

        while (i < 9) {
                iter[i] = pthread_create (&thread[i], NULL, pointers_thread[i],
                                          NULL);
                i++;
        }

        sleep (600);

        printf ("Total Statistics ======>\n");
        printf ("Opens        : %d/%d\n", info.num_open_success,info.num_open);
        printf ("Reads        : %d/%d\n", info.read_success, info.read);
        printf ("Writes       : %d/%d\n", info.write_success, info.write);
        printf ("Flocks       : %d/%d\n", info.flocks_success, info.flocks);
        printf ("fcntl locks  : %d/%d\n", info.fcntl_locks_success,
                info.fcntl_locks);
        printf ("Truncates    : %d/%d\n", info.truncate_success, info.truncate);
        printf ("Fstat        : %d/%d\n", info.fstat_success, info.fstat);
        printf ("Chown        : %d/%d\n", info.chown_success, info.chown);
        printf ("Opendir      : %d/%d\n", info.opendir_success, info.opendir);
        printf ("Readdir      : %d/%d\n", info.readdir_success, info.readdir);

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

        pthread_mutex_destroy (&info.mutex);
        return ret;
}

void *
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
                        return;
                } else {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.num_open++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                }

                lock.l_type = F_RDLCK;
                lock.l_whence = SEEK_SET;
                lock.l_start = 0;
                lock.l_len = 0;
                lock.l_pid = 0;

                pthread_mutex_lock (&info.mutex);
                {
                        info.fcntl_locks++;
                }
                pthread_mutex_unlock (&info.mutex);

                ret = fcntl (fd, F_SETLK, &lock);
                if (ret == 0) {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.fcntl_locks_success++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                }

                pthread_mutex_lock (&info.mutex);
                {
                        info.flocks++;
                }
                pthread_mutex_unlock (&info.mutex);

                ret = flock (fd, LOCK_SH);
                if (ret == 0) {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.flocks_success++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                }

                pthread_mutex_lock (&info.mutex);
                {
                        info.write++;
                }
                pthread_mutex_unlock (&info.mutex);

                ret = write (fd, data, strlen (data));
                if (ret == 0) {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.write_success++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                }

                lock.l_type = F_UNLCK;
                ret = fcntl (fd, F_SETLK, &lock);

                ret = flock (fd, LOCK_UN);

                close (fd);
        }

        return NULL;
}

void *
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
                pthread_mutex_lock (&info.mutex);
                {
                        info.num_open++;
                }
                pthread_mutex_unlock (&info.mutex);

                if (fd = open (file->filename, file->flags, file->mode) == -1) {
                        ret = -1;
                        goto out;
                } else {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.num_open_success++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                }

                close (fd);
        }
out:
        if (file)
                free(file);
        return NULL;
}

void *
fstat_thread(void *ptr)
{
        oft *all = (oft *)ptr;
        fstat_t *inode = NULL;
        open_t *file = NULL;
        int ret = 0;
        int fd = -1;

        file = all->open;
        inode = all->fstat;

        pthread_mutex_lock (&info.mutex);
        {
                info.num_open++;
        }
        pthread_mutex_unlock (&info.mutex);

        fd = open (file->filename, file->flags, file->mode);
        if (fd == -1) {
                ret = -1;
                goto out;
        } else {
                pthread_mutex_lock (&info.mutex);
                {
                        info.num_open_success++;
                }
                pthread_mutex_unlock (&info.mutex);
        }

        while (1) {
                pthread_mutex_lock (&info.mutex);
                {
                        info.fstat++;
                }
                pthread_mutex_unlock (&info.mutex);

                if (fstat(fd, inode->buf) == -1) {
                        ret = -1;
                        goto out;
                } else {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.fstat_success++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                }
        }

out:

        close (fd);
        if (inode->buf)
                free (inode->buf);
        if (inode)
                free(inode);
        return NULL;
}

void *
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
                pthread_mutex_lock (&info.mutex);
                {
                        info.read++;
                }
                pthread_mutex_unlock (&info.mutex);

                ret = read (fd, buffer, 22);
                if (ret == -1) {
                        goto out;
                }

                if (ret == EOF) {
                        lseek (fd, 0, SEEK_SET);
                } else {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.read_success++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                }
        }

        ret = 0;
out:
        close (fd);
        return NULL;
}

void *
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

        pthread_mutex_lock (&info.mutex);
        {
                info.num_open++;
        }
        pthread_mutex_unlock (&info.mutex);

        fd = open (file->filename, file->flags | O_APPEND, file->mode);
        if (fd == -1) {
                ret = -1;
                goto out;
        } else {
                pthread_mutex_lock (&info.mutex);
                {
                        info.num_open_success++;
                }
                pthread_mutex_unlock (&info.mutex);
        }

        while (1) {
                pthread_mutex_lock (&info.mutex);
                {
                        info.write++;
                }
                pthread_mutex_unlock (&info.mutex);

                ret = write (fd, buffer, strlen (buffer));
                bytes_written = ret;
                if (ret == -1) {
                        goto out;
                }

                if ((data + bytes_written) >= 4096) {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.truncate++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                        ret = ftruncate (fd, 0);
                        if (ret == -1) {
                                goto out;
                        } else {
                                pthread_mutex_lock (&info.mutex);
                                {
                                        info.truncate_success++;
                                }
                                pthread_mutex_unlock (&info.mutex);
                        }
                        data = 0;
                } else {
                        data = data + bytes_written;
                         pthread_mutex_lock (&info.mutex);
                         {
                                 info.write_success++;
                         }
                         pthread_mutex_unlock (&info.mutex);
                }
        }

out:
        close (fd);
        return NULL;
}

void *
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
                pthread_mutex_lock (&info.mutex);
                {
                        info.fstat++;
                }
                pthread_mutex_unlock (&info.mutex);

                ret = fstat (fd, &stat_buf);
                if (ret == -1) {
                        goto out;
                } else {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.fstat_success++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                }

                pthread_mutex_lock (&info.mutex);
                {
                        info.chown++;
                }
                pthread_mutex_unlock (&info.mutex);
                if (stat_buf.st_uid == 1315 && stat_buf.st_gid == 1315)
                        ret = fchown (fd, 2222, 2222);
                else
                        ret = fchown (fd, 1315, 1315);

                if (ret == -1) {
                        goto out;
                } else {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.chown_success++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                }
        }

        ret = 0;
out:
        close (fd);
        return NULL;
}

void *
opendir_and_readdir ()
{
        DIR    *dir = NULL;
        char   dir_to_open[1024] = {0,};
        int    old_errno = 0;
        struct dirent *entry = NULL;

        getcwd (dir_to_open, sizeof (dir_to_open));
        while (1) {
                pthread_mutex_lock (&info.mutex);
                {
                        info.opendir++;
                }
                pthread_mutex_unlock (&info.mutex);
                dir = opendir (dir_to_open);
                if (!dir) {
                        break;
                }  else {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.opendir_success++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                }

                old_errno = errno;
                errno = 0;

                do {
                        pthread_mutex_lock (&info.mutex);
                        {
                                info.readdir++;
                        }
                        pthread_mutex_unlock (&info.mutex);
                        entry = readdir (dir);
                        if (entry) {
                                entry->d_off = telldir (dir);
                                pthread_mutex_lock (&info.mutex);
                                {
                                        info.readdir_success++;
                                }
                                pthread_mutex_unlock (&info.mutex);
                        }
                } while (entry);

                if (errno != 0)

                closedir (dir);
                dir = NULL;
        }

        return NULL;
}
