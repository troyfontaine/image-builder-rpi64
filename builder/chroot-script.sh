#!/bin/bash
set -ex

KEYSERVER="ha.pool.sks-keyservers.net"

function clean_print(){
  local fingerprint="${2}"
  local func="${1}"

  nospaces=${fingerprint//[:space:]/}
  tolowercase=${nospaces,,}
  KEYID_long=${tolowercase:(-16)}
  KEYID_short=${tolowercase:(-8)}
  if [[ "${func}" == "fpr" ]]; then
    echo "${tolowercase}"
  elif [[ "${func}" == "long" ]]; then
    echo "${KEYID_long}"
  elif [[ "${func}" == "short" ]]; then
    echo "${KEYID_short}"
  elif [[ "${func}" == "print" ]]; then
    if [[ "${fingerprint}" != "${nospaces}" ]]; then
      printf "%-10s %50s\n" fpr: "${fingerprint}"
    fi
    # if [[ "${nospaces}" != "${tolowercase}" ]]; then
    #   printf "%-10s %50s\n" nospaces: $nospaces
    # fi
    if [[ "${tolowercase}" != "${KEYID_long}" ]]; then
      printf "%-10s %50s\n" lower: "${tolowercase}"
    fi
    printf "%-10s %50s\n" long: "${KEYID_long}"
    printf "%-10s %50s\n" short: "${KEYID_short}"
    echo ""
  else
    echo "usage: function {print|fpr|long|short} GPGKEY"
  fi
}


function get_gpg(){
  GPG_KEY="${1}"
  KEY_URL="${2}"

  clean_print print "${GPG_KEY}"
  GPG_KEY=$(clean_print fpr "${GPG_KEY}")

  if [[ "${KEY_URL}" =~ ^https?://* ]]; then
    echo "loading key from url"
    KEY_FILE=temp.gpg.key
    wget -q -O "${KEY_FILE}" "${KEY_URL}"
  elif [[ -z "${KEY_URL}" ]]; then
    echo "no source given try to load from key server"
#    gpg --keyserver "${KEYSERVER}" --recv-keys "${GPG_KEY}"
    apt-key adv --keyserver "${KEYSERVER}" --recv-keys "${GPG_KEY}"
    return $?
  else
    echo "keyfile given"
    KEY_FILE="${KEY_URL}"
  fi

  FINGERPRINT_OF_FILE=$(gpg --with-fingerprint --with-colons "${KEY_FILE}" | grep fpr | rev |cut -d: -f2 | rev)

  if [[ ${#GPG_KEY} -eq 16 ]]; then
    echo "compare long keyid"
    CHECK=$(clean_print long "${FINGERPRINT_OF_FILE}")
  elif [[ ${#GPG_KEY} -eq 8 ]]; then
    echo "compare short keyid"
    CHECK=$(clean_print short "${FINGERPRINT_OF_FILE}")
  else
    echo "compare fingerprint"
    CHECK=$(clean_print fpr "${FINGERPRINT_OF_FILE}")
  fi

  if [[ "${GPG_KEY}" == "${CHECK}" ]]; then
    echo "key OK add to apt"
    apt-key add "${KEY_FILE}"
    rm -f "${KEY_FILE}"
    return 0
  else
    echo "key invalid"
    exit 1
  fi
}

## examples:
# clean_print {print|fpr|long|short} {GPGKEYID|FINGERPRINT}
# get_gpg {GPGKEYID|FINGERPRINT} [URL|FILE]

# device specific settings
HYPRIOT_DEVICE="Raspberry Pi 3 64bit"

# set up /etc/resolv.conf
DEST=$(readlink -m /etc/resolv.conf)
export DEST
mkdir -p "$(dirname "${DEST}")"
echo "nameserver 8.8.8.8" > "${DEST}"

# reload package sources
apt-get update
apt-get upgrade -y

# # install WiFi firmware packages (same as in Raspbian)
# apt-get install -y \
#   firmware-atheros \
#   firmware-brcm80211 \
#   firmware-libertas \
#   firmware-ralink \
#   firmware-realtek

# install WiFi firmware for internal RPi3 WiFi module
mkdir -p /lib/firmware/brcm
curl -sSL https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm80211/brcm/brcmfmac43430-sdio.bin > /lib/firmware/brcm/brcmfmac43430-sdio.bin
curl -sSL https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm80211/brcm/brcmfmac43430-sdio.txt > /lib/firmware/brcm/brcmfmac43430-sdio.txt

# install kernel- and firmware-packages
# apt-get install -y \
#   "raspberrypi-kernel=${KERNEL_BUILD}" \
#   "raspberrypi-bootloader=${KERNEL_BUILD}" \
#   "libraspberrypi0=${KERNEL_BUILD}" \
#   "libraspberrypi-dev=${KERNEL_BUILD}" \
#   "libraspberrypi-bin=${KERNEL_BUILD}"

# enable serial console
printf "# Spawn a getty on Raspberry Pi serial line\nT0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100\n" >> /etc/inittab

# boot/cmdline.txt
echo "dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 cgroup_enable=cpuset cgroup_memory=1 swapaccount=1 elevator=deadline fsck.repair=yes rootwait console=ttyAMA0,115200 net.ifnames=0" > /boot/cmdline.txt
# " net.ifnames=0" is neccessary for Debian Stretch: see https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/

# create a default boot/config.txt file (details see http://elinux.org/RPiconfig)
echo "
# enable UART console on GPIO pins
enable_uart=1
hdmi_force_hotplug=1
" > boot/config.txt

# echo "# camera settings, see http://elinux.org/RPiconfig#Camera
# start_x=1
# disable_camera_led=1
# gpu_mem=128
# " >> boot/config.txt

echo "# setting for maximum memory, gpu_mem to minimum 16M, camera off
start_x=0
gpu_mem=16
" >> boot/config.txt

# # /etc/modules
# echo "snd_bcm2835
# " >> /etc/modules

# create /etc/fstab
echo "
proc /proc proc defaults 0 0
/dev/mmcblk0p1 /boot vfat defaults 0 0
/dev/mmcblk0p2 / ext4 defaults,noatime 0 1
" > /etc/fstab

# as the Pi does not have a hardware clock we need a fake one
apt-get install -y \
  fake-hwclock

# install packages for managing wireless interfaces
apt-get install -y \
  wpasupplicant \
  wireless-tools \
  ethtool \
  crda

# # add firmware and packages for managing bluetooth devices
# apt-get install -y \
#   --no-install-recommends \
#   bluetooth \
#   pi-bluetooth
apt-get install -y \
  --no-install-recommends \
  bluetooth

# ensure compatibility with Docker install.sh, so `raspbian` will be detected correctly
apt-get install -y \
  lsb-release

# install cloud-init and its required dependencies
apt-get install -y \
  cloud-init \
  dirmngr \
  less

mkdir -p /var/lib/cloud/seed/nocloud-net
ln -s /boot/user-data /var/lib/cloud/seed/nocloud-net/user-data
ln -s /boot/meta-data /var/lib/cloud/seed/nocloud-net/meta-data

#TODO:---

echo "Installing rpi-serial-console script"
wget -q https://raw.githubusercontent.com/lurch/rpi-serial-console/master/rpi-serial-console -O usr/local/bin/rpi-serial-console
chmod +x usr/local/bin/rpi-serial-console

# cleanup APT cache and lists
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set device label and version number
cat <<EOF >> /etc/os-release
HYPRIOT_BOOTLOADER_BUILD="${BOOTLOADER_BUILD}"
HYPRIOT_KERNEL_BUILD="${KERNEL_BUILD}"
HYPRIOT_KERNEL_VERSION="${KERNEL_VERSION}"
HYPRIOT_DEVICE="$HYPRIOT_DEVICE"
HYPRIOT_IMAGE_VERSION="$HYPRIOT_IMAGE_VERSION"
EOF
cp /etc/os-release /boot/os-release
