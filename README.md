# littleoldvm #

## PREP WORK ##
* Install VirtualBox Guest Additionals :
    * vagrant plugin install vagrant-vbguest
    * vagrant vbguest --status

## SETUP VAGRANTFILE ##

```
$ cp Vagrantfile.example Vagrantfile
```

## SITE_DIR ##
Update SITES_DIR to represent your local sites dir.

```
$ vi Vagrantfile
```

## NOTES ##
* You can also update your available CPUs & memory
