#! /bin/bash
# Enters a running dev container. 

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

vblog "Checking if containers are already running using devc_status.sh..."
$(dirname $0)/devc_status.sh > /dev/null
if [ $? -eq 0 ]
   then
   echo 'No devc container is currently running. Try devc_up.sh.' >&2
   exit 1
fi

vblog "Entering devc container with 'buildah run'..."
# isolation must be 'chroot' so the bind mounts we set up in 
# devc_up will work.
sudo buildah run --tty --isolation chroot devc_local-working-container /bin/bash 
