#! /bin/bash
     
for((i = 0; i < 200; ++i)); do
  flock counter -c '
                   read value < counter
                   echo $value
                   value=$(( value + 1 ))
                   echo ${value} > counter
           '
  done
