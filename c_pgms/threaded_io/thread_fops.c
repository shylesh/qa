
#include "thread_fops.h"

static error_t
thread_parse_opts (int key, char *arg,
                   struct argp_state *_state);
static void
thread_default_config (void);

static thread_config_t thread_config;

static struct argp_option thread_options[] = {
        { "dir", 'd', "DIRECTORY", 0, "absolute or relative path of the tests"},
        { "time", 't', "TIME", 0, "time duration for which test should run"
          " (defaults to 600 seconds)"},
        {0, 0, 0, 0, 0}
};

static error_t
thread_parse_opts (int key, char *arg,
            struct argp_state *_state)
{
        switch (key) {
        case 'd':
        {
                int len = 0;
                int pathlen = 0;
                int ret = -1;
                int old_errno = 0;
                struct stat stbuf = {0,};

                len = strlen (arg) + strlen ("playground");
                if (len > UNIX_PATH_MAX) {
                        fprintf (stderr, "pathname is too long (%s)\n",
                                 arg);
                        return -1;
                }

                strcpy (thread_config.directory, arg);
                pathlen = strlen (thread_config.directory);
                if (thread_config.directory[pathlen - 1] != '/')
                        thread_config.directory[pathlen] = '/';
                thread_config.directory[pathlen+1] = '\0';

                old_errno = errno;
                errno = 0;
                ret = stat (thread_config.directory, &stbuf);
                if ((ret == -1) || !S_ISDIR (stbuf.st_mode)) {
                        if (errno == ENOENT) {
                                fprintf (stderr, "the directory %s does not "
                                         "exist\n", thread_config.directory);
                                return -1;
                        } else {
                                fprintf (stderr, "given path %s is not a "
                                         "directory\n",
                                         thread_config.directory);
                                return -1;
                        }
                }
                strcat (thread_config.directory, "playground");
                errno = old_errno;
        }
        break;

        case 't':
        {
                long long  time = 0;
                char       *tail = NULL;

                errno = 0;
                time = strtoll (arg, &tail, 10);
                if (errno == ERANGE || errno == EINVAL) {
                        fprintf (stderr, "invalid time (%s)\n", arg);
                        return -1;
                }

                if (tail[0] != '\0') {
                        fprintf (stderr, "invalid time (%s)\n", arg);
                        return -1;
                }

                if (time < 0) {
                        fprintf (stderr, "time (%s) cannot be -ve\n", arg);
                        return -1;
                }

                thread_config.time = time;
        }
        break;

        case ARGP_KEY_NO_ARGS:
                break;
        case ARGP_KEY_ARG:
                break;
        case ARGP_KEY_END:
                if (_state->argc == 1) {
                        //argp_usage (_state);
                        thread_default_config ();
                }

        }

        return 0;
}

static struct argp argp = {
        thread_options,
        thread_parse_opts,
        "",
        "threaded-io - tool which spawns multiple threads, with each thread "
        "opening the same file and doing different fops on their respective "
        "fds"
};

static void
thread_default_config (void)
{
        int ret = -1;
        char playground[UNIX_PATH_MAX] = {0,};
        struct stat stbuf = {0,};

        getcwd (playground, sizeof (playground));

        ret = stat (playground, &stbuf);
        if (ret == -1) {
                fprintf (stderr, "Error: %s: The playground directory %s "
                         "seems to have an error (%s)", __FUNCTION__,
                         playground, strerror (errno));
                return;
        }

        strcat (playground, "/playground");
        strcpy (thread_config.directory, playground);

        thread_config.time = 600;
}

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

        thread_default_config ();

        ret = argp_parse (&argp, argc, argv, 0, 0, NULL);
        if (ret != 0) {
                ret = -1;
                fprintf (stderr, "%s: argp_parse() failed\n", argv[0]);
                goto err;
        }

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

        fstat_t *inode = NULL;
        inode = (fstat_t *)calloc(1,sizeof(*inode));
        if (!inode) {
                fprintf (stderr, "%s:out of memory\n",
                         strerror(errno));
                goto out;
        }

        inode->buf = NULL;
        inode->buf = (struct stat *)calloc(1,sizeof(struct stat));
        if (!inode->buf) {
                fprintf (stderr, "%s:Out of memory\n",
                         strerror(errno));
                goto out;
        }

        int fd_main = -1;

        oft *both = NULL;
        both = (oft *)calloc(1,sizeof(*both));
        if (!both) {
                fprintf (stderr, "%s:out of memory\n",
                         strerror(errno));
                goto out;
        }

        strcpy (playground, thread_config.directory);

        ret = mkdir (playground, 0755);
        if (ret == -1 && (errno != EEXIST) ) {
                fprintf (stderr, "Error: Error creating the playground ",
                         ": %s (%s)", playground, __FUNCTION__,
                         strerror (errno));
                goto out;
        }

        printf ("Switching over to the working directory %s time %llu\n",
                playground, thread_config.time);
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

        sleep (thread_config.time);

        printf ("Total Statistics ======>\n");
        printf ("Opens        : %llu/%llu\n", info.num_open_success,info.num_open);
        printf ("Reads        : %llu/%llu\n", info.read_success, info.read);
        printf ("Writes       : %llu/%llu\n", info.write_success, info.write);
        printf ("Flocks       : %llu/%llu\n", info.flocks_success, info.flocks);
        printf ("fcntl locks  : %llu/%llu\n", info.fcntl_locks_success,
                info.fcntl_locks);
        printf ("Truncates    : %llu/%llu\n", info.truncate_success, info.truncate);
        printf ("Fstat        : %llu/%llu\n", info.fstat_success, info.fstat);
        printf ("Chown        : %llu/%llu\n", info.chown_success, info.chown);
        printf ("Opendir      : %llu/%llu\n", info.opendir_success, info.opendir);
        printf ("Readdir      : %llu/%llu\n", info.readdir_success, info.readdir);

        ret = 0;
out:
        if (file) {
                free (file);
                file = NULL;
        }
        if (inode) {
                if (inode->buf) {
                        free (inode->buf);
                        inode->buf = NULL;
                }
                free (inode);
                inode = NULL;
        }
        if (both) {
                both->open = NULL;
                both->fstat = NULL;
                free(both);
                both = NULL;
        }

        pthread_mutex_destroy (&info.mutex);

err:
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
