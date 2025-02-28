#!/bin/bash

# Exit on error
set -e

# Logging
LOG_FILE="/var/log/dns_setup.log"
echo "Script started at $(date)" >> "$LOG_FILE"
exec >> "$LOG_FILE" 2>&1

# Function to install BIND9 if not already installed
install_bind9() {
    if ! command -v named &> /dev/null; then
        echo "BIND9 (named) is not installed. Installing BIND9..."
        if command -v apt &> /dev/null; then
            # Debian/Ubuntu
            sudo apt update
            sudo apt install -y bind9 bind9-utils
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            sudo yum install -y bind bind-utils
        else
            echo "Error: Unsupported package manager. Please install BIND9 manually."
            exit 1
        fi
        echo "BIND9 installed successfully."
    else
        echo "BIND9 is already installed."
    fi
}

# Install BIND9 if not installed
install_bind9

# Input validation functions
validate_domain() {
    if [[ ! "<span class="math-inline">1" \=\~ ^\(\[a\-zA\-Z0\-9\]\+\(\-\[a\-zA\-Z0\-9\]\+\)\*\\\.\)\+\[a\-zA\-Z\]\{2,\}</span> ]]; then
        echo "Error: Invalid domain name."
        exit 1
    fi
}

validate_ip() {
    if [[ ! "<span class="math-inline">1" \=\~ ^\(\[0\-9\]\{1,3\}\\\.\)\{3\}\[0\-9\]\{1,3\}</span> ]]; then
        echo "Error: Invalid IP address."
        exit 1
    fi
    local octet
    for octet in $(echo "$1" | tr "." " "); do
        if [[ "$octet" -lt 0 || "$octet" -gt 255 ]]; then
            echo "Error: Invalid IP address octet."
            exit 1
        fi
    done
}

validate_email() {
    if [[ ! "<span class="math-inline">1" \=\~ ^\[a\-zA\-Z0\-9\.\_%\+\-\]\+@\[a\-zA\-Z0\-9\.\-\]\+\\\.\[a\-zA\-Z\]\{2,\}</span> ]]; then
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
validate_ip "<span class="math-inline">MAIL\_SERVER\_IP"
\# Extract the main domain
MAIN\_DOMAIN\=</span>(extract_main_domain "$DOMAIN")

# Create zones directory if it doesn't exist
ZONES_DIR="/etc/bind/zones"
if [ ! -d "$ZONES_DIR" ]; then
    mkdir -p "$ZONES_DIR"
fi

# Define the zone file for the main domain
ZONE_FILE="$ZONES_DIR/$MAIN_DOMAIN.zone"

# Check if the zone file for the main domain already exists
if [ -f "$ZONE_FILE" ]; then
    echo "Zone file for main domain $MAIN_DOMAIN already exists. Adding subdomain records..."
else
    echo "Creating a new zone file for main domain <span class="math-inline">MAIN\_DOMAIN\.\.\."
\# Create a new zone file for the main domain
ADMIN\_EMAIL\_BIND\=</span>(echo "<span class="math-inline">ADMIN\_EMAIL" \| sed 's/@/\./'\)
SERIAL\=</span>(date +%Y%m%d%H%M) #more accurate serial number
    cat << EOF > "$ZONE_FILE"
\$TTL 86400
@    IN    SOA $NAMESERVER_IP. $ADMIN_EMAIL_BIND. (
                                $SERIAL ; Serial
                                3600         ; Refresh
                                1800         ; Retry
                                604800       ; Expire
                                86400        ; Minimum TTL
                                )

; Name servers
@                IN    NS    $NAMESERVER_IP.

; A records
@                IN    A     $SERVER_IP

; MX records
@                IN    MX    10    mail.$MAIN_DOMAIN.

; Mail server
mail             IN    A     $MAIL_SERVER_IP
EOF
fi

# Append subdomain records to the zone file
if [[ "$DOMAIN" != "$MAIN_DOMAIN" ]]; then
    echo "Adding subdomain records for $DOMAIN..."
    cat << EOF >> "$ZONE_FILE"
; Subdomain records
$DOMAIN                IN    A     $SERVER_IP
EOF
fi

# Set correct permissions and ownership
chown root:bind "$ZONE_FILE"
chmod 640 "<span class="math-inline">ZONE\_FILE"
\# Backup existing BIND9 configuration
BACKUP\_FILE\="/etc/bind/named\.conf\.local\.</span>(date +%Y%m%d%H%M%S).bak"
cp /etc/bind/named.conf.local "$BACKUP_FILE"
echo "Backup of named.conf.local created at $BACKUP_FILE."

# Update BIND9 configuration to include the main domain zone (if not already present)
if ! grep -q "zone \"$MAIN_DOMAIN\"" /etc/bind/named.conf.local; then
    echo "Adding zone configuration for $MAIN_DOMAIN to named.conf.local..."
    echo "zone \"$MAIN_DOMAIN\" {
        type master;
        file \"$ZONE_FILE\";
    };" >> /etc/bind/named.conf.local
fi

# Validate the zone file
if ! named-checkzone "$MAIN_DOMAIN" "$ZONE_FILE"; then
    echo "Error: Zone

# Restart BIND9 to apply changes
if systemctl restart bind9; then
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
