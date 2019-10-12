#! /bin/bash
# Stops a dev container. 
# Based on the args you pass to this script, will 
# either write the changes out to an image or discard 
# them. Write 'save' or 'discard'. 
# Pass -v for verbose mode.

# this is duplicated from ./devc_write.sh for now.
# TODO(mprast): factor this method out
function vblog {
    # BASH_ARGV contains the args to the script.
    # $1 is an arg to the function
    if [ ${BASH_ARGV[1]:-''} == '-v' ]
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

# exit if any command fails
set -e

save_mode=false
if [ "$1" == 'save' ] || [ "$2" = 'save' ]
   then 
   echo "Saving your changes..."
   save_mode=true
elif [ "$1" == 'discard' ] || [ "$2" == 'discard' ]
   then
   echo "Discarding your changes..."
   # do nothing 
else
   echo 'Usage: devc_write_end.sh [-v] (save|discard)'  
   exit 1
fi  

vblog "Making mountpoints in the dev container private so unmount events don't propagate back to the host..."

build_dir=$(sudo buildah mount devc_local-working-container)

vblog "Setting /proc to rprivate..."
sudo mount --make-rprivate $build_dir/proc

vblog "Setting /dev to rprivate..."
sudo mount --make-rprivate $build_dir/dev

vblog "Setting /sys to rprivate..."
sudo mount --make-rprivate $build_dir/sys

vblog "Setting /src to private (not rprivate!)..."
sudo mount --make-private $build_dir/src

#vblog "Setting /ssh_agent to private (not rprivate!)..."
#sudo mount --make-private ssh_agent

# don't mount containers for write devc. didn't work 
# using acbuild and I don't have the time to make 
# it work with buildah

#vblog "Setting /containers to rprivate..."
#sudo mount --make-rprivate containers

vblog "Unmounting mountpoints with umount -l..."

vblog "Unmounting /proc..."
sudo umount -l $build_dir/proc

vblog "Unmounting /dev..."
sudo umount -l $build_dir/dev

vblog "Unmounting /sys..."
sudo umount -l $build_dir/sys

vblog "Unmounting /src..."
sudo umount -l $build_dir/src

vblog "Unmounting /ssh_agent..."
sudo umount -l $build_dir/ssh_agent

#vblog "Unmounting /containers..."
#sudo umount -l containers

if [ $save_mode = true ]
   then

   image_name="devc_local_$(date +'%Y_%m_%d_%H_%M')"
   echo "Saving your changes to $image_name with buildah commit. This will take a second..."
   sudo buildah commit --squash devc_local-working-container docker-daemon:$image_name:latest

   echo "Tagging $image_name as devc_local:latest..."
   sudo docker tag $image_name:latest devc_local:latest
fi

vblog 'Clearing the devc container from buildah by running buildah umount and buildah rm...'
sudo buildah umount devc_local-working-container
sudo buildah rm devc_local-working-container
echo "Done!"
