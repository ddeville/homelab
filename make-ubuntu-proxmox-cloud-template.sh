#!/bin/bash

set -eu

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

UBUNTU_VERSION="${UBUNTU_VERSION:-jammy}"
VM_ID="${VM_ID:-8000}"

WORK_DIR="$(mktemp -d)"
trap 'rm -f "${WORK_DIR}/${UBUNTU_VERSION}-server-cloudimg-amd64.img"' EXIT

PATH=/usr/sbin/:$PATH

pushd "${WORK_DIR}"

wget "https://cloud-images.ubuntu.com/${UBUNTU_VERSION}/current/${UBUNTU_VERSION}-server-cloudimg-amd64.img"

qm create "${VM_ID}" --memory 2048 --core 2 --name "${UBUNTU_VERSION}-cloud" --net0 virtio,bridge=vmbr0,firewall=1,trunks=40

qm importdisk "${VM_ID}" "${UBUNTU_VERSION}-server-cloudimg-amd64.img" data-lvm
qm set "${VM_ID}" --scsihw virtio-scsi-pci --scsi0 data-lvm:vm-"${VM_ID}"-disk-0
qm set "${VM_ID}" --boot c --bootdisk scsi0
qm resize "${VM_ID}" scsi0 +16G
qm set "${VM_ID}" --ide2 data-lvm:cloudinit
qm set "${VM_ID}" --serial0 socket --vga serial0
qm set "${VM_ID}" --sshkey "${SCRIPT_DIR}/id_rsa.pub"
qm set "${VM_ID}" --ciuser "damien"
qm set "${VM_ID}" --ipconfig0 ip=dhcp

qm template "${VM_ID}"

popd
