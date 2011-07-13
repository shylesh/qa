#! /bin/bash

(time prove -r $DIR/tests "$@" | tee -a /tmp/posix

grep FAILED /tmp/posix 2> /dev/null) 2>>$LOG_FILE 1>>$LOG_FILE

