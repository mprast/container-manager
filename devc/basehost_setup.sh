if [ $EUID -ne 0 ]
then
    echo 'Please run this as root.'
    exit 1		
fi

# exits immediately if something errors out
set -e

echo 'pulling basehost from docker://fedora'
basehost_container_id=$(buildah from docker://fedora)

# for now let's not make everybody's images 40MB larger...
# buildah run 'dnf remove vim-minimal -y'
# buildah run 'dnf install vim -y'

# dnf.conf includes the line 'tsflags=nodocs', which 
# will prevent any manpages from ever being installed. 
# this is a good way to keep container sizes small, but 
# since we'll be using this container for development 
# we actually do want the docs in there. need to 
# remove that line from the config
echo "remove 'tsflags=nodocs' from /etc/dnf/dnf.conf so we can install man pages"
buildah run $basehost_container_id -- sed -i '/tsflags=nodocs/d' /etc/dnf/dnf.conf

# provides common utilities that allow 
# you to interact with /proc. these 
# include ps, top, and kill.
echo 'installing procps-ng...'
buildah run $basehost_container_id -- dnf install procps-ng -y

# adds find and xargs
echo 'installing findutils...'
buildah run $basehost_container_id -- dnf install findutils -y

echo 'installing man and man-pages...'
buildah run $basehost_container_id -- dnf install man -y
buildah run $basehost_container_id -- dnf install man-pages -y

echo 'adding TERM=screen.xterm-256color to .bashrc...'
buildah run $basehost_container_id -- sed -i '$a\export TERM=screen.xterm-256color' /root/.bashrc

echo 'adding SSH_AUTH_SOCK=/ssh_agent/ssh_agent.socket to .bashrc (for ssh agent forwarding)...'
buildah run $basehost_container_id -- sed -i '$a\export SSH_AUTH_SOCK=\/ssh_agent\/ssh_agent.socket' /root/.bashrc

echo 'adding PATH to .bashrc...'
buildah run $basehost_container_id -- sed -i '$a\export PATH' /root/.bashrc

# $HOME doesn't get set inside the fedora container image...we need 
# to set it ourselves. insert it into /.bashrc, which will get run when 
# we enter the shell. source ~/.bashrc after so we get all the stuff in 
# our 'regular' bashrc
echo 'adding HOME=/root to the very start of /.bashrc...'
# weird hack to get output redirection working. I couldn't figure out how to 
# use sed here because /.bashrc doesn't exist yet.
buildah run $basehost_container_id -- bash -c "echo '' > /.bashrc"
buildah run $basehost_container_id -- sed -i '$a\export HOME=\/root' /.bashrc
buildah run $basehost_container_id -- sed -i '$a\source ~\/.bashrc' /.bashrc

basehost_name=`date +fedora_basehost_%Y_%m_%d`

echo "storing the new basehost image in the docker daemon under $basehost_name:latest..."
buildah commit $basehost_container_id docker-daemon:$basehost_name:latest

echo "tagging the new basehost as devc_local:latest..."
docker tag $basehost_name:latest devc_local:latest

echo 'Basehost image successfully configured!'
