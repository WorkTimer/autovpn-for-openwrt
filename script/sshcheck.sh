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
     echo "$1: permission denied"
     exit 1
     ;;
esac
case "$2" in
   pppd)
     ;;
   *)
     echo "$2: permission denied"
     exit 1
     ;;
esac
export PATH
exec "$@"
