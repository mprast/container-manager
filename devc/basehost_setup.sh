if [ $EUID -ne 0 ]
then
    echo 'Please run this as root.'
    exit 1		
fi

acbuild begin docker://fedora

# for now let's not make everybody's images 40MB larger...
# acbuild run 'dnf remove vim-minimal -y'
# acbuild run 'dnf install vim -y'
acbuild run -- dnf install procps-ng -y
acbuild run -- dnf install findutils -y
acbuild run -- dnf install man -y
acbuild run -- dnf install man-pages -y
acbuild run -- echo 'export TERM=screen.xterm-256color' >> ~root/.bashrc
acbuild run -- echo 'export SSH_AUTH_SOCK=/ssh_agent/ssh_agent.socket' >> ~root/.bashrc
acbuild run -- echo 'export PATH' >> ~root/.bashrc
# $HOME doesn't get set inside the fedora container image...we need 
# to set it ourselves. insert it at the start of the file so 
# we have it before running /etc/bashrc
acbuild run -- sed -i "1i\export HOME='/root'" ~root/.bashrc

acbuild write 'fedora_basehost_v1.aci'
acbuild end
