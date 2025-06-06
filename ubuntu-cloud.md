# Creating a Cloud-Init Ubuntu Template in Proxmox with Multiple Sudo Accounts

Creating a Cloud-Init Ubuntu template in Proxmox with multiple sudo accounts involves several steps, primarily focusing on downloading the base image, creating the VM, configuring Cloud-Init to handle user creation and sudo privileges, and then converting it into a template.

Here's a comprehensive guide:

**Phase 1: Prepare Proxmox and Download Ubuntu Cloud Image**

1.  **Enable Snippets Storage:**
    * Log in to the Proxmox web UI.
    * Navigate to `Datacenter` -> `Storage`.
    * Select your storage where you want to store Cloud-Init snippets (e.g., `local` or `local-zfs`).
    * Click `Edit` and ensure "Snippets" is checked in the "Content" dropdown. This creates the `/var/lib/vz/snippets` directory (or similar, depending on your storage) which is essential for custom Cloud-Init configurations.

2.  **Download Ubuntu Cloud Image:**
    * SSH into your Proxmox host.
    * Navigate to your Proxmox image storage directory (e.g., `/var/lib/vz/template/iso` or a custom path for your `local-zfs` storage).
    * Download the latest Ubuntu cloud image. You can find these on the official Ubuntu Cloud Images website (e.g., `https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img` for Ubuntu 24.04 Noble Numbat).
    * Example using `wget`:
        ```bash
        wget [https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img](https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img)
        ```

**Phase 2: Create the Proxmox VM**

1.  **Create a New VM (without an OS yet):**
    * In the Proxmox web UI, click `Create VM`.
    * **General Tab:**
        * `Node`: Select your Proxmox node.
        * `VM ID`: Choose an unused VM ID (e.g., `9000`).
        * `Name`: Give it a descriptive name (e.g., `ubuntu-cloudinit-template`).
    * **OS Tab:**
        * `Do not use any media`.
        * `Guest OS`: Select `Linux` and `2.6 Kernel (l26)`.
    * **System Tab:**
        * `Graphic card`: `Serial (serial0)`.
        * `SCSI Controller`: `VirtIO SCSI Single`.
        * `Qemu Agent`: Check `Enable Qemu Agent`. This is highly recommended for better integration between Proxmox and the VM.
        * `BIOS`: `OVMF (UEFI)` (recommended for modern systems). If you use UEFI, ensure you have an EFI disk.
    * **Disks Tab:**
        * `Bus/Device`: `SCSI` (`0` is usually fine).
        * `Storage`: Select your storage (the same one where you downloaded the image).
        * `Disk size (GiB)`: Set a small size, e.g., `32` GB, as Cloud-Init will resize it later.
        * `Discard`: (If on SSD/NVMe) Check `Discard` for TRIM support.
    * **CPU Tab:**
        * `Sockets`: `1`.
        * `Cores`: `1` (you can adjust this later for clones).
        * `Type`: `host` (recommended for best performance).
    * **Memory Tab:**
        * `Memory (MiB)`: Set a reasonable amount, e.g., `1024` MiB (1 GB). You can adjust this later for clones.
    * **Network Tab:**
        * `Bridge`: Select your VM bridge (e.g., `vmbr0`).
        * `Model`: `VirtIO (paravirtualized)`.
    * **Confirm Tab:** Review settings and click `Finish`.

2.  **Import the Downloaded Cloud Image:**
    * SSH into your Proxmox host again.
    * Import the downloaded `.img` file into the VM's disk. Replace `9000` with your VM ID and `local-zfs` with your storage:
        ```bash
        qm importdisk 9000 noble-server-cloudimg-amd64.img local-zfs
        ```
    * You'll see output like `Successfully imported disk as 'vm-9000-disk-0'`.

3.  **Attach the Imported Disk and Configure Boot Order:**
    * In the Proxmox web UI, select your new VM (`9000`).
    * Go to `Hardware`. You'll see an "Unused Disk 0" (or similar).
    * Select it and click `Edit`.
    * `Bus/Device`: `SCSI` (e.g., `SCSI0`).
    * `Storage`: Select the same storage where you imported the disk.
    * Click `Add`.
    * Go to `Options` -> `Boot Order`.
    * Ensure the newly attached disk (e.g., `scsi0`) is enabled and moved to the top.

4.  **Add Cloud-Init CD-ROM Drive:**
    * In the Proxmox web UI, select your VM (`9000`).
    * Go to `Hardware` -> `Add` -> `Cloud-Init Drive`.
    * `Storage`: Select the same storage you enabled snippets on.
    * `CD-ROM`: This will be `ide2` by default, which is fine.
    * Click `Add`.

**Phase 3: Configure Cloud-Init for Multiple Sudo Accounts**

This is the core part. You'll create a `user-data` YAML file containing the configuration for your multiple sudo accounts.

1.  **Create the `user-data.yaml` file:**
    * SSH into your Proxmox host.
    * Navigate to your snippets directory (e.g., `/var/lib/vz/snippets/`).
    * Create a file named `my-users.yaml` (or any name you prefer) and paste the following content, replacing placeholders with your desired usernames, hashed passwords, and SSH public keys:

    ```yaml
    #cloud-config
    users:
      # First sudo user
      - name: adminuser1
        sudo: ALL=(ALL) NOPASSWD:ALL  # Gives passwordless sudo. Consider "ALL=(ALL:ALL) ALL" for password-required sudo
        groups: users, sudo, adm
        shell: /bin/bash
        ssh_authorized_keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... # Your public SSH key for adminuser1
        lock_passwd: false # Allow password login (if you set a password hash)
        passwd: "$6$rounds=40000$saltdat$hashedpasswordforadminuser1" # Replace with actual SHA512 hash

      # Second sudo user
      - name: adminuser2
        sudo: ALL=(ALL) NOPASSWD:ALL
        groups: users, sudo, adm
        shell: /bin/bash
        ssh_authorized_keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD... # Your public SSH key for adminuser2
        lock_passwd: false
        passwd: "$6$rounds=40000$saltdat$hashedpasswordforadminuser2" # Replace with actual SHA512 hash

      # Optional: A regular user without sudo
      - name: regularuser
        groups: users
        shell: /bin/bash
        ssh_authorized_keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... # Your public SSH key for regularuser
        lock_passwd: false
        passwd: "$6$rounds=40000$saltdat$hashedpasswordforregularuser"

    # Optional: Set hostname and install qemu-guest-agent (often already in cloud images)
    # If using an existing cloud image, qemu-guest-agent might be pre-installed.
    # hostname: mytemplate
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
    ```

    **Important Notes on `user-data.yaml`:**
    * **Password Hashing:** You **must** generate SHA512 password hashes for the `passwd` field. You can do this on a Linux machine using `mkpasswd -m sha-512` or `openssl passwd -6`. Do not use plain text passwords.
    * **SSH Keys:** It's highly recommended to use SSH keys for authentication. Replace the placeholder `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...` with your actual public SSH keys. You can add multiple keys per user if needed.
    * **`sudo`:**
        * `sudo: ALL=(ALL) NOPASSWD:ALL` grants passwordless sudo.
        * `sudo: ALL=(ALL:ALL) ALL` requires a password for sudo. Choose based on your security requirements.
    * **`lock_passwd: false`**: Allows password login. If you only want SSH key access, set this to `true` and omit the `passwd` field.
    * **`groups: users, sudo, adm`**: Adding users to `sudo` and `adm` groups (common in Ubuntu) grants them sudo privileges. `users` is a standard group.
    * **`packages` and `runcmd`**: These are optional but good for ensuring `qemu-guest-agent` is installed and running, which improves Proxmox's ability to manage the VM.

2.  **Assign the Custom Cloud-Init Configuration to the VM:**
    * Still in SSH on your Proxmox host:
        ```bash
        qm set 9000 --cicustom "user=local:snippets/my-users.yaml"
        ```
        (Replace `9000` with your VM ID and `local` with your storage name if different).

    * Alternatively, you can configure basic Cloud-Init settings in the Proxmox UI under the VM's `Cloud-Init` tab (username, password, SSH keys, IP). However, for multiple users and advanced `sudo` configurations, a custom `user-data.yaml` is essential.

**Phase 4: Convert to Template**

1.  **Sysprep the VM (if it's not a fresh cloud image):**
    * If you started with a pre-existing Ubuntu VM that wasn't a cloud image, you need to run `cloud-init clean --logs` inside the VM to reset Cloud-Init before templating.
    * If you're using a fresh cloud image, this step is often not strictly necessary as they are designed to be "sysprepped."

2.  **Shutdown the VM:**
    * In the Proxmox web UI, select the VM (`9000`) and click `Shutdown`.

3.  **Convert to Template:**
    * Once the VM is shut down, select it in the Proxmox web UI.
    * Click `More` -> `Convert to Template`.
    * Confirm the action.

**Phase 5: Deploy and Verify**

1.  **Clone the Template:**
    * Right-click your new template (`ubuntu-cloudinit-template`).
    * Click `Clone`.
    * **Mode:** `Linked Clone` is faster and uses less space, but is dependent on the template. `Full Clone` is independent but takes longer and uses more space. For typical VM deployments, `Linked Clone` is often preferred.
    * `Target storage`: Select your VM storage.
    * `VM ID`: Choose a new, unused ID for the clone.
    * `Name`: Give the new VM a unique name (e.g., `my-ubuntu-server-1`).
    * Click `Clone`.

2.  **Configure Cloned VM (Optional, but Recommended):**
    * Select the newly cloned VM.
    * Go to its `Cloud-Init` tab.
    * Here you can override template settings like:
        * `User`: (Optional, you can leave the users defined in your `my-users.yaml` to be created).
        * `Password`: (Optional, if you want a password for the default Proxmox Cloud-Init user).
        * `SSH Public Key`: (Optional, if you want to add more SSH keys or override).
        * `IP Configuration`: Set `IPv4` and `IPv6` if you need a static IP. Otherwise, leave it as `DHCP`.
        * `DNS Domain`, `DNS Servers`.
    * **Crucially**, the custom `user-data` from your `my-users.yaml` will still be processed alongside any settings you configure here in the Proxmox UI.

3.  **Start the Cloned VM:**
    * Start the new VM.
    * Cloud-Init will run on the first boot, creating your specified users, setting passwords (or applying SSH keys), configuring sudo, and installing `qemu-guest-agent`.

4.  **Verify:**
    * Once the VM has booted (it might reboot once or twice due to Cloud-Init actions), try to SSH into it using the usernames and SSH keys you defined in `my-users.yaml`.
    * Test sudo access for your `adminuser1` and `adminuser2`.
