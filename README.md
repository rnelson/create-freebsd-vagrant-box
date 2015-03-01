# FreeBSD on Vagrant

<img src="https://www.freebsd.org/layout/images/logo-red.png" align="right" />

> Quidquid latine dictum sit, altum viditur.
> 
> _(Whatever is said in Latin sounds profound.)_

Every time I work on a new project (which happens quite often at various local
hackathons), I set up a new [Vagrant] environment. This is problematic as the
base boxes that I use keep becoming unavailable, so each environment is
different than the last; all of my setup scripts have to be customized for the
specific event I'm at. Recently, I spent a very large chunk of a 5 hour event
just trying to get an environment up and running.

Because of this, I decided to create my own [FreeBSD] box for Vagrant that I
could reuse at all events. In my search for information on doing that, I found
[wunki's freebsd-vagrant project], which I have forked and customized to my
liking. It builds a FreeBSD 10.1 VM with a [ZFS] root and a few changes to the
base install.

**Table of Contents**

- [Freebsd on Vagrant](#freebsd-on-vagrant)
	- [Quickstart](#quickstart)
	- [Jails](#jails)
	- [Create your own FreeBSD Box](#create-your-own-freebsd-box)
		- [Virtualbox Settings](#virtualbox-settings)
		- [Installation from msfBSD ISO](#installation-from-msfbsd-iso)
		- [Configuration](#configuration)
		- [Package for Vagrant](#package-for-vagrant)
	- [What's Next?](#whats-next)
	- [Credits](#credits)
	- [License](#license)
    
## Quickstart

Simply copy the [Vagrantfile] from this repository to the project you want to
run the VM from and you are done. The box will be downloaded for you.

## Jails

The box comes with a *cloned_interface* with IP address which can be used for
jails. The range 172.23.0.1/16 is already configured for you with a proxy by
pf to have internet connectivity in a jail. To start a new jail, all you have
to do is:

    ezjail-admin install
    ezjail-admin create example.com 'lo1|172.23.0.1'
    ezjail-admin start example.com

    # Jump inside the jail
    ezjail-admin console example.com

## Create your own FreeBSD Box

This is for people who want to have their own customized box, instead of the
box I made for you with the scripts in this repository.

The FreeBSD boxes are built from the excellent [mfsBSD] site. Download either
the 9.2 or 10.1 special edition ISO and create a new virtual machine.

### Virtualbox Settings

Create a new Virtual Machine with the following settings:

- System -> Motherboard -> **Hardware clock in UTC time**
- System -> Acceleration -> **VT/x/AMD-V**
- System -> Acceleration -> **Enable Nested Paging**
- Storage -> Attach a **.vdi** disk (this one we can minimize later)
- Network -> Adapter 1 -> Attached to -> NAT
- Network -> Adapter 1 -> Advanced -> Adapter Type -> **Paravirtualized Network (virtio-net)**
- Network -> Adapter 2 -> Advanced -> Attached to -> **Host-Only Adapter**
- Network -> Adapter 2 -> Advanced -> Adapter Type -> **Paravirtualized Network (virtio-net)**

I would also recommend to disable all the things you are not using, such as
*audio* and *usb*.

### Installation from msfBSD ISO

Attach the ISO as a CD and boot it. You can login with `root` and password
`mfsroot`. After logging in, start the base installation with:

    mount_cd9660 /dev/cd0 /cdrom
    zfsinstall -d /dev/ada0 -u /cdrom/10.1-RELEASE-amd64 -s 1G

When the installation is done, you can `poweroff` and **remove the CD from
boot order in the settings.**

### Configuration

Boot into your clean FreeBSD installation. You can now run the
`vagrant-installation.sh` script from this repository. This will install and
setup everything which is needed for Vagrant to run. First, login as root (no
password required).

Select your keyboard:

    kbdmap

Get an IP adress:

    dhclient vtnet0

Bootstrap pkg manager by typing:

    pkg

[Github recently switched to new SSLv1.2 certificates] which requires you to
install the latest certificates. You can do so by fetching them from my own
repository:

    pkg install ca_root_nss
    ln -s /usr/local/etc/ssl/cert.pem /etc/ssl/cert.pem

In your FreeBSD box, fetch the installation script:

    fetch -o /tmp/vagrant-setup.sh https://raw.github.com/rnelson/vagrant-freebsd/master/bin/vagrant-setup.sh

Run it:

    cd /tmp
    chmod +x vagrant-setup.sh
    ./vagrant-setup.sh

### Package for Vagrant

Before packaging, I would recommend trying to reduce the size of the disk a
bit more. In Linux you can do:

    VBoxManage modifyvdi <freebsd-virtual-machine>.vdi compact

You can now package the box by running the following on your local machine:

    vagrant package --base <name-of-your-virtual-machine> --output <name-of-your-box>

## Credits

This is based off of a project by [wunki]. He used the [xironix freebsd] builds
to help build his project.

## License

This project is released under the BSD license.

[FreeBSD]: http://www.freebsd.org/
[Vagrant]: http://www.vagrantup.com/
[jails]: http://www.freebsd.org/doc/handbook/jails.html
[ZFS]: http://en.wikipedia.org/wiki/ZFS
[Vagrantfile]: https://github.com/rnelson/vagrant-freebsd/blob/master/Vagrantfile
[mfsBSD]: http://mfsbsd.vx.sk/
[10.1-RELEASE-amd64 special edition]: http://mfsbsd.vx.sk/
[xironix freebsd]: https://github.com/xironix/freebsd-vagrant
[Github recently switched to new SSLv1.2 certificates]: https://github.com/blog/1734-improving-our-ssl-setup
[wunki]: https://github.com/wunki
[wunki's freebsd-vagrant project]: https://github.com/wunki/vagrant-freebsd
