#! /bin/bash
# Enters a running dev container. Looks for a container in 
# 'write mode' first, then a container in 'read mode'.

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

# TODO(mprast): factor out builddir name
username=$(whoami)
builddir="/home/$username/.devc_build"
acbuilddir="$builddir/.acbuild"
if [ -e $acbuilddir ]
   then
   pushd $builddir > /dev/null
   vblog "Entering write container with acbuild run '/bin/bash'... "
   sudo acbuild run --engine chroot "/bin/bash"
   popd > /dev/null
else
   # TODO(mprast): rewrite this to be more stable - use the 
   # rkt metadata api

   # this gets the hash of any running fedora containers 
   # and passes them to rkt enter. assumes there's only 
   # one fedora container running on the box.
   devc_sha=$(rkt list | perl -ane 'print $F[0] if $F[2] =~ /fedora:latest/ && $F[3] =~ /running/') 
   if [ ! "$devc_sha" ]
      then
      echo "no running dev container found! (no write container since $acbuilddir doesn't exist, no read 
container since no running fedora container found by rkt list."
      exit 1
   fi

   vblog "Entering read container (id $devc_sha) with rkt enter..." 
   sudo rkt enter $devc_sha
fi
