# littleoldvm #

## PREP WORK ##
* Install VirtualBox Guest Additionals :
    * vagrant gem install vagrant-vbguest
    * C:\vagrant\vagrant\embedded\bin\gem.bat install vagrant-vbguest (if needed, a Window's workaround).
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
