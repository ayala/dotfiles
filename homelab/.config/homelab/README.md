# Storage and Backup
In this repo I will layout my storage and backup solutions for all of the services and platforms running on my homelab. Currently, I manage everything with Proxmox and Proxmox Backup Server. While soultions like Unraid and TrueNAS are awesome, I have found over the years the Proxmox is actually an amazing solution for managing storage, network shares, and backups.

Pulled from this guide → https://www.youtube.com/watch?v=qmSizZUbCOA&t=1748s

## Navigation
* [Apps](https://github.com/TechHutTV/homelab/tree/main/apps) - List of all the apps and services.
* [Home Assistant](https://github.com/TechHutTV/homelab/tree/main/homeassistant) - Smart home services and automation.
* [Media Server](https://github.com/TechHutTV/homelab/tree/main/media) - Plex, Jellyfin, *arr stack, and more.
* [Server Monitoring](https://github.com/TechHutTV/homelab/tree/main/monitoring) - Graphs and Visualizations for Unriad, Proxmox, and more.
* [Surveillance System](https://github.com/TechHutTV/homelab/tree/main/surveillance) - Frigate NVR Solution with Coral TPU.
* **Storage** - Current Storage and Backup Solution.
* [Proxy Managment](https://github.com/TechHutTV/homelab/tree/main/proxy) - NGINX Proxy Manager, DDNS with Cloudflare, Local Domains, and more.

## Proxmox as a NAS
My current setup involves a single server with x3 NVME drives and a bunch of harddrives in a ZFS configuration. These are combined into seperate ZFS pools for the HDDs (vault) and the SSDs (flash). Vault is used as a large data storage pool and Flash is used for containers and virtual machines disks. No mattery your configuratiuon you can follow this guide. However, I would recommend at least one NVME SSD for your boot drive, and at least 512gb if you don't have any other NVME SSDs and at least x2 HHDs for file storage.

### 1. Post Install Steps (optional)

#### Removing Proxmox Subscription Notice
(not currently working)

#### Disable Enterprise Repositories
1. Node > Repositories. Disable the enterprise repositories.
2. Now click Add and enable the no subscription repository. Finally, go Updates > Refresh.
3. Upgrade your system.

#### Delete local-lvm and Resize local
My boot drive is small and I run all my containers and virtual machine disks on a seperate storage pool. So the lvm paritiion is not nessesary for me and goes unused. If you're running everything off the same boot drive for fast storage skips this. Also you should check out this [video](https://www.youtube.com/watch?v=czQuRgoBrmM).
1. Delete local-lvm manually from web interface.
2. Run the following commands
```
lvremove /dev/pve/data
lvresize -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root
```
3. Check to ensure your local storage partition is using all avalible space. Reassign storage for containers and VM if needed.

#### Ensure IOMMU is enabled
Enable IOMMU on in grub configuration
```
nano /etc/default/grub
```
You will see the line with `GRUB_CMDLINE_LINUX_DEFAULT="quiet"`, all you need to do is add `intel_iommu=on` or amd_iommu=on` depending on your system.
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
```
Next run the following commands and reboot your system.
```
update-grub
```
Now check to make sure everything is enabled.
```
dmesg | grep -e DMAR -e IOMMU
dmesg | grep 'remapping'
```
Learn about enabling PCI Passthrough [here](https://pve.proxmox.com/wiki/PCI_Passthrough)

### 2. Create ZFS Pools

First, we are going to setup two ZFS Pools. A "Tank" pool which is used for larger stored data sets such as media, images and archives. We also will make a "Flash" pool which is used for virtual machine and container root file systems. To do this, on the Proxmox sidebar for your datacenter, go to Disks -> ZFS -> Create: ZFS. This will pop up the screen to create a ZFS pool.

From this screen, it should show all of your drives, so select the ones you want in your pool, and select your RAID level (in my case RAIDZ for my vault pool and mirror for my flash pool) and compression, (in my case lz4). Make sure you check the box that says **Add to Storage**. This will make the pools immiatily avalible and will prevent using .raw files as obsosed to my previous setup when I added directorties. 

### 3. Creating Containers using ZFS Pools

Now time to put these new storage pools in use. For this, we are going to create our first LXC. In this example the LXC is going to be in charge of managing our media server. First we need a operating system image. Click on your local storage in the sidebar and click on CT Templates then the Templates button. From there search for Ubuntu and download the ubuntu-22.04-standard template.

Now in the top right click on Create CT. The "Create: LXC Container" prompt should show up. On the general tab I set my CT ID to 100 (later I will match this to a local IP for organization) and I set the hostname to "servarr", you can name it anything like media, jellyfin, or whatever. Set your password, keep the container and unpriviledged and click Next. Select your downloaded Ubuntu template and click next. Under disk you can select your storage location. If you created the flash pool like we did eariler select it, otherwise local is fine. For storage I picked 64gb as my media server is quite large. Click next as we will add the data and docker directory later. Give it as many CPU cores and ram as you need, for my setup I gave it 6 cores and 8gb of memory.

Under network we will leave most everything, but I like to give it a static IP here. If you want to manage this with your router select DHCP. Under IPv4 I set the IPv4/CIDR to `10.0.0.100/24' and the gateway to `10.0.0.1` your local IP may be different. Keep DNS as is and confirm the installation. 

### 4. Adding Mount Points

Now that our container is created I want to add some storage and mount the data and docker directories on my system. Click on your newly created LXC and then click on Resources. From there click the Add button and select mount point. The first one I'll add is going to be for the bulk file storage or I will change the option under storage to tank. For path I will set this to /data and uncheck backup. We will set up backups later. I want to dedicate a ton of room to this so I 26078 GiB (28 TB). Set this to what works best your how much media you'd like to store there. I keep everything else as is and click create. For the docker mount I repeated all these steps, but set the storage to flash, mount point to /docker, and gave it about 128gb of space.

### 5. Creating SMB Shares

Great video resource by KeepItTechie: [https://www.youtube.com/watch?v=2gW4rWhurUs](https://www.youtube.com/watch?v=2gW4rWhurUs)
[source](https://gist.github.com/pjobson/3811b73740a3a09597511c18be845a6c)

Create your share directory and set permissions 
```
sudo mkdir /data
sudo chown -R brandon:brandon /data
```
Install Samba
```
sudo apt install samba
```
Create a backup of the default configuration
```
cd /etc/samba
sudo mv smb.conf smb.conf.old
```
Edit the samba config
```
sudo nano smb.conf
```
This is my configuration
```
[global]
   server string = Servarr
   workgroup = WORKGROUP
   security = user
   map to guest = Bad User
   name resolve order = bcast host
   hosts allow = 10.0.0.0/24
   hosts deny = 0.0.0.0/0
[data]
   path = /data
   force user = brandon
   force group = brandon
   create mask = 0774
   force create mode = 0774
   directory mask = 0775
   force directory mode = 0775
   browseable = yes
   writable = yes
   read only = no
   guest ok = no
[docker]
   path = /docker
   force user = brandon
   force group = brandon
   create mask = 0774
   force create mode = 0774
   directory mask = 0775
   force directory mode = 0775
   browseable = yes
   writable = yes
   read only = no
   guest ok = no
```
Add your samba user
```
sudo smbpasswd -a [username]
```
Set services to auto start on startup
```
sudo systemctl enable smbd
sudo systemctl enable nmbd
Restart samba services
sudo systemctl restart smbd
sudo systemctl restart nmbd
```
Allow samba on firewall if you run into any issues.
```
sudo ufw allow Samba
sudo ufw status
```
Install wsdd for Windows discorvery
```
sudo apt install wsdd
```
# Backups
Work in Progress
