#!/bin/bash

# run manually after creating a new CT/VM

# install figlet if not already installed
curl -s https://raw.githubusercontent.com/ayala/dotfiles/main/homelab/config/figlet.sh | bash

# --- configuration ---
HOST_DB="https://raw.githubusercontent.com/ayala/dotfiles/main/homelab/config/motd.sh"
LOCAL_HOST_DB_PATH="/tmp/host-db" # temporary local path for the downloaded file
CUSTOM_MOTD="/etc/update-motd.d/99-custom"
STATIC_MOTD="/etc/motd" # path to the static MOTD file
# LXC_DETAILS_SCRIPT="/etc/profile.d/00_lxc-details.sh" # No longer needed, as we'll clear all files

# --- functions ---

# download the host-db file from GitHub
download_host_db() {
    echo "Attempting to download host-db from $HOST_DB..."
    # use curl to download the file silently (-s) and fail fast on errors (-f)
    if ! curl -L "$HOST_DB" -o "$LOCAL_HOST_DB_PATH"; then
        echo "Error: Failed to download host-db from GitHub. Please check the URL and your network connection."
        # exit the script if the host-db cannot be downloaded, as it's critical
        exit 1
    fi
    echo "host-db downloaded successfully to $LOCAL_HOST_DB_PATH."
}

# disable dynamic MOTD scripts
disable_dynamic_motd() {
    echo "Disabling dynamic MOTD scripts..."
    # iterate through all files in update-motd.d and remove execute permission
    for script in /etc/update-motd.d/*; do
        if [[ -f "$script" && "$script" != "$CUSTOM_MOTD" ]]; then
            chmod -x "$script" 2>/dev/null
        fi
    done
    echo "Dynamic MOTD scripts disabled (except for 99-custom)."
}

# function to configure SSHD PrintMotd and PrintLastLog directives
configure_sshd_motd() {
    echo "Configuring SSHD PrintMotd and PrintLastLog directives..."

    # configure PrintMotd
    if grep -q "^PrintMotd" /etc/ssh/sshd_config; then
        sed -i 's/^PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
    else
        echo "PrintMotd no" >> /etc/ssh/sshd_config
    fi

    # configure PrintLastLog (to suppress "Last login" message)
    if grep -q "^PrintLastLog" /etc/ssh/sshd_config; then
        sed -i 's/^PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
    else
        echo "PrintLastLog no" >> /etc/ssh/sshd_config
    fi

    systemctl reload sshd || service sshd reload || echo "Warning: Could not reload sshd. Please do so manually if needed."
    echo "SSHD PrintMotd and PrintLastLog configured to 'no'."
}

# function to clear the static /etc/motd file
clear_static_motd() {
    echo "Clearing static MOTD file: $STATIC_MOTD..."
    if [[ -f "$STATIC_MOTD" ]]; then
        # truncate the file to zero size
        > "$STATIC_MOTD"
        echo "Static MOTD file cleared."
    else
        echo "Warning: Static MOTD file $STATIC_MOTD not found."
    fi
}

# clear all files in /etc/profile.d by removing execute permissions
clear_profile_d_scripts() {
    echo "Clearing all scripts in /etc/profile.d by removing execute permissions..."
    local profile_d_dir="/etc/profile.d"
    if [[ -d "$profile_d_dir" ]]; then
        for script in "$profile_d_dir"/*; do
            if [[ -f "$script" ]]; then
                chmod -x "$script" 2>/dev/null
                echo "Disabled: $script"
            fi
        done
        echo "All scripts in /etc/profile.d cleared."
    else
        echo "Warning: Directory $profile_d_dir not found."
    fi
}

# generate the custom MOTD script
create_custom_motd() {
    local hostname=$(hostname)
    local custom_banner=""

    echo "Generating custom MOTD for hostname: $hostname"

    # check if the downloaded host-db exists
    if [[ ! -f "$LOCAL_HOST_DB_PATH" ]]; then
        echo "Error: Downloaded host-db file not found at $LOCAL_HOST_DB_PATH. This should not happen if download_host_db succeeded."
        echo "Using figlet for banner as a fallback."
    fi

    # find hostname in hosts-db and extract banner
    if [[ -f "$LOCAL_HOST_DB_PATH" ]]; then
        local found=false
        local start_reading=false
        while IFS= read -r line; do
            if [[ "$line" == "#START_HOST:$hostname" ]]; then
                start_reading=true
                found=true
                continue
            elif [[ "$line" == "#END_HOST:$hostname" ]]; then
                start_reading=false
                break
            # handle empty lines within the banner gracefully
            elif [[ -z "$line" && "$start_reading" == true ]]; then
                custom_banner+="\n"
            fi

            if [[ "$start_reading" == true ]]; then
                custom_banner+="$line\n"
            fi
        done < "$LOCAL_HOST_DB_PATH"
    fi

    # if no custom banner found, use figlet
    if [[ -z "$custom_banner" ]]; then
        echo "No custom banner found for $hostname in $LOCAL_HOST_DB_PATH. Using figlet."
        # use printf to handle potential newlines from figlet better
        custom_banner=$(figlet -f sliver.flf "${hostname}" && echo "")
    fi

    # create the 99-custom script
    cat << EOF > "$CUSTOM_MOTD"
#!/bin/bash

# Custom MOTD generated by PVE MOTD script

# Ensure lolcat is available
if ! command -v lolcat &> /dev/null; then
    echo "lolcat not found. Displaying banner without color."
    # Use printf to properly interpret newlines in the banner
    printf "%b" "$custom_banner"
else
    # Added --force to ensure color output even when not directly to a TTY
    # Use printf to properly interpret newlines in the banner
    printf "%b" "$custom_banner" | lolcat --force && echo ""
fi

EOF

    chmod +x "$CUSTOM_MOTD"
    echo "Custom MOTD script created at $CUSTOM_MOTD"
}

# --- main script logic ---

echo "Starting Proxmox Container/VM MOTD Customization Script..."

download_host_db
disable_dynamic_motd
configure_sshd_motd
clear_static_motd
clear_profile_d_scripts # Changed function call here
create_custom_motd

echo "MOTD customization complete. Please log out and back in to see the changes."
echo "If this is a new container/VM, a reboot might be beneficial for all services."

# --- cleanup ---
# remove the temporary downloaded host-db file
if [[ -f "$LOCAL_HOST_DB_PATH" ]]; then
    rm "$LOCAL_HOST_DB_PATH"
    echo "Cleaned up temporary host-db file: $LOCAL_HOST_DB_PATH"
fi
