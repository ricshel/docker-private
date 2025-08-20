#!/usr/bin/env bash
set -euo pipefail

# --- sanity: tools ---
need() { command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need mdadm; need parted; need cryptsetup; need sgdisk; need wipefs; need blkid; need udevadm

# --- args/root ---
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
[[ $# -eq 2 ]] || { echo "Usage: $0 /dev/sdX /dev/sdY"; exit 1; }

DISK_A="$(readlink -f "$1")"
DISK_B="$(readlink -f "$2")"
[[ -b "$DISK_A" && -b "$DISK_B" ]] || { echo "Both args must be block devices"; exit 1; }
[[ "$DISK_A" != "$DISK_B" ]] || { echo "DISK_A and DISK_B must differ"; exit 1; }

echo "About to WIPE and rebuild RAID1+LUKS+ext4 on:"
ls -l "$DISK_A" "$DISK_B" || true
read -rp "Type EXACTLY 'DESTROY' to continue: " CONF
[[ "$CONF" == "DESTROY" ]]

# --- refuse if anything under these disks is mounted (e.g., /, /boot, etc.) ---
for d in "$DISK_A" "$DISK_B"; do
  if lsblk -nr -o MOUNTPOINT "$d" | grep -q .; then
    echo "Refusing: something on $d is mounted. Unmount first."; exit 1
  fi
done

# --- stop any previous stack (ignore errors) ---
umount -R /mnt/secure_data 2>/dev/null || true
cryptsetup close secure_raid 2>/dev/null || true
mdadm --stop /dev/md0 2>/dev/null || true

# --- wipe old signatures/metadata ---
mdadm --zero-superblock "$DISK_A" "$DISK_B" 2>/dev/null || true
mdadm --zero-superblock "${DISK_A}1" "${DISK_B}1" 2>/dev/null || true
wipefs -a "$DISK_A" "$DISK_B"
sgdisk --zap-all "$DISK_A"
sgdisk --zap-all "$DISK_B"
blkdiscard "$DISK_A" 2>/dev/null || true
blkdiscard "$DISK_B" 2>/dev/null || true

# --- partition (GPT, single RAID partition) ---
parted -s "$DISK_A" mklabel gpt mkpart primary 1MiB 100% set 1 raid on
parted -s "$DISK_B" mklabel gpt mkpart primary 1MiB 100% set 1 raid on
udevadm settle

PART_A="${DISK_A}1"   # for /dev/sdX this is /dev/sdX1
PART_B="${DISK_B}1"

# --- create RAID2 with internal bitmap ---
mdadm --create /dev/md0 --level=1 --raid-devices=2 --metadata=1.2 --bitmap=internal \
  "$PART_A" "$PART_B"
udevadm settle

# --- keyfile + LUKS ---
mkdir -p /etc/keys
if [[ ! -f /etc/keys/raid.key ]]; then
  dd if=/dev/urandom of=/etc/keys/raid.key bs=64 count=1 status=none
  chmod 600 /etc/keys/raid.key
fi
cryptsetup luksFormat /dev/md0 --type luks2 --pbkdf argon2id --key-file /etc/keys/raid.key
cryptsetup open /dev/md0 secure_raid --key-file /etc/keys/raid.key

# --- filesystem + mount ---
mkfs.ext4 -L secure_raid /dev/mapper/secure_raid
mkdir -p /mnt/secure_data
mount /dev/mapper/secure_raid /mnt/secure_data

# --- persist RAID assembly ---
cp /etc/mdadm/mdadm.conf /etc/mdadm/mdadm.conf.bak.$(date +%s) 2>/dev/null || true
mdadm --detail --scan > /etc/mdadm/mdadm.conf
update-initramfs -u

# --- crypttab (auto-unlock on boot) ---
if grep -qE '^secure_raid\s' /etc/crypttab 2>/dev/null; then
  sed -i 's|^secure_raid.*$|secure_raid /dev/md0 /etc/keys/raid.key luks,discard|' /etc/crypttab
else
  echo 'secure_raid /dev/md0 /etc/keys/raid.key luks,discard' >> /etc/crypttab
fi

# --- fstab (auto-mount on boot) ---
FSUUID=$(blkid -s UUID -o value /dev/mapper/secure_raid)
grep -q "$FSUUID" /etc/fstab 2>/dev/null || echo "UUID=$FSUUID /mnt/secure_data ext4 defaults 0 2" >> /etc/fstab

echo
echo "=== Done ==="
lsblk -f
mdadm --detail /dev/md0 || true
cryptsetup status secure_raid || true
df -h /mnt/secure_data || true

# echo
# echo "Recommended once: "
# echo "  cryptsetup luksHeaderBackup /dev/md0 --header-backup-file /root/md0.luksHeader.bin"
# echo "  gpg -c -o /root/raid.key.gpg /etc/keys/raid.key (move both OFF the box)"
