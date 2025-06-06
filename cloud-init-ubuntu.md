* Proxmox Template with Cloud Init
> Jun 5 2024

Choose your [Ubuntu](https://cloud-images.ubuntu.com) Cloud Image

```sh
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

Create a VM
```sh
qm create 800 --memory 2048 --core 2 --name ubuntu-cloud --net0 virtio,bridge=vmbr0
```

Import the Ubuntu disk to local storage (Change ==local== to preffered storage)
```sh
qm disk import 800 jammy-server-cloudimg-amd64.img vms
```

Attach the new disk to the vm as a scsi drive on the scsi controller (Change ==local== to the storage of your choice)
```sh
qm set 800 --scsihw virtio-scsi-pci --scsi0 local:vm-800-disk-0
```

Add cloud init drive (Change ==local== to the storage of your choice)
```sh
qm set 800 --ide2 local:cloudinit
```

Make the cloud init drive bootable and restrict BIOS to boot from disk only
```sh
qm set 800 --boot c --bootdisk scsi0
```

Add serial console
```sh
qm set 800 --serial0 socket --vga serial0
```

#### DO NOT START YOUR VM

Now, configure hardware and cloud init, then create a template and clone.
If you want to expand your hard drive you can on this base image before 
creating a template or after you clone a new machine. I prefer to expand 
the hard drive after I clone a new machine based on need.

Create Template
```sh
qm template 800
```

Clone template (Change 135 to desired VM ID and name it)
```sh
qm clone 800 135 --name nameme --full
```

### Instructions
Download Ubuntu (replace with the url of the one you chose from above)
In Proxmox Click → Create VM and use the following settings:
* General: VM ID: 800 to set it low on your list
* OS: Do not Use any media: Select
* System: Graphics card: Serial terminal 0 | Qemu Agent: Select
* Disks: Discard scsi0
* CPU: Cores:2 | Type: host
* Memory: Balooning Device: Deselect
* Network: Skip and Create VM
* Once created, click → More and convert to template
 
### Step 2 Clone VM
* Click → More ← select Clone 
* VM ID: 900 | Name: Debian 12 | Mode: Full Clone 

### Step 3 Load Clone 
```sh
# Download Debian on host node → debian-12-generic-amd64.qcow2 
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
```
```sh
# Import image to Debian12 VM
qm importdisk 900 debian-12-generic-amd64.qcow2 vms --format qcow2
```
Go to Hardware and add Unused Disk ) to hard drive by clicking → Edit
* Disk: Click → Add 
* Change Boot Order in Options
* Add another Hard Drive in Hardware, choose CloudInit Drive and store in → vms
* Go to Cloud-Init and add you settings and convert to template
