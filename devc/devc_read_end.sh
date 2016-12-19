#! /bin/bash
# Stops a dev container that's running in read mode.

# exit if any command fails
set -e

# TODO: factor this "is this running" logic out into its own thing.
devc_sha=$(rkt list | perl -ane 'print $F[0] if $F[2] =~ /fedora:latest/ && $F[3] =~ /running/')

if [ ! "$devc_sha" ]
   then
   echo "no dev container is running in read mode (couldn't find a running fedora container using 'rkt list')" >&1
   exit 1
fi

echo "stopping container $devc_sha with 'rkt stop'..."
sudo rkt stop $devc_sha
echo "stopped."
