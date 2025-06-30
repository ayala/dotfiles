#!/bin/bash

# This script aims to disable the "Last login" message for both direct logins
# (via console/TTY) and SSH logins within a Linux environment, especially useful in containers.

# --- Method 1: Disable Last Login Message using ~/.hushlogin (Per-user) ---
# This method creates a .hushlogin file in the current user's home directory.
# Most login programs (like `login` for console access) check for this file
# and suppress the "Last login" message if it exists.

echo "Attempting to create ~/.hushlogin for the current user..."
touch "$HOME/.hushlogin"

if [ -f "$HOME/.hushlogin" ]; then
    echo "~/.hushlogin created successfully for user: $(whoami)"
    echo "This should suppress 'Last login' message for direct logins."
else
    echo "Error: Could not create ~/.hushlogin. Check permissions."
fi

echo "" # Add a blank line for readability

# --- Method 2: Disable Last Login Message in SSH Server Configuration (for SSH logins) ---
# This method modifies the sshd_config file to prevent the SSH daemon from printing
# the last login time. This requires root privileges and restarting the SSH service.

echo "Attempting to modify SSH server configuration (sshd_config)..."

# Check if sshd_config exists
SSH_CONFIG="/etc/ssh/sshd_config"
if [ ! -f "$SSH_CONFIG" ]; then
    echo "Warning: SSH server configuration file ($SSH_CONFIG) not found."
    echo "This part of the script will not have an effect if SSH is not installed or configured differently."
else
    # Check if the script is running as root
    if [ "$EUID" -ne 0 ]; then
        echo "You need to run this script with sudo or as root to modify $SSH_CONFIG and restart SSH."
        echo "Skipping SSH configuration modification and service restart."
    else
        # Backup the original sshd_config before modifying
        if [ ! -f "${SSH_CONFIG}.bak" ]; then
            cp "$SSH_CONFIG" "${SSH_CONFIG}.bak"
            echo "Backup of sshd_config created at ${SSH_CONFIG}.bak"
        else
            echo "Backup of sshd_config already exists at ${SSH_CONFIG}.bak"
        fi

        # Use sed to find and replace the PrintLastLog setting
        # The 's/^#?PrintLastLog yes/PrintLastLog no/' part:
        # ^#?   - Matches the start of the line, optionally followed by a '#' (for commented lines)
        # PrintLastLog yes - Matches the string "PrintLastLog yes"
        # PrintLastLog no - Replaces it with "PrintLastLog no"
        sed -i 's/^#?PrintLastLog yes/PrintLastLog no/' "$SSH_CONFIG"

        if grep -q "PrintLastLog no" "$SSH_CONFIG"; then
            echo "Successfully set 'PrintLastLog no' in $SSH_CONFIG"

            # Restart SSH service
            echo "Attempting to restart SSH service..."
            if systemctl restart sshd 2>/dev/null; then
                echo "SSH service (sshd) restarted successfully using systemctl."
            elif service ssh restart 2>/dev/null; then
                echo "SSH service (ssh) restarted successfully using service."
            else
                echo "Warning: Could not restart SSH service automatically."
                echo "You may need to manually restart it using 'sudo systemctl restart sshd' or 'sudo service ssh restart'."
            fi
        else
            echo "Failed to set 'PrintLastLog no' in $SSH_CONFIG. Manual intervention might be needed."
        fi
    fi
fi

echo "" # Add a blank line for readability
echo "Script execution completed."
echo "Please re-login (or create a new SSH connection) to see the effects."
