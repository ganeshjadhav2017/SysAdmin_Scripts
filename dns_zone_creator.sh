#!/bin/bash

# Exit on error
set -e

# Debugging: Print script start time
echo "Script started at $(date)"

# Function to install BIND9 if not already installed
install_bind9() {
    if ! command -v named &> /dev/null; then
        echo "BIND9 (named) is not installed. Installing BIND9..."
        if command -v apt &> /dev/null; then
            # Debian/Ubuntu
            sudo apt update
            sudo apt install -y bind9 bind9-utils
        elif command -v dnf &> /dev/null; then
            # CentOS/RHEL (using dnf as per your request)
            sudo dnf install -y bind bind-utils
        else
            echo "Error: Unsupported package manager. Please install BIND9 manually."
            exit 1
        fi
        echo "BIND9 installed successfully."
    else
        echo "BIND9 is already installed."
    fi
}

# Check if named service exists and install if needed
if ! systemctl is-active --quiet named; then
    echo "named service is not active or installed."
    install_bind9
else
    echo "named service is active."
fi

# Input validation functions
validate_domain() {
    if [[ ! "$1" =~ ^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+[a-zA-Z]{2,}$ ]]; then
        echo "Error: Invalid domain name."
        exit 1
    fi
}

validate_ip() {
    if [[ ! "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "Error: Invalid IP address."
        exit 1
    fi
}

validate_email() {
    if [[ ! "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Error: Invalid email address."
        exit 1
    fi
}

# Function to extract the main domain
extract_main_domain() {
    local domain="$1"
    echo "$domain" | awk -F'.' '{if (NF >= 2) {print $(NF-1)"."$NF} else {print $0}}'
}

# Prompt user for inputs
read -p "Enter domain name (e.g., sub.example.com): " DOMAIN
validate_domain "$DOMAIN"

read -p "Enter nameserver IP (e.g., 192.168.1.1): " NAMESERVER_IP
validate_ip "$NAMESERVER_IP"

read -p "Enter admin email (e.g., admin@example.com): " ADMIN_EMAIL
validate_email "$ADMIN_EMAIL"

read -p "Enter server IP: " SERVER_IP
validate_ip "$SERVER_IP"

read -p "Enter mail server IP: " MAIL_SERVER_IP
validate_ip "$MAIL_SERVER_IP"

# Debugging: Print user inputs
echo "DOMAIN: $DOMAIN"
echo "NAMESERVER_IP: $NAMESERVER_IP"
echo "ADMIN_EMAIL: $ADMIN_EMAIL"
echo "SERVER_IP: $SERVER_IP"
echo "MAIL_SERVER_IP: $MAIL_SERVER_IP"

# Extract the main domain
MAIN_DOMAIN=$(extract_main_domain "$DOMAIN")
echo "Main domain: $MAIN_DOMAIN"

# Create zones directory if it doesn't exist
ZONES_DIR="/etc/bind/zones"
if [ ! -d "$ZONES_DIR" ]; then
    echo "Creating zones directory: $ZONES_DIR"
    sudo mkdir -p "$ZONES_DIR"
fi

# Define the zone file for the main domain
ZONE_FILE="$ZONES_DIR/$MAIN_DOMAIN.zone"
echo "Zone file: $ZONE_FILE"

# Check if the zone file for the main domain already exists
if [ -f "$ZONE_FILE" ]; then
    echo "Zone file for main domain $MAIN_DOMAIN already exists. Adding subdomain records..."
else
    echo "Creating a new zone file for main domain $MAIN_DOMAIN..."
    # Create a new zone file for the main domain
    cat << EOF > "$ZONE_FILE"
\$TTL 86400
@   IN  SOA $NAMESERVER_IP. $ADMIN_EMAIL. (
                $(date +%Y%m%d%H) ; Serial
                3600       ; Refresh
                1800       ; Retry
                604800     ; Expire
                86400      ; Minimum TTL
                )

; Name servers
@               IN  NS  $NAMESERVER_IP.

; A records
@               IN  A   $SERVER_IP

; MX records
@               IN  MX  10  mail.$MAIN_DOMAIN.

; Mail server
mail            IN  A   $MAIL_SERVER_IP
EOF
fi

# Append subdomain records to the zone file
if [[ "$DOMAIN" != "$MAIN_DOMAIN" ]]; then
    echo "Adding subdomain records for $DOMAIN..."
    cat << EOF >> "$ZONE_FILE"
; Subdomain records
$DOMAIN         IN  A   $SERVER_IP
EOF
fi

# Set correct permissions and ownership
sudo chown root:bind "$ZONE_FILE"
sudo chmod 640 "$ZONE_FILE"

# Backup existing BIND9 configuration
BACKUP_FILE="/etc/bind/named.conf.local.$(date +%Y%m%d%H%M%S).bak"
sudo cp /etc/bind/named.conf.local "$BACKUP_FILE"
echo "Backup of named.conf.local created at $BACKUP_FILE."

# Update BIND9 configuration to include the main domain zone (if not already present)
if ! grep -q "zone \"$MAIN_DOMAIN\"" /etc/bind/named.conf.local; then
    echo "Adding zone configuration for $MAIN_DOMAIN to named.conf.local..."
    echo "zone \"$MAIN_DOMAIN\" {
        type master;
        file \"$ZONE_FILE\";
    };" | sudo tee -a /etc/bind/named.conf.local
fi

# Validate the zone file
if ! named-checkzone "$MAIN_DOMAIN" "$ZONE_FILE"; then
    echo "Error: Zone file validation failed."
    exit 1
fi

# Restart BIND9 to apply changes
if sudo systemctl restart bind9; then
    echo "BIND9 restarted successfully."
else
    echo "Error: Failed to restart BIND9."
    exit 1
fi

# Display appropriate success message
if [[ "$DOMAIN" == "$MAIN_DOMAIN" ]]; then
    echo "DNS zone for $DOMAIN has been set up successfully."
else
    echo "DNS zone for $DOMAIN has been set up successfully under the main domain $MAIN_DOMAIN."
fi
