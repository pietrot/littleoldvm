# littleoldvm

## PREP WORK

* Core Tools:
    * https://www.virtualbox.org/wiki/Downloads
    * https://www.vagrantup.com

* SSH Client:
    * https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html (Windows)
    * https://www.iterm2.com (Mac)
    * Basic Terminal (Linux)

* Install VirtualBox Guest Additionals :
    * vagrant plugin install vagrant-vbguest
    * vagrant vbguest --status

## Launching your VM

1. Setup the config file

```
$ cp Vagrantfile.example Vagrantfile
```

2. Update your sites directory (SITES_DIR - in Vagrantfile) to reflect your local sites directory.
   - providing folder sharing between the vm and your local machine - network mapping.

3. SSH into the VM and run the build script.

```
vagrant ssh
sudo /vagrant/provision/shell/build.sh
```

(ensure to monitor as user input is required)

## Notes
* You can adjust available CPUs & memory in the config file.
