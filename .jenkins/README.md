# about
> provide Jenkins pipeline configuration as code. There is also a `Makefile` script that will help your deploy the DBP locally in the same way is deploy on Jenkins server.

# usage
* cd in this folder
* run and follow help messages displayed
 ```
  $ make
 ```
 > (works on Unix, for Windows run this using CygWin)

* run `$ make build` to create everithing in one go
* run `$ make destroy` to delete everithing
* run `$ make destroy DESIREDNAMESPACE=my-app` if you want to delete everithing in namespace "my-app"