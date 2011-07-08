/*
   gcc index.c -o index -Wall -g
   ./index &
   ./index &
   ./index &

   abort()s on failure, runs forever on non-failure
*/
#define _XOPEN_SOURCE 500 /* for pread() */
#define _BSD_SOURCE /* for major(), minor() */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>

struct mail_index {
	const char *filepath;
	int fd;
	int log_fd;
};

struct mail_index_header {
	/* major version is increased only when you can't have backwards
	   compatibility. minor version is increased when header size is
	   increased to contain new non-critical fields. */
	uint8_t major_version;
	uint8_t minor_version;

	uint16_t base_header_size;
	uint32_t header_size; /* base + extended header size */
	uint32_t record_size;

	uint8_t compat_flags; /* enum mail_index_header_compat_flags */
	uint8_t unused[3];

	uint32_t indexid;
	uint32_t flags;

	uint32_t uid_validity;
	uint32_t next_uid;

	uint32_t messages_count;
	uint32_t unused_old_recent_messages_count;
	uint32_t seen_messages_count;
	uint32_t deleted_messages_count;

	uint32_t first_recent_uid;
	/* these UIDs may not exist and may not even be unseen/deleted */
	uint32_t first_unseen_uid_lowwater;
	uint32_t first_deleted_uid_lowwater;

	uint32_t log_file_seq;
	/* non-external records between tail..head haven't been committed to
	   mailbox yet. */
	uint32_t log_file_tail_offset;
	uint32_t log_file_head_offset;

	uint64_t sync_size;
	uint32_t sync_stamp;

	/* daily first UIDs that have been added to index. */
	uint32_t day_stamp;
	uint32_t day_first_uid[8];
};

struct mail_index_record {
	uint32_t uid;
	uint8_t flags; /* enum mail_flags | enum mail_index_mail_flags */
};
int mail_index_try_open_only(struct mail_index *index)
{
	index->fd = open(index->filepath, O_RDWR);
	if (index->fd == -1) {
		if (errno != ENOENT)
			abort();

		/* have to create it */
		return 0;
	}
	return 1;
}

void mail_index_close_file(struct mail_index *index)
{
	if (index->fd != -1) {
		if (close(index->fd) < 0)
			abort();
		index->fd = -1;
	}
}

int mail_index_reopen_if_changed(struct mail_index *index)
{
	struct stat st1, st2;

	if (index->fd == -1)
		return mail_index_try_open_only(index);

	//nfs_flush_file_handle_cache(index->filepath);
	if (stat(index->filepath, &st2) < 0)
		abort();

#define CMP_DEV_T(a, b) (major(a) == major(b) && minor(a) == minor(b))
	if (fstat(index->fd, &st1) < 0) {
		abort();
	} else if (st1.st_ino == st2.st_ino &&
		   CMP_DEV_T(st1.st_dev, st2.st_dev)) {
		/* the same file */
		return 1;
	}

	/* new file */
	mail_index_close_file(index);
	return mail_index_try_open_only(index);
}

static int mail_index_read_header(struct mail_index *index,
				  void *buf, size_t buf_size, size_t *pos_r)
{
	size_t pos;
	int ret;

	memset(buf, 0, sizeof(struct mail_index_header));

        pos = 0;
	do {
		ret = pread(index->fd, (char*)buf + pos,
			    buf_size - pos, pos);
		if (ret <= 0)
			abort();
		if (ret > 0)
			pos += ret;
	} while (ret > 0 && pos < sizeof(struct mail_index_header));

	*pos_r = pos;
	return ret;
}

static int
mail_index_read_map(struct mail_index *index, off_t file_size)
{
	const struct mail_index_header *hdr;
	unsigned char read_buf[8192];
	const void *buf;
	ssize_t ret;
	size_t pos, records_size;
	unsigned int records_count = 0, extra;

	ret = mail_index_read_header(index, read_buf, sizeof(read_buf), &pos);
	buf = read_buf; hdr = buf;

	if (ret > 0) {
		/* header read, read the records now. */
		records_size = (size_t)hdr->messages_count * hdr->record_size;
		records_count = hdr->messages_count;

		if (file_size - hdr->header_size < records_size ||
		    (hdr->record_size != 0 &&
		     records_size / hdr->record_size != hdr->messages_count))
			abort();

		if (pos <= hdr->header_size)
			extra = 0;
		else
			extra = pos - hdr->header_size;
		if (records_size > extra) {
			void *data = malloc(records_size - extra);
			ret = pread(index->fd, data, records_size - extra,
				    hdr->header_size + extra);
			if (ret != records_size - extra) abort();
			free(data);
		}
	}
	return 1;
}

static int file_lock_do(int fd, int lock_type, int timeout_secs)
{
	struct flock fl;
	int ret;

	fl.l_type = lock_type;
	fl.l_whence = SEEK_SET;
	fl.l_start = 0;
	fl.l_len = 0;

	if (timeout_secs != 0)
		alarm(timeout_secs);
	ret = fcntl(fd, timeout_secs != 0 ? F_SETLKW : F_SETLK, &fl);
	if (timeout_secs != 0)
		alarm(0);

	if (ret == 0)
		return 1;

	if (timeout_secs == 0 &&
	    (errno == EACCES || errno == EAGAIN)) {
		/* locked by another process */
		return 0;
	}
	abort();
}

static int mail_index_map_latest_file(struct mail_index *index)
{
	struct stat st;
	off_t file_size;
	int ret;

	ret = mail_index_reopen_if_changed(index);
	if (ret <= 0) {
		if (ret < 0)
			return -1;

		/* the index file is lost/broken. */
		return 1;
	}

	if (file_lock_do(index->fd, F_RDLCK, 120) == 0) abort();

	//nfs_flush_attr_cache_fd_locked(index->filepath, index->fd);
	if (fstat(index->fd, &st) < 0)
		abort();
	file_size = st.st_size;

	ret = mail_index_read_map(index, file_size);
	if (file_lock_do(index->fd, F_UNLCK, 0) == 0) abort();
	return 1;
}

static int mail_index_create_backup(struct mail_index *index)
{
	char backup_path[1024], tmp_backup_path[1024];
	int ret;

	snprintf(backup_path, sizeof(backup_path), "%s.backup", index->filepath);
	snprintf(tmp_backup_path, sizeof(tmp_backup_path), "%s.tmp", backup_path);
	ret = link(index->filepath, tmp_backup_path);
	if (ret < 0 && errno == EEXIST) {
		if (unlink(tmp_backup_path) < 0 && errno != ENOENT)
			abort();
		ret = link(index->filepath, tmp_backup_path);
	}
	if (ret < 0) {
		if (errno == ENOENT) {
			/* no dovecot.index file, ignore */
			return 0;
		}
		abort();
	}

	if (rename(tmp_backup_path, backup_path) < 0)
		abort();
	return 0;
}

static void mail_index_recreate(struct mail_index *index)
{
	struct mail_index_header hdr;
	struct mail_index_record *recs;
	char path[1024];
	int fd;
	unsigned int i, size;

	snprintf(path, sizeof(path), "%s.tmp", index->filepath);
	fd = open(path, O_RDWR|O_CREAT|O_TRUNC, 0600);
	if (fd == -1)
		abort();

	memset(&hdr, 0, sizeof(hdr));
	hdr.base_header_size = hdr.header_size = sizeof(hdr);
	hdr.record_size = sizeof(*recs);
	hdr.messages_count = (rand() % 10000) * 100;

	if (write(fd, &hdr, sizeof(hdr)) != sizeof(hdr)) abort();
	size = sizeof(*recs) * hdr.messages_count;
	recs = calloc(size, 1);
	for (i = 0; i < hdr.messages_count; i++)
		recs[i].uid = i + 1;
	if (write(fd, recs, size) != size) abort();
	free(recs);
	if (fdatasync(fd) < 0)
		abort();
	if (close(fd) < 0)
		abort();
	mail_index_create_backup(index);

	if (rename(path, index->filepath) < 0) {
		perror("rename()");
		abort();
	}
}

static int log_lock(struct mail_index *index)
{
	if (index->log_fd == -1) {
		index->log_fd = open("/mnt/gluster/dovecot.index.log", O_CREAT | O_RDWR, 0600);
		if (index->log_fd == -1)
			abort();
	}
	return file_lock_do(index->log_fd, F_WRLCK, 0);
}

static void log_unlock(struct mail_index *index)
{
	if (file_lock_do(index->log_fd, F_UNLCK, 0) == 0) abort();
}

int main(void)
{
	struct mail_index index;

	memset(&index, 0, sizeof(index));
	index.fd = -1;
	index.log_fd = -1;
	index.filepath = "/mnt/gluster/dovecot.index";

	for (;;) {
		if (rand() % 100 < 70)
			mail_index_map_latest_file(&index);
		else if (log_lock(&index) > 0) {
			mail_index_recreate(&index);
			log_unlock(&index);
		}
		usleep(10000);
	}
}
