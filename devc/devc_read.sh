#! /bin/bash 
# Starts a devc container in 'read mode'. The container is actually being 
# run by rkt when it's in read mode (as opposed to write mode, when it's 
# being 'run' by acbuild). No changes are recorded (i.e. 
# everything is thrown away when you stop the container)
# 

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

vblog "Checking if containers are already running using devc_list.sh..."
$(dirname $0)/devc_list.sh > /dev/null
if [ $? -eq 1 ]
   then
   echo 'One or more devc containers are already running. Check devc_list.sh.'
   exit 1
fi

exit 0

# make sure we get sudo *before* we start the dev container
sudo echo 'h' > /dev/null

# TODO(mprast): factor out the name of the actual container.
vblog "Starting a devc container in read mode by using 'rkt run' with stage1-fly. Using a dummy process that just runs 'sleep 1d' over and over."
sudo rkt run --insecure-options=image --stage1-name=coreos.com/rkt/stage1-fly:1.20.0 /home/mprast/.devc_build/devc.aci --exec "/bin/bash" -- -c "while [ true ]; do sleep 1d; done" &
echo 'Dev container started!'
