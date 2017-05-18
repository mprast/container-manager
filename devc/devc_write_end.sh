#! /bin/bash
# Stops a dev container that's running in write mode. 
# Based on the args you pass to this script, will 
# either write the changes out to an aci or discard 
# them. Write 'save' or 'discard'. 
# Pass -v for verbose mode.

# exit if any command fails
set -e

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

save_mode=false
if [ "$1" == 'save' ] || [ "$2" = 'save' ]
   then 
   echo "Saving your changes to devc.aci..."
   save_mode=true
elif [ "$1" == 'discard' ] || [ "$2" == 'discard' ]
   then
   echo "Discarding your changes..."
   # do nothing 
else
   echo 'Usage: devc_write_end.sh [-v] (save|discard)'  
   exit 1
fi  

# assuming $RKT_HOME is set and acbuild is 
# installed on this machine - otherwise 
# the user wouldn't have been able to 
# start the container

# TODO(mprast): factor the builddir 
# config out
username=$(whoami)
build_dir="/home/$username/.devc_build"
acbuild_dir="$build_dir/.acbuild"

no_acbuilddir_msg=$(cat <<MSG
The acbuild build dir $build_dir does not exist. This indicates that no 
dev container is running in write mode. Are you sure your container 
isn't running in read mode, or that you didn't start your container 
as a different user?
MSG
)

if [ ! -e $acbuild_dir ]
   then 
   echo $no_acbuilddir_msg
   exit 1
fi

vblog "Making mountpoints in the dev container private so unmount events don't propagate back to the host..."

rootdir=$acbuild_dir/currentaci/rootfs
pushd $rootdir > /dev/null

vblog "Setting /proc to rprivate..."
sudo mount --make-rprivate proc

vblog "Setting /dev to rprivate..."
sudo mount --make-rprivate dev

vblog "Setting /sys to rprivate..."
sudo mount --make-rprivate sys

vblog "Setting /src to private (not rprivate!)..."
sudo mount --make-private src

vblog "Setting /root/.stack to private (not rprivate!)..."
sudo mount --make-private root/.stack

#vblog "Setting /ssh_agent to private (not rprivate!)..."
#sudo mount --make-private ssh_agent

# don't mount containers for write devc. doesn't work in read mode 
# & we want to keep things consistent. Right way to do it is 
# probably to have cman mount containers for investigation as 
# needed.

#vblog "Setting /containers to rprivate..."
#sudo mount --make-rprivate containers

vblog "Unmounting mountpoints with umount -l..."

vblog "Unmounting /proc..."
sudo umount -l proc

vblog "Unmounting /dev..."
sudo umount -l dev

vblog "Unmounting /sys..."
sudo umount -l sys

vblog "Unmounting /src..."
sudo umount -l src

vblog "Unmounting /root/.stack..."
sudo umount -l root/.stack

vblog "Unmounting /ssh_agent..."
sudo umount -l ssh_agent

#vblog "Unmounting /containers..."
#sudo umount -l containers

popd > /dev/null

pushd $build_dir > /dev/null
if [ $save_mode = true ]
   then
   if [ -e './devc.aci' ]
      then  
      backup_fn="./devc_backup_$(date +'%m_%d_%Y_%I%p_%M')"
      vblog "moving the old devc.aci to $backup_fn..."
      mv ./devc.aci "$backup_fn"
   fi
   echo "Saving your changes to 'devc.aci' with acbuild write. This will take a few minutes..."
   sudo acbuild write ./devc.aci
fi
vblog "Clearing the build dir with acbuild end..."
sudo acbuild end
popd > /dev/null

echo "Done!"
