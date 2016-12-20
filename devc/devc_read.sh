#! /bin/bash 
# Starts a devc container in 'read mode'. The container is actually being 
# run by rkt when it's in read mode (as opposed to write mode, when it's 
# being 'run' by acbuild). No changes are recorded (i.e. 
# everything is thrown away when you stop the container)
# 

# THIS is duplicated from ./devc_write.sh for now.
# TODO(mprast): factor this method out
function vblog {
    # BASH_ARGV contains the args to the script.
    # $1 is an arg to the function
    if [ ${BASH_ARGV[0]:-''} == '-v' ]
    then
        echo $1
    fi
}

# TODO(mprast): factor this out into a preamble
rkt_home_missing_msg=$(cat <<MSG
Could not start dev container in record mode: RKT_HOME needs to be set. This should point to the data directory that rkt uses (usually /var/lib/rkt); it is usually set by the scripts that provision the machine. If you installed rkt manually on this host you will need to set it yourself.
MSG
)

#shorthand; writes message to STDERR & exits if var is missing
: "${RKT_HOME:? $rkt_home_missing_msg}"

vblog "Checking if containers are already running using devc_list.sh..."
$(dirname $0)/devc_list.sh > /dev/null
if [ $? -eq 1 ]
   then
   echo 'One or more devc containers are already running. Check devc_list.sh.'
   exit 1
fi

# make sure we get sudo *before* we start the dev container
sudo echo 'h' > /dev/null

# TODO(mprast): factor out the name of the actual container.
vblog "Starting a devc container in read mode by using 'rkt run' with stage1-fly. Running 'tail -f /dev/null' as a dummy process to keep the container going forever. Mounting the rkt running pod dir to /containers"
sudo rkt run --insecure-options=image --stage1-name=coreos.com/rkt/stage1-fly:1.20.0 /home/mprast/.devc_build/devc.aci --volume containers,kind=host,source=$RKT_HOME/pods/run,recursive=true --mount volume=containers,target=/containers --exec "/usr/bin/tail" -- -f "/dev/null" &
echo 'Dev container started!'
