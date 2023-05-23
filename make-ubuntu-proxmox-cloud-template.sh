#!/bin/bash

set -eu

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

UBUNTU_VERSION="${UBUNTU_VERSION:-jammy}"
VM_ID="${VM_ID:-8000}"

WORK_DIR="$(mktemp -d)"
trap "rm -f ${WORK_DIR}-server-cloudimg-amd64.img" EXIT

pushd "${WORK_DIR}"

wget "https://cloud-images.ubuntu.com/${UBUNTU_VERSION}/current/${UBUNTU_VERSION}-server-cloudimg-amd64.img"

/usr/sbin/qm create ${VM_ID} --memory 2048 --core 2 --name ${UBUNTU_VERSION}-cloud --net0 virtio,bridge=vmbr0
/usr/sbin/qm importdisk ${VM_ID} "${UBUNTU_VERSION}-server-cloudimg-amd64.img" data-lvm
/usr/sbin/qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 data-lvm:vm-${VM_ID}-disk-0
/usr/sbin/qm set ${VM_ID} --ide2 data-lvm:cloudinit
/usr/sbin/qm set ${VM_ID} --boot c --bootdisk scsi0
/usr/sbin/qm set ${VM_ID} --serial0 socket --vga serial0
/usr/sbin/qm resize ${VM_ID} scsi0 +16G

echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9YoKFxv4ixFrJvRn3wUz5BSxtPjGk30tHGRc18BInN damien@ddeville.me" > id_rsa.pub
/usr/sbin/qm set ${VM_ID} --sshkey id_rsa.pub
/usr/sbin/qm set ${VM_ID} --ciuser "damien"
/usr/sbin/qm set ${VM_ID} --ipconfig0 ip=dhcp

/usr/sbin/qm template ${VM_ID}

popd
