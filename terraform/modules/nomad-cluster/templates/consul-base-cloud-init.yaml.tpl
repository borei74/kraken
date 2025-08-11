# cloud-config

groups:
  - ansible

users:
  - default:
  - name: ansible
    primary_group: ansible
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE5nVMPR1+C5mcIi9s57+X09JV7ChozFSQUHJCprzdk0 dan@borei.soleks.net
