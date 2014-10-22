#!/bin/bash

set $SSH_ORIGINAL_COMMAND >/dev/null
case "$1" in
   sudo)
     ;;
   "")
     echo "permission denied"
     exit 1
     ;;
   *)
     echo "$1:1: permission denied"
     exit 1
     ;;
esac
case "$2" in
   pppd)
     ;;
   *)
     echo "$2:2: permission denied"
     exit 1
     ;;
esac
case "$3" in
   nodetach|notty|noauth)
     ;;
   *)
     echo "$3:3: permission denied"
     exit 1
     ;;
esac
case "$4" in
   nodetach|notty|noauth)
     ;;
   *)
     echo "$4:4: permission denied"
     exit 1
     ;;
esac
case "$5" in
   nodetach|notty|noauth)
     ;;
   *)
     echo "$5:5: permission denied"
     exit 1
     ;;
esac
case "$6" in
   "")
     ;;
   *)
     echo "$6:6: permission denied"
     exit 1
     ;;
esac
export PATH
exec "$@"
