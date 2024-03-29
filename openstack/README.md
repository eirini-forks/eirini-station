# Eirini Openstack station

This is a set of scripts which makes it easier to create development stations
on Openstack. The scripts only use the [`openstack`
CLI](https://docs.openstack.org/newton/user-guide/common/cli-install-openstack-command-line-clients.html) and don't automate provisioning.

## Dependencies

The scripts needs:
  -  the [`openstack` CLI](https://docs.openstack.org/newton/user-guide/common/cli-install-openstack-command-line-clients.html)
  - Openstack RC File sourced
  - an SSH Key uploaded into your Openstack profile. Your key name should be the same as your I/D user name.
  - These additional environment variables set:
    - `EIRINI_STATION_USERNAME`: the username associated to your VM
    - `STATION_NETWORK_NAME`: The FloatingIP Network you retreived earlier
    - `VMUSER`: The name of the user that will exist on the VM

## Usage

To get a working station:

```
$ source </path/to/openstack/rc/file>
$ ./create.sh
$ ./provision.sh
$ ./ssh.sh
```

Once the machine is created, you could also provision it manually:

```
$ mkdir workspace
$ sudo apt update && sudo apt-get -y install git snap
$ git clone https://github.com/eirini-forks/eirini-station.git workspace/eirini-station
$ sudo workspace/eirini-station/provision.sh
$ workspace/eirini-station/provision-user.sh
```

To stop the machine:

```
./stop.sh
```

To start the machine back:

```
./start.sh
```

To destroy the machine:

```
./destroy.sh
```
