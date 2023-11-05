#!/bin/bash

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt update -y
sudo apt upgrade -y

# Set up a basic firewall using UFW (Uncomplicated Firewall)
echo "Setting up a basic firewall using UFW (Uncomplicated Firewall)..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# Enable and configure SSH for better security
# echo "Enabling and configuring SSH for better security..."
# sudo apt install openssh-server
# sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
# sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
# sudo systemctl restart ssh

# Set up fail2ban to protect against brute force attacks
echo "Setting up fail2ban to protect against brute force attacks..."
sudo apt install fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Stop and disable unnecessary services
echo "Stopping and disabling unnecessary services..."
sudo systemctl stop apache2
sudo systemctl disable apache2

# Harden the sysctl settings
echo "Harden the sysctl settings..."
echo "net.ipv4.tcp_syncookies=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.ip_forward=0" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects=0" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Check if all users have a password
echo "Checking if all users have a password..."
users_without_password=$(awk -F: '$2 == "" {print $1}' /etc/shadow)
if [ -n "$users_without_password" ]; then
    echo "Warning: The following users do not have a password set:"
    echo "$users_without_password"
fi

# Add a lockout policy for failed login attempts
echo "Adding a lockout policy for failed login attempts..."
cp /etc/pam.d/common-auth /etc/pam.d/common-auth~
echo "auth [success=1 default=ignore] pam_unix.so nullok_secure 
auth required pam_deny.so 	#was requisite
auth required pam_permit.so
auth required pam_tally2.so onerr=fail deny=3 unlock_time=1800" > /etc/pam.d/common-auth

# Restrict cron job setting to root user only
echo "Restricting cron job setting to root user only..."
echo "root" | sudo tee /etc/cron.allow
echo "ALL" | sudo tee /etc/cron.deny

# Check if outside packets are claiming to be from the loopback interface
echo "Checking if outside packets are claiming to be from the loopback interface..."
apt-get install iptables -y -qq
iptables -A INPUT -p all -s localhost  -i eth0 -j DROP

# Check for users with UID 0 and reassign their UIDs to random values
echo "Checking for users with UID 0 and reassigning their UIDs to random values..."
while IFS=: read -r user _ uid _; do
    if [ "$uid" -eq 0 ] && [ "$user" != "root" ]; then
        new_uid=$(shuf -i 1000-9999 -n 1)  # Generates a random UID between 1000 and 9999
        echo "Fixing $user UID to $new_uid..."
        sudo usermod -u "$new_uid" "$user"
    fi
done </etc/passwd

# Ensure root UID is set to 0
echo "Ensuring root UID is set to 0..."
root_uid=$(id -u root)
if [ "$root_uid" -ne 0 ]; then
    echo "Fixing root UID..."
    sudo usermod -u 0 root
fi

# Change persmissions on sensitive files
echo "Changing permissions on sensitive files..."
chown root:root /etc/securetty
chmod 0600 /etc/securetty
chmod 644 /etc/crontab
chmod 640 /etc/ftpusers
chmod 440 /etc/inetd.conf
chmod 440 /etc/xinetd.conf
chmod 400 /etc/inetd.d
chmod 644 /etc/hosts.allow
chmod 440 /etc/sudoers
chmod 640 /etc/shadow
chown root:root /etc/shadow

# Configure LightDM to hide users, require a username, and not allow guests
echo "Configuring LightDM to hide users and require a username..."
echo "[SeatDefaults]" | sudo tee -a /etc/lightdm/lightdm.conf
echo "greeter-show-manual-login=true" | sudo tee -a /etc/lightdm/lightdm.conf
echo "greeter-hide-users=true" | sudo tee -a /etc/lightdm/lightdm.conf
echo "allow-guest=false" | sudo tee -a /etc/lightdm/lightdm.conf


# Set up periodic system updates and security checks
echo "Setting up periodic system updates and security checks..."
sudo apt install unattended-upgrades
echo 'APT::Periodic::Enable "1";' | sudo tee -a /etc/apt/apt.conf.d/10periodic
echo 'APT::Periodic::Download-Upgradeable-Packages "1";' | sudo tee -a /etc/apt/apt.conf.d/10periodic
echo 'APT::Periodic::AutocleanInterval "7";' | sudo tee -a /etc/apt/apt.conf.d/10periodic
echo 'APT::Periodic::Unattended-Upgrade "1";' | sudo tee -a /etc/apt/apt.conf.d/10periodic

# Remove unnecessary packages
sudo apt autoremove