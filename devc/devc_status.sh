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

# the convention when running containers in buildah is 
# to take the image name and append -working-container 
# to it, so we're interested in 'devc_local-working-container'.
# if somebody accidentally creates more containers from the 
# devc_local image, we'll get things like 
# 'devc_local-working-container-2', etc. we're only concerned 
# whether 'devc_local-working-container' exists or not.
buildah_listing=$(sudo buildah containers -f name=devc_local-working-container --format "{{.ContainerName}}" | tac | sort | head -n 1)

if [ ${buildah_listing:-''} != "devc_local-working-container" ]
   then
   echo "There isn't a devc container running."
   exit 0
else
   echo "There's a devc container running under $buildah_listing."
   exit 1
fi
