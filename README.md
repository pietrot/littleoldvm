# littleoldvm

## Prep work

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

1. Setup the config file.

```
cp Vagrantfile.example Vagrantfile
```

* Update your hostname (HOSTNAME - in Vagrantfile). 

* Update your sites directory (SITES_DIR - in Vagrantfile) to reflect your local sites directory. This provides folder sharing between the vm and your local machine through network mapping.

(adjust available CPUs & memory as needed)

3. Spin up the VM (incl. provisioning).

```
vagrant up
```

4. Create local DNS entry.

```
sudo vim /etc/hosts
```

```
...
192.168.33.11 {hostname}.test
```
