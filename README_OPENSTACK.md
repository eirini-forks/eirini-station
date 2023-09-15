# eirini-station - Openstack

## Prerequisites

* All the [common prerequisites](./README.md)
* Install the `vagrant-openstack-provider` and the `vagrant-env` plugin:
  ```
  vagrant plugin install vagrant-openstack-provider
  vagrant plugin install vagrant-env
  ```
* Add the SSH key you're going to use to your Openstack User on the Dashboard -> <your Username> -> Key Pairs. 
  Click on "Create New" and add the SSH public key.
  This has to be the same key you have loaded in your local SSH agent!
* Retreive the Openstack RC File from the Dashboard -> API Endpoints for Clients -> Download Openstack RC File
  Source the RC File:
  ```
  source openrc-<osdomain>-<osproject>
  ```
* Retreive the Floating IP Network, assigned to your Openstack Account. In the Dashboard, go to Networks&Routers and choose an External FloatingIP Network.
* Set up the necessary environment variables:
  - `EIRINI_STATION_USERNAME`: the username associated to your VM
  - `EIRINI_STATION_FLOATING_NETWORK`: The FloatingIP Network you retreived earlier
  - `VMUSER`: The name of the user that will exist on the VM


## Usage

Start the VM:

```
vagrant up --provider=openstack
```

SSH into the VM:

```
vagrant ssh
```

Print the command to ssh onto the VM and send it to your pair:

```
pssh
```

You can now start your pairing session:

```
pmux
```

You pair can then join the session:

```
pattach
```

## Station script

Alternatively you can put [this script](https://raw.githubusercontent.com/eirini-forks/eirini-home/master/util/bin/station) somewhere on your path. It is a tiny vagrant wrapper that exports the necessary env vars for you and delegates to vagrant.
You can easily provision the vm by running `station up` or `station provision` from any directory.
Logging onto the vm is as easy as `station ssh`
