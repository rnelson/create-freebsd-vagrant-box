#!/bin/sh
################################################################################
# CONFIG
################################################################################

# Packages which are pre-installed
INSTALLED_PACKAGES="ca_root_nss virtualbox-ose-additions bash sudo ezjail curl wget git"

# Configuration files
MAKE_CONF="https://raw.github.com/rnelson/vagrant-freebsd/master/etc/make.conf"
RC_CONF="https://raw.github.com/rnelson/vagrant-freebsd/master/etc/rc.conf"
RESOLV_CONF="https://raw.github.com/rnelson/vagrant-freebsd/master/etc/resolv.conf"
LOADER_CONF="https://raw.github.com/rnelson/vagrant-freebsd/master/boot/loader.conf"
EZJAIL_CONF="https://raw.github.com/rnelson/vagrant-freebsd/master/usr/local/etc/ezjail.conf"
PF_CONF="https://raw.github.com/rnelson/vagrant-freebsd/master/etc/pf.conf"

# Private key of Vagrant (you probable don't want to change this)
VAGRANT_PRIVATE_KEY="https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub"

################################################################################
# SYSTEM UPDATE
################################################################################
freebsd-update fetch install

################################################################################
# PACKAGE INSTALLATION
################################################################################

# Setup pkgng
pkg update
pkg upgrade -y

# Install required packages
for p in $INSTALLED_PACKAGES; do
    pkg install -y "$p"
done

# Remove the wunki repository
pkg update

################################################################################
# Configuration
################################################################################

# Symlink the ca_root_nss cert for everything else to use it
sudo ln -s /usr/local/etc/ssl/cert.pem /etc/ssl/cert.pem

# Create the vagrant user
pw useradd -n vagrant -s /usr/local/bin/bash -m -G wheel -h 0 <<EOP
vagrant
EOP

# Enable sudo for this user
echo "%vagrant ALL=(ALL) NOPASSWD: ALL" >> /usr/local/etc/sudoers

# Authorize vagrant to login without a key
mkdir /home/vagrant/.ssh
touch /home/vagrant/.ssh/authorized_keys
chown vagrant:vagrant /home/vagrant/.ssh

# Get the public key and save it in the `authorized_keys`
fetch -o /home/vagrant/.ssh/authorized_keys $VAGRANT_PRIVATE_KEY
chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys

# make.conf
fetch -o /etc/make.conf $MAKE_CONF

# rc.conf
fetch -o /etc/rc.conf $RC_CONF

# resolv.conf
fetch -o /etc/resolv.conf $RESOLV_CONF

# loader.conf
fetch -o /boot/loader.conf $LOADER_CONF

# ezjail
fetch -o /usr/local/etc/ezjail.conf $EZJAIL_CONF

# pf
fetch -o /usr/local/etc/pf.conf $PF_CONF


################################################################################
# CLEANUP
################################################################################

# Clean up installed packages
pkg clean -a -y

# Remove the history
cat /dev/null > /root/.history

# Try to make it even smaller
echo "Writing zeros to the disk to shrink the image; this will take a while."
dd if=/dev/zero of=/tmp/ZEROES bs=1M; break;;

# Empty out tmp directory
rm -rf /tmp/*

# DONE!
echo "We are all done. Poweroff the box and package it up with Vagrant:"
echo "  cd ~/VirtualBox\ VMs/freebsd-box"
echo "  VBoxManage modifyvdi freebsd-box.vdi compact"
echo "  cd ~/Desktop"
echo "  vagrant package --base freebsd-box --output freebsd-10.1-amd64.box"
echo ""

while true; do
    read -p "Would you like me to shut down? [y/N] " yn
    case $yn in
        [Yy]* ) shutdown -h now; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done