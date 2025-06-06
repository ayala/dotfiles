# Proxmox Ubuntu Cloud Init Template
> Jun 6 2024

Choose your [Ubuntu](https://cloud-images.ubuntu.com) Cloud Image

```sh
cd /var/lib/vz/template/iso/ 
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

Create VM
```sh
qm create 9000 --memory 4096 --cpu host --balloon 0 --numa 1 --core 2 --name ubuntu-cloud --net0 virtio,bridge=vmbr0
```
```sh
cd /var/lib/vz/template/iso/
```
Import the Ubuntu disk (Change ```nvme``` to preferred storage)
```sh
qm importdisk 9000 noble-server-cloudimg-amd64.img nvme
```

Attach the new disk to VM (Change ```nvme``` to preferred storage)
```sh
qm set 9000 --scsihw virtio-scsi-pci --scsi0 nvme:9000/vm-9000-disk-0.raw,discard=on,ssd=1
```

Add Cloud Init drive (Change ```nvme``` to prefered storage)
```sh
qm set 9000 --ide2 nvme:cloudinit
```

Make the Cloud Init drive bootable
```sh
qm set 9000 --boot c --bootdisk scsi0
```

Add serial console
```sh
qm set 9000 --serial0 socket --vga serial0
```

#### DO NOT START YOUR VM

Now, configure hardware and cloud init, then create a template and clone.

IP Config: Enable DHCP

If you want to expand your hard drive you can on this base image before 
creating a template or after you clone a new machine with the following:
```sh
qm disk resize 9000 scsi0 10G
```

You'll find existing SSH Keys for Proxmox here:
```/root/.ssh/id_rsa``` and ```/root/.ssh/id_rsa.pub```

Create custom user-data.yaml with sudo users and inital commands
and assign to VM using the following command:
```sh
qm set 9000 --cicustom "user=nvme:snippets/user-data.yaml"
```

Create Template
```sh
qm template 9000
```

Clone template (Change ```102``` to desired VM ID and name it)
```sh
qm clone 9000 102 --name nameme --full
```

