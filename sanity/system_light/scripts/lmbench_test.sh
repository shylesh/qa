#!/bin/bash

#(time sudo lmbench-run) 2>> $LOG_FILE #Used for perrformance testing such as hardware,OS,development etc.

cp -r $SRC_DIR $GF_MP
cd  $LM_DIR
(time make results) 2>> $LOG_FILE