#! /bin/bash
# Starts the dev container. Once started you'll be 
# able to enter with devc_enter.sh. The container 
# will remember whatever you do to it - when you 
# shut it down with devc_down.sh you will have 
# the option to save or discard your changes.
# Supply -v to this script to get verbose mode.

if [ $EUID -eq 0 ]
then
    echo 'Please do not run this as root. The script will ask for sudo when it needs elevated privileges. Thanks!'
    exit 1
fi

# verbose log, not video blog :)
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
if [ $? -eq 1 ]
   then 
   echo 'A devc container is already running. Check devc_status.sh.'
   exit 1
fi

# exits immediately if something errors out
set -e 

buildah_missing_msg=$(cat <<MSG
devc uses buildah to create and run images. looks like 'which buildah' didnt find anything. please install buildah on this machine to continue.
MSG
)

if !(which buildah >/dev/null 2>/dev/null) then 
    echo $buildah_missing_msg >&2
    exit 1
fi

vblog "Creating a new container from devc_local:latest..."
container_id=$(sudo buildah from --pull-always docker-daemon:devc_local:latest)
vblog "Mounting the filesystem for container $container_id..."
build_dir=$(sudo buildah mount $container_id)

vblog "Setting up crucial mountpoints in the mounted container (these let the container see the outside world)..."

vblog "Mounting /proc..."
sudo mount --rbind /proc $build_dir/proc

vblog "Mounting /dev..."
sudo mount --rbind /dev $build_dir/dev

vblog "Mounting /sys..."
sudo mount --rbind /sys $build_dir/sys

vblog "Mounting /src to /src (with --bind, not --rbind!)..."
if sudo [ ! -d "$build_dir/src" ]; then
    sudo mkdir $build_dir/src
fi
sudo mount --bind /src $build_dir/src

vblog "Mounting $HOME/ssh_agent to /ssh_agent (with --bind, not --rbind!)..."
if sudo [ ! -d "$build_dir/ssh_agent" ]; then
    sudo mkdir $build_dir/ssh_agent
fi
sudo mount --bind $HOME/ssh_agent $build_dir/ssh_agent

# for now, don't mount /containers. didn't work using acbuild and I don't have 
# time to try it again with buildah.

#vblog "Mounting /containers to the running rkt image dir in $RKT_HOME/pods/run"
#mount --rbind "$RKT_HOME/pods/run" containers

echo "Dev container is ready to go! You can enter it with devc_enter.sh."
