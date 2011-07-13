#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <sys/inotify.h>
/* This will watch for any new arrivals at TARGET directory and if found,it will invoke the SANITY_TEST script. */

#define TARGET "/home/raghavendrabhat/nightly_sanity"

#define MAIL "mutt -a /home/raghavendrabhat/result/logs* -s \"Sanity test for date `date +%F`\" -i /home/raghavendrabhat/nightly_sanity/tests_failed* dl-qa@gluster.com <."

void get_event (int fd, const char * target);


/* ----------------------------------------------------------------- */

int main (int argc, char *argv[])
{
   char target[FILENAME_MAX];
   int result;
   int fd;
   int wd;   /* watch descriptor */

   if (argc < 2) {
      strcpy (target,TARGET);
	
   }
   else {
      fprintf (stderr, "Watching %s\n", TARGET);
      strcpy (target, TARGET);
   }

   fd = inotify_init();
   if (fd < 0) {
      fprintf (stderr, "Error: %s\n", strerror(errno));
      return 1;
   }
   
   wd = inotify_add_watch (fd, target, IN_ALL_EVENTS);
   if (wd < 0) {
      fprintf (stderr, "Error: %s\n", strerror(errno));
      return 1;
   }
   
   daemon (0,0);
   while (1) {
      get_event(fd, target);
   }

   return 0;
}

/* ----------------------------------------------------------------- */
/* Allow for 1024 simultanious events */
#define BUFF_SIZE ((sizeof(struct inotify_event)+FILENAME_MAX)*1024)

void get_event (int fd, const char * target)
{
   ssize_t len, i = 0;
   int status;
   char action[81+FILENAME_MAX] = {0};
   char buff[BUFF_SIZE] = {0};

   len = read (fd, buff, BUFF_SIZE);
   
   while (i < len) {
      struct inotify_event *pevent = (struct inotify_event *)&buff[i];
      char action[81+FILENAME_MAX] = {0};

      if (pevent->len) 
         strcpy (action, pevent->name);
      else
         strcpy (action, target);
    
      if (pevent->mask & IN_CLOSE_WRITE){ 
	strcat(action, " opened for writing was closed");
	system(MAIL);
	system("rm /home/raghavendrabhat/nightly_sanity/tests_failed*");
	system ("rm /home/raghavendrabhat/result/*");
      }
      //  printf ("%s\n", action);
      i += sizeof(struct inotify_event) + pevent->len;
   }
}  /* get_event */

