#!/bin/bash

# Set TERM if it's not already set (e.g., when run from cron or systemd)
# Choose an appropriate value for your environment, 'xterm' is often a safe default
if [ -z "$TERM" ]; then
    TERM=xterm
    export TERM
fi

# run manually after creating a new CT/VM

# install figlet if not already installed (and lolcat)
# It's good practice to install lolcat here as well, since it's a core dependency
# for coloring the custom banner.
# The 'figlet.sh' script might handle lolcat as well, but let's be explicit.
# Assuming figlet.sh also installs lolcat, or you'll install it separately.
curl -s https://raw.githubusercontent.com/ayala/dotfiles/main/homelab/config/figlet.sh | bash

# --- configuration ---
HOST_DB="https://raw.githubusercontent.com/ayala/dotfiles/main/homelab/config/host-db2"
LOCAL_HOST_DB_PATH="/tmp/host-db" # temporary local path for the downloaded file
CUSTOM_MOTD="/etc/update-motd.d/99-custom"
STATIC_MOTD="/etc/motd" # path to the static MOTD file

# --- functions ---

# download the host-db file from GitHub
download_host_db() {
    echo "Attempting to download host-db from $HOST_DB..."
    # use curl to download the file silently (-s) and fail fast on errors (-f)
    if ! curl -s -f -L "$HOST_DB" -o "$LOCAL_HOST_DB_PATH"; then
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
    # We now also handle empty lines within the banner itself by explicitly adding a newline.
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
            # Handle empty lines within the banner gracefully
            elif [[ -z "$line" && "$start_reading" == true ]]; then
                custom_banner+="\n"
            fi

            if [[ "$start_reading" == true ]]; then
                custom_banner+="$line\n"
            fi
        done < "$LOCAL_HOST_DB_PATH"
    fi

    # if no custom banner found (or host-db didn't exist/failed), use figlet
    if [[ -z "$custom_banner" ]]; then
        echo "No custom banner found for $hostname in $LOCAL_HOST_DB_PATH. Using figlet."
        # Use figlet to generate the banner.
        custom_banner=$(figlet -f sliver.flf "${hostname}")
    fi

    # create the 99-custom script
    cat << EOF > "$CUSTOM_MOTD"
#!/bin/bash

# Custom MOTD generated by PVE MOTD script

# Clear the screen before presenting the MOTD
clear

# Ensure lolcat is available
if ! command -v lolcat &> /dev/null; then
    echo "lolcat not found. Displaying banner without color."
    # Use printf to properly interpret newlines in the banner
    printf "%b" "$custom_banner"
else
    # Added --force to ensure color output even when not directly to a TTY
    # Removed '&& echo ""' here, as printf with %b and the banner's existing newlines are sufficient.
    printf "%b" "$custom_banner" | lolcat --force
fi

# Add a single blank line for spacing after the banner, if desired.
# If you want NO blank line after the banner, remove the line below.
echo ""

EOF

    chmod +x "$CUSTOM_MOTD"
    echo "Custom MOTD script created at $CUSTOM_MOTD"
}

# --- main script logic ---

echo "Starting Proxmox Container/VM MOTD Customization Script..."

# Ensure figlet and lolcat are installed first
echo "Ensuring figlet and lolcat are installed..."
if ! command -v figlet &> /dev/null || ! command -v lolcat &> /dev/null; then
    echo "figlet or lolcat not found. Running figlet.sh to install them."
    curl -s https://raw.githubusercontent.com/ayala/dotfiles/main/homelab/config/figlet.sh | bash
    # It's good to check again after running the install script
    if ! command -v figlet &> /dev/null; then
        echo "Error: figlet installation failed. Cannot proceed with banner generation."
        exit 1
    fi
    if ! command -v lolcat &> /dev/null; then
        echo "Warning: lolcat installation failed. Banner will not be colored."
    fi
else
    echo "figlet and lolcat are already installed."
fi


download_host_db
disable_dynamic_motd
configure_sshd_motd
clear_static_motd
clear_profile_d_scripts
create_custom_motd

echo "MOTD customization complete. Please log out and back in to see the changes."
echo "If this is a new container/VM, a reboot might be beneficial for all services."

# --- cleanup ---
# remove the temporary downloaded host-db file
if [[ -f "$LOCAL_HOST_DB_PATH" ]]; then
    rm "$LOCAL_HOST_DB_PATH"
    echo "Cleaned up temporary host-db file: $LOCAL_HOST_DB_PATH"
fi
