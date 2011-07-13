#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/resource.h>

double timeval_elapsed(struct timeval *tv1, struct timeval *tv2);

double timeval_elapsed(struct timeval *tv1, struct timeval *tv2)
{
  return (tv2->tv_sec - tv1->tv_sec)+
    (tv2->tv_usec - tv1->tv_usec) * 1.0e-6;
}

/* This function sets the limit on maximum number of open files. By default it is set to 1024.This function raises that limit*/

int ulimit_unlimited()
{
  int err = 0;
  int ret = 0;
  struct rlimit lim;
  lim.rlim_cur = 1048576;
  lim.rlim_max = 1048576;

  if ( setrlimit(RLIMIT_NOFILE, &lim) == -1 ) {
    err = errno;
    ret = -1;
    fprintf(stderr,"%s:ulimit -n error\n",
	    strerror(errno));
    goto out;
  }

 out:
  return ret;
}

int create_block_special_file(char *dir, int n)
{

  int mknod_ret;
  int err;
  struct timeval before, after;
  double create;
  dev_t dev;
  char name[4096];
  char remove_name[4096];
  int i;
  
  gettimeofday(&before,NULL);
  
  for ( i = 0; i < n; i++ ) {
    sprintf(name,"%s/%s.%d", dir, "dev", i);
    dev = makedev(2,2    );  /* creates a device with given major and minor numbers and returns a structure of type dev_t */
    mknod_ret = mknod(name,S_IFBLK|0644,dev);

    if(mknod_ret) {
      err = errno;
      fprintf(stderr,"%s:Creating device file %s failed\n",
	    strerror(errno),name);
      exit(err);
    } 
  }
  
  gettimeofday(&after,NULL);
  
  create = timeval_elapsed(&before,&after) * 1e6 / n;
  printf("Time to create block device special file is %.01f us\n",create);
  
  for ( i = 0; i < n; i++ ) {
    sprintf(remove_name,"%s/%s.%d", dir, "dev", i);
    unlink(remove_name);
  }
  return 0;

}
    

int create_directory(char *dirname, int n)
{
  char name[4096];
  char rmdir_name[4096];
  double create;
  int makedir_ret;
  int err;
  int i;
  struct timeval before, after;
  
  gettimeofday(&before,NULL);
  
  for ( i = 1; i < n; i++ ) {
    sprintf(name,"%s/%s.%d", dirname, "dir", i);
    makedir_ret = mkdir(name,0755);
    if (makedir_ret == -1) {
      err = errno;
      fprintf(stderr,"%s:creating directory %s  created error\n",
	      strerror(errno),name);
      exit(err);
    }
    
  }
    
  gettimeofday(&after,NULL);

  create = timeval_elapsed(&before,&after) * 1e6 / n;
  printf("Time to create directory is %.01f us\n",create);
  
  for ( i = 0; i < n; i++) {
    sprintf(rmdir_name,"%s/%s.%d", dirname, "dir", i);
    rmdir(rmdir_name);
  }
  
  return 0;

}

int create_character_special_file(char *dir, int n)
{
  int mknod_ret;
  int err;
  struct timeval before, after;
  double create;
  dev_t dev;
  char name[4096];
  char remove_name[4096];
  int i;
  
  gettimeofday(&before,NULL);
  
  for ( i = 0; i < n; i++ ) {
    sprintf(name,"%s/%s.%d", dir, "chr", i);
    dev = makedev(2,2);  /* creates a device with given major and minor numbers and returns a structure of type dev_t */
    mknod_ret = mknod(name,S_IFCHR|0644,dev);

    if(mknod_ret) {
      err = errno;
      fprintf(stderr,"%s:Creating device file %s failed\n",
	    strerror(errno),name);
      exit(err);
    } 
    
  }
  
  gettimeofday(&after,NULL);
  
  create = timeval_elapsed(&before,&after) * 1e6 / n;
  printf("Time to create character special file is %.01f us\n",create);
  
  for ( i = 0; i < n; i++ ) {
    sprintf(remove_name,"%s/%s.%d", dir, "chr", i);
    unlink(remove_name);
  }
  
  return 0;

}

int create_pipe(char *dirname, int n)
{
  struct timeval before,after;
  char pipe_name[4096];
  char remove_pipe[4096];
  int err = 0;
  double create_pipe;
  int i;
  int ret;
  
  gettimeofday(&before,NULL);
  
  for ( i  = 0; i  < n ; i++) {
    sprintf(pipe_name,"%s/%s.%d", dirname, "pipe", i);
    ret = mkfifo(pipe_name, 0644);
    if ( ret == -1 ) {
      err = errno;
      fprintf(stderr,"%s:Creating pipe %s caused error\n",
	      strerror(errno),pipe_name);
      exit(err);
    }
  }

  gettimeofday(&after,NULL);
  
  create_pipe = timeval_elapsed(&before,&after) * 1e6 / n;
  printf("Time to create a pipe is %.01f us\n", create_pipe);
 
  for ( i = 0; i < n; i++) {
      sprintf(pipe_name,"%s/%s.%d", dirname, "pipe", i);
      unlink(pipe_name);
    }
  
  return 0;
}

int create_regular_file(char *dirname, int n)
{
  struct timeval before,after;
  char file_name[4096];
  char remove_file[4096];
  int err = 0;
  double create_file;
  int i;
  int ret;
  
  gettimeofday(&before,NULL);
  
  for ( i  = 0; i  < n ; i++) {
    sprintf(file_name,"%s/%s.%d", dirname, "file", i);
    ret = open(file_name, O_CREAT|O_RDWR,0600);
    if ( ret == -1 ) {
      err = errno;
      fprintf(stderr,"%s:Creating file %s caused error\n",
	      strerror(errno),file_name);
      exit(err);
    }
  }
  
  gettimeofday(&after,NULL);
  
  create_file = timeval_elapsed(&before,&after) * 1e6 / n;
  printf("Time to create a regular file is %.01f us\n", create_file);
 
  for ( i = 0; i < n; i++) {
      sprintf(file_name,"%s/%s.%d", dirname, "file", i);
      unlink(file_name);
    }
  
  return 0;
}


int main(int argc, char **argv)
{
  //char *pathname = "special_file";
  int err;
  int num = 1000;
  char *dir = ".";
  char *dirname = "block_dir";
  char *dirname_char = "char_dir";
  char *dirname_pipe = "pipe_dir";
  char *dirname_regular_file = "file_dir";
  char *entries_dir_path;  

  if(argv[1])
    num = atoi(argv[1]);
  
  printf("%d\n",num);
  if ( ulimit_unlimited() == -1 ) {
    fprintf(stderr, "%s:ulimit failed going with default value, Setting %d to 1000\n",
	    strerror(errno),num);
    num = 1000;
  }
  /* Creating 1000 block special files and calculating the time needed for it */
  entries_dir_path = getcwd(entries_dir_path,255);
  mkdir (dirname,0755);
  strcat(entries_dir_path,dirname);
  create_block_special_file(dirname,num);
  rmdir(dirname);

  /* Creating 1000 cgaracter special files and calculating the time needed for it */
  entries_dir_path = getcwd(entries_dir_path,255);
  mkdir (dirname_char,0755); 
  strcat(entries_dir_path,dirname_char);
  create_character_special_file(dirname_char,num);
  rmdir(dirname_char);

  /*Creating 1000 directories and calculating the time needed for it */
  create_directory(dir,num);

  /* Creating 1000 files and calculating the time needed for it */
  entries_dir_path = getcwd(entries_dir_path,255);
  mkdir (dirname_pipe,0755); 
  strcat(entries_dir_path,dirname_pipe);
  create_pipe(dirname_pipe,num);
  rmdir(dirname_pipe);

  /* Creating 1000 regular files and calculating the time needed for it */
  entries_dir_path = getcwd(entries_dir_path,255);
  mkdir (dirname_regular_file,0755); 
  strcat(entries_dir_path,dirname_regular_file);
  create_regular_file(dirname_regular_file,num);
  rmdir(dirname_regular_file);
  
  return 0;
}

