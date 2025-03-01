curl -O https://raw.githubusercontent.com/ganeshjadhav2017/SysAdmin_Scripts/refs/heads/main/dns_zone_creator.sh && bash dns_zone_creator.sh

Automating DNS zone setup for local virtual Linux servers without relying on control panels can save a lot of time and effort, especially when managing multiple domains or subdomains. Here's a summary of how this script fits into this use case and why it's useful:

**Use Case: Local Virtual Linux Servers**

You are managing local virtual Linux servers (e.g., using VirtualBox, VMware, or KVM) and need to:

    Quickly set up DNS zones for domains and subdomains.

    Avoid using control panels (e.g., cPanel, Plesk) for simplicity or resource efficiency.

    Ensure consistency and correctness in DNS configurations.
---

### **Script Purpose:**
The script automates the setup of DNS zones for both **main domains** (e.g., `example.com`) and **subdomains** (e.g., `sub.example.com`) using BIND9. It ensures that:
1. Subdomains are added under the main domain's zone file.
2. Main domains have their own zone file created if it doesn't already exist.
3. The DNS configuration is validated and applied correctly.

---

### **Key Functionality:**
1. **User Inputs**:
   - Prompts the user for:
     - Domain name (e.g., `example.com` or `sub.example.com`).
     - Nameserver IP.
     - Admin email.
     - Server IP.
     - Mail server IP.
   - Validates all inputs for correctness (e.g., valid domain, IP, and email formats).

2. **Main Domain Extraction**:
   - Extracts the **main domain** from the provided domain name (e.g., `example.com` from `sub.example.com`).

3. **Zone File Management**:
   - Creates a new zone file for the **main domain** if it doesn't exist.
   - Appends **subdomain records** to the main domain's zone file if the domain is a subdomain.

4. **BIND9 Configuration**:
   - Updates the BIND9 configuration (`named.conf.local`) to include the main domain's zone.
   - Backs up the existing BIND9 configuration before making changes.

5. **Validation and Restart**:
   - Validates the zone file using `named-checkzone`.
   - Restarts the BIND9 service to apply changes.

6. **User Feedback**:
   - Provides clear, context-specific success messages:
     - For **main domains**: `DNS zone for example.com has been set up successfully.`
     - For **subdomains**: `DNS zone for sub.example.com has been set up successfully under the main domain example.com.`

---

### **Example Use Cases:**
1. **Main Domain Setup**:
   - Input: `example.com`
   - Action: Creates a new zone file for `example.com`.
   - Output: `DNS zone for example.com has been set up successfully.`

2. **Subdomain Setup**:
   - Input: `sub.example.com`
   - Action: Appends `sub.example.com` records to the existing `example.com.zone` file.
   - Output: `DNS zone for sub.example.com has been set up successfully under the main domain example.com.`

---

### **Key Benefits:**
- **Automation**: Simplifies DNS zone setup for both main domains and subdomains.
- **Error Handling**: Validates inputs and ensures proper configuration.
- **Flexibility**: Handles both new and existing zone files.
- **Clarity**: Provides clear, context-specific feedback to the user.

---

This script is ideal for system administrators managing DNS zones with BIND9, ensuring consistency and reducing manual errors.
