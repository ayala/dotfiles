# Create a Cloud-Init VM template


### Step 1 Create VM
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
