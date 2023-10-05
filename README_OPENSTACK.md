# eirini-station - Openstack

## Prerequisites

* All the [common prerequisites](./README.md)
* Install the `vagrant-openstack-provider` and the `vagrant-env` plugin:
  ```
  vagrant plugin install vagrant-openstack-provider
  vagrant plugin install vagrant-env
  ```
* Add the SSH key you're going to use to your Openstack User on the Dashboard -> <your Username> -> Key Pairs.
  Click on "Create New" and add the SSH public key. Use your I/D Username as the key name.
  This has to be the same key you have loaded in your local SSH agent!
* Retreive the Openstack RC File from the Dashboard -> API Endpoints for Clients -> Download Openstack RC File
  Source the RC File:
  ```
  source openrc-<osdomain>-<osproject>
  ```
* Retreive the Floating IP Network, assigned to your Openstack Account. In the Dashboard, go to Networks&Routers and choose an External FloatingIP Network.
* Set up the necessary environment variables:
  - `EIRINI_STATION_USERNAME`: the username associated to your VM
  - `STATION_NETWORK_NAME`: The FloatingIP Network you retreived earlier
  - `VMUSER`: The name of the user that will exist on the VM

