### What?

**cloudinitdataserver** is a quick and dirty Sinatra app for serving
**cloud-init** user-data and meta-data to local virtual machines.

It is intended as a light replacement for AWS EC2's meta-data HTTP server
that is normally accessed via http://169.254.169.254/ when your virtual
machines boot up.

This is needed when running your own virtual machines (eg. using KVM or Xen)
with an Ubuntu server cloudimg disk image, and you want to customise the
meta-data/user-data without using other methods.


### How?

Configuration is stored in-memory only while the sinatra app is running (no persistence).

You set the configuration by posting it to /set/01:23:45:67:89:0a where
01:23:45:67:89:0a is the MAC address of the virtual machine.

The MAC address of inbound connections are found using the output of "arp".

In place of a mac address you can use "default" which will be served to all
clients as a fallback.

If you're really lazy you can edit the source to populate the default
before running the server.


### Example

First, bind the required ip address to the ethernet interface where the VMs reside:

	ifconfig virbr0:0 inet 169.254.169.254/16

Run this app: (requires root to use port 80)

	bundle install
	rvmsudo foreman start

Post it some data from another Ruby program:

	meta_data = {
	      'instance-id' => server_name,
	      'placement'   => { 'availability-zone' => 'ap-southeast-2' }
	    }.to_json

	RestClient.post("http://169.254.169.254/set/#{mac_address}",
	  'user-data' => File.read("seed-user-data.txt")
	  'meta-data' => meta_data.to_json
	)

The minimum required data for Ubuntu cloud images to boot successfully is
instance-id and placement.  You can just put "unknown" for the availability
zone and ubuntu's servers default to the US mirror.


### More info

