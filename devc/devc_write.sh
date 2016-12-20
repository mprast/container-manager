#! /bin/bash
# Starts the dev container in 'record-mode'. Record mode remembers whatever 
# you do in the container and allows you to either save your changes or get 
# rid of them. Call devc_end.sh once you're done with your changes. 
# Supply -v to this script to get verbose mode.

# verbose log, not video blog :)
function vblog { 
    # BASH_ARGV contains the args to the script. 
    # $1 is an arg to the function
    if [ ${BASH_ARGV[0]:-''} == '-v' ]  
    then 
	echo $1 
    fi 
}

vblog "Checking if containers are already running using devc_list.sh..."
$(dirname $0)/devc_list.sh > /dev/null
if [ $? -eq 1 ]
   then 
   echo 'One or more devc containers are already running. Check devc_list.sh.' >&2
   exit 1
fi

# exits immediately if something errors out
set -e 

rkt_home_missing_msg=$(cat <<MSG
Could not start dev container in record mode: RKT_HOME needs to be set. This should point to the data directory that rkt uses (usually /var/lib/rkt); it is usually set by the scripts that provision the machine. If you installed rkt manually on this host you will need to set it yourself. 
MSG
)

# shorthand; writes message to STERR & exits if var is missing
: "${RKT_HOME:? $rkt_home_missing_msg}"

acbuild_missing_msg=$(cat <<MSG
record mode uses acbuild to create a new image for you. looks like 'which acbuild' didnt find anything. please install acbuild on this machine to continue.
MSG
)

if !(which acbuild >/dev/null 2>/dev/null) then 
    echo $acbuild_missing_msg >&2
    exit 1
fi

username=$(whoami)
build_dir="/home/$username/.devc_build"
if [ ! -e $build_dir ]
   then
   vblog "Creating devc build directory ($build_dir)..."
   mkdir $build_dir 
fi

acbuild_dir=$build_dir/.acbuild
# VV not needed for now, since the call to devc_list will catch this case. 
# if we re-architect things we might want to consider putting it back.

#acbuild_found_msg=$(cat <<MSG
#Found an existing acbuild build image in ($acbuild_dir). This probably indicates 
#that you started a container in record mode without discarding it or saving it.
#If you created this image yourself please discard it and create a new one to 
#use - we do some special setup to get record mode to work!
#Do you want to (d)iscard the image, (c)ontinue, or (a)bort?:
#MSG
#)
#
#if [ -e $acbuild_dir ]
#  then
#  echo $acbuild_found_msg 
#  read response
#  if [ $response == 'd' ]
#    then
#    vblog "Calling into 'devc_write_end.sh' to clean up the image..."
#    $(dirname $0)/devc_write_end.sh -v discard
#    exit 0
#  fi
#
#  if [ $response == 'a' ]
#    then 
#    echo 'Aborting'
#    exit 1
#  fi
#fi 

if [ ! -e $acbuild_dir ]
  then
  pushd $build_dir >/dev/null
  vblog "Creating a new build image with 'acbuild begin devc.aci'..."
  sudo acbuild begin ./devc.aci
  
  rootdir=$acbuild_dir/currentaci/rootfs

  vblog "Setting up crucial mountpoints in $rootdir (these let the container see the outside world)..."

  pushd $rootdir > /dev/null

  vblog "Mounting /proc..."
  sudo mount --rbind /proc proc

  vblog "Mounting /dev..."
  sudo mount --rbind /dev dev

  vblog "Mounting /sys..."
  sudo mount --rbind /sys sys
  
  vblog "Mounting $HOME/src to /src (with --bind, not --rbind!)..."
  sudo mount --bind $HOME/src src

  # for now, don't mount /containers. doesn't work in read mode so we want to 
  # keep things consistent. right thing is probably to have cman mount\unmount 
  # containers for investigation as needed in a separate dir.

  #vblog "Mounting /containers to the running rkt image dir in $RKT_HOME/pods/run"
  #sudo mount --rbind "$RKT_HOME/pods/run" containers

  popd > /dev/null 
  popd > /dev/null
fi


echo "Ready to record!"
