#! /bin/bash
# Lists the dev containers that are currently running.
# Returns 0 if no containers are running, and 1 if 
# containers are running.

# exit if any command fails
set -e 

# this is duplicated from ./devc_write.sh for now.
# TODO(mprast): factor this method out
function vblog {
    # BASH_ARGV contains the args to the script.
    # $1 is an arg to the function
    if [ ${BASH_ARGV[0]:-''} == '-v' ]
    then
        echo $1
    fi
}

containers_running=false

# TODO(mprast): factor out build dir
username=$(whoami)
acbuilddir="/home/$username/.devc_build/.acbuild"
vblog "checking for a running write container by seeing if $acbuilddir exists..."
if [ -e $acbuilddir ]
   then
   containers_running=true
   echo "There's a dev container running in write mode."
fi

devc_sha=$(rkt list | perl -ane 'print $F[0] if $F[2] =~ /fedora:latest/ && $F[3] =~ /running/')
vblog "checking for a running read container by seeing if there's a fedora container in the 'running' state using 'rkt list'..."
if [ "$devc_sha" ]
   then
   containers_running=true
   echo "There's a dev container running in read mode."
fi

if ! $containers_running 
   then
   echo "There are no devc containers running."
   exit 0
else
   exit 1
fi
