#!/bin/sh

# figlet x lolcat — Custom CLI MOTD prompts
# Version : 1.0
# Last Updated: 28/01/2025

# Function to display a spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr="\|/-"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

echo "Setting up your custom CLI MOTD prompts..."

cat << EOF

 ┌─────────────────────────────────────╮
 │  ____ _ ____ _    ____ ___          │
 │  |--  | |__, |___ |-__  |   SLIVER  │
 │                                     │
 ╰─────────────────────────────────────╯

EOF

echo "----------------------------------------------------"
echo "Starting installation and setup process:"
echo "----------------------------------------------------"
echo ""

# Step 1: Install dependencies figlet and lolcat
printf "Installing figlet and lolcat... "
(sudo apt install -y figlet lolcat > /dev/null 2>&1) & spinner $!
if [ $? -eq 0 ]; then
    echo "Done."
else
    echo "Failed. Please ensure you have apt and sudo configured correctly."
    exit 1
fi
echo ""

# Step 2: Download sliver.flf directly
printf "Downloading sliver.flf to /usr/share/figlet/... "
(sudo wget -q -O /usr/share/figlet/sliver.flf https://raw.githubusercontent.com/ayala/dotfiles/refs/heads/main/homelab/config/data/sliver.flf) & spinner $!
if [ $? -eq 0 ]; then
    echo "Done."
else
    echo "Failed. Could not download or copy sliver.flf. Check your internet connection or permissions."
    exit 1
fi
echo ""

# Step 3: Move lolcat executable
printf "Moving lolcat executable to /usr/local/bin/... "
(sudo mv /usr/games/lolcat /usr/local/bin/ > /dev/null 2>&1) & spinner $!
if [ $? -eq 0 ]; then
    echo "Done."
else
    echo "Failed. Could not move lolcat. It might not be in /usr/games/lolcat or you lack permissions."
    exit 1
fi
echo ""

# Final MOTD display
printf "Displaying final confirmation of custom font and color... "
(echo "") & spinner $!
(figlet -f "sliver.flf" "figlet installed" | lolcat && echo "") 
echo "Done."
echo ""

echo "Setup complete! Enjoy your custom MOTD."
