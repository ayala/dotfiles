# This is the host-db file for custom Proxmox container/VM MOTDs.
# Each custom banner should be enclosed between #START_HOST: and #END_HOST: markers.
# The hostname in the marker should exactly match the actual hostname of the CT/VM.
# Blank lines within the banner content will be preserved.

# --- Example 1: Custom banner for 'pve-ct-debian' ---
# If a host matches 'pve-ct-debian', this banner will be used.
# Otherwise, figlet will generate a banner from its hostname.
# You can use ASCII art, UTF-8 characters, or anything you like here.

#START_HOST:plex
 ┌─────────────────────────────────────╮
 │  ____ _ ____ _    ____ ___          │
 │  |--  | |__, |___ |-__  |   SLIVER  │
 │                                     │
 ╰─────────────────────────────────────╯
 __________________________________________
|                                          |
|  Welcome to your Debian Proxmox Container|
|  ╦ ╦╔═╗╦╔═╦╔╦╗╔═╗╔╗╔                      |
|  ║║║║╣ ╠╩╗║ ║║║╣ ║║║                      |
|  ╚╩╝╚═╝╩ ╩╩═╩╝╚═╝╝╚╝                      |
|                                          |
|__________________________________________|
#END_HOST:plex


# --- Example 2: Custom banner for 'webserver-01' ---
# This banner shows a simple design with some blank lines for spacing.

#START_HOST:webserver-01
   _ __ ___   __ _  ___ ___
  | '_ ` _ \ / _` |/ __/ __|
  | | | | | | (_| | (__\__ \
  |_| |_| |_|\__,_|\___|___/

       Web Server Node

       All systems nominal.
#END_HOST:webserver-01


# --- Example 3: Custom banner for 'db-server' with a different ASCII style ---

#START_HOST:db-server
  ______   ____  _______
 |  ____| | __ )|__   __|
 | |__    |  _ \   | |
 |  __|   | |_) |  | |
 | |____  |  _ <   | |
 |______| |____/   |_|

 _______________________________
|                               |
|  Database Server - Production |
|_______________________________|
#END_HOST:db-server


# Any host not listed here will fall back to the figlet-generated banner.


 ┌─────────────────────────────────────╮
 │  ____ _ ____ _    ____ ___          │
 │  |--  | |__, |___ |-__  |   SLIVER  │
 │                                     │
 ╰─────────────────────────────────────╯
