#!/usr/bin/env bash

# Script de création d'une VM sous KVM pour xpesynology

# Nom du VG utilisé pour la création des VM
VGName=lvm-kvm

# Path pour le device mapper utilisé pour les montages kpartx / loosetup
# nécessaire pour monter le file system afin de modifier le fichier grub.cfg
devmapp=/dev/mapper

# Nom de la VM que nous allons créer
VMname=SynoBoot_DS3615xs-6.1_V1.02b

# Nom du fichier IMG (bootloader)
ImgFile=SynoBoot_DS3615xs-6.1_V1.02b.img

# Nom du LV qui recevera la copie l'image (fichier img)
LVBootName=SynoBoot_DS3615xs-6.1_V1.02b

# Taille du LV --> correspondant au fichier bootloader (IMG)
# 50Mo dans notres cas
LVBootSize=50m

# Nom du LV complet avec son path
LVBootFullName=/dev/$VGName/$LVBootName

# Nom du LV pour le DSM (system)
LVDSMName=Syno_system.6.2-test

# Taille du LV pour le DSM
# NB : 10Go mini sinon lors de l'installation
LVDSMSize=10G

# Full name pour le LV DSM
LVDSMFullName=/dev/$VGName/$LVDSMName

# Point de montage pour la partition contenant le fichier grub.cfg
SynoBoot=/mnt/synology

# Optionnel :
# - Numéro de série à mettre dans le fichier grub.cfg
# - Laisser à la valeur 0 (zéro) sinon
MySerialNumber=xxxxxxxxxx

# Optionnel :
# - timeout à mettre dans le fichier grub.cfg
# - Laisser à la valeur 0 (zéro) sinon
MyTimeOut=3

# Optionnel :
# - Passer le boot en mode verbeux
# - Laisser à la valeur 0 (zéro) sinon
Verbose=1

Exemple de paramètres utilisés pour la création de la VMExemple de paramètres utilisés pour la création de la VM
# Nbr de CPU
VMcpus="2"

# RAM
VMram="1024"

# Type OS
VMOStype="linux"

# Nom de l'OS
VMOSvariant="archlinux"

# Disque USB --> BootLoader
VMBootDisk="path=$LVBootFullName,bus=usb,target.dev=sdb,boot.order=1"

# Disque pour le DSM (system)
VMDSMDisk="path=$LVDSMFullName,bus=sata,target.dev=sda,address.type=drive,address.controller=0,address.bus=0,address.target=0,address.unit=0"

# Remote display : VNC, spice, ...
VMgraphics="spice"

# Conf Network : en bridge chez moi modèle de la carte
VMnetwork="network=bridge,model.type=e1000e"

#-----------------------------------------------------------------------
# Etape 1 : Creat LV + Recopie du fichier image dans le LV 
#           NB : Cela sera l'équivalent de la clé USB via un LV....
#
# Pour cette étape on part du postula que :
#   - le fichier de boot zip est téléchargé, 
#   - l'extraction du zip a été effectué
#   - le DSM DSM_DS3615xs_24922.pat est téléchargé
#-----------------------------------------------------------------------

# 1.1
# Renommer le fichier SynoBoot.img en SynoBoot_DS3615_6.2.v1.03b.img
# sinon remplacer SynoBoot_DS3615_6.2.v1.03b.img par le nom correspondant
# au nom du fichier extrait (SynoBoot.img généralement)


# 1.4 Suppression du LV if exist
if [ -b $LVBootFullName ]; then
  echo virsh destroy $VMname; virsh undefine $VMname --remove-all-storage
  virsh destroy $VMname; virsh undefine $VMname --remove-all-storage
  sleep 1

  echo "Suppression de $LVBootFullName"
  lvremove -f $LVBootFullName
fi
sleep 1

# 1.4 Creat if not exist
if [ ! -b $LVBootFullName ]; then
  echo "lvcreate $VGName -n $LVBootName -L $LVBootSize --wipesignatures n"
  lvcreate $VGName -n $LVBootName -L $LVBootSize --wipesignatures n
fi
sleep 1

# 1.4 Affichage / vérif du LV
echo lvdisplay $LVBootFullName
lvdisplay $LVBootFullName
sleep 1

# 1.5 Copie du fichier img dans le lv
echo dd bs=512K status=progress if=$ImgFile of=$LVBootFullName
dd bs=512K status=progress if=$ImgFile of=$LVBootFullName
sleep 1

# 1.6 Check du LV ...on doit sensiblement avoir la même chose...
echo sgdisk $LVBootFullName -e
sgdisk $LVBootFullName -e
sleep 1

echo parted $LVBootFullName unit s print
parted $LVBootFullName unit s print

# 1.7 Afficher les partitions contenues dans le fichier img
echo fdisk -l $ImgFile
fdisk -l $ImgFile

sleep 2
# Fin de l'étape 1

#-----------------------------------------------------------------------
# Etape 2 : Adaptation / Modification du fichier grub.cfg pour
#           - Modifier le n° de série
#           - Mettre le boot en mode verbeux le cas échéant
#           - Augmenter/changer la value du timeout 
#-----------------------------------------------------------------------

# 2.1 kpartx du LV pour accéder à la partion contenant le fichier grub.cfg

# 2.1.1 Les noms contenant des tirets doivent être transfomés avec 2 tirets
#       car le montage par kpartx les transfome comme suit :
#       nom lvm   .............: /dev/lvm-kvm/Syno_DS3615xs-6.2.v1.03b 
#       nom remappé par kpartx : /dev/mapper/lvm--kvm-Syno_DS3615xs--6.2.v1.03b
# 
#  NB : On aurait un résultat équivalent avec la commande loosetup

mapplvm=$(echo $LVBootFullName | sed 's/^\///;s/dev\///;s/-/--/g;s/\//-/')
# echo "mapplvm=$mapplvm"
sleep 1

# 2.1.2 On récupère dans un array le nom des partitions mappées par kpartx
kix_lvm=( $(kpartx -av $LVBootFullName 2>&1 | grep -owE "($mapplvm+[0-9]+)") )

# 2.1.2 Affichage du premier poste du tblx pour vérifier que tout est OK
echo ${kix_lvm[0]}
sleep 2

echo mount $devmapp/${kix_lvm[0]} $SynoBoot
mount $devmapp/${kix_lvm[0]} $SynoBoot
sleep 1

# 2.3 Check si le fichier grub.cfg existe
if [ -f $SynoBoot/grub/grub.cfg ]; then
  echo "Le fichier $SynoBoot/grub/grub.cfg existe"  
fi

# 2.3.1 Optionnel 
#       Generate serial : https://xpenogen.github.io/serial_generator/index.html

#  Si changement du serial number demandé 
if [ $MySerialNumber != "0" ]; then
  # Remplacement de la chaine de caractères pour le serial number ...
  echo "Change seial number --> sn=$MySerialNumber"
  sed -i "s/^set sn=.*$/set sn=$MySerialNumber/" $SynoBoot/grub/grub.cfg
  cat $SynoBoot/grub/grub.cfg | grep -ai "set sn="
  sleep 4
fi

#  Si changement du timeout demandé 
if [ $MyTimeOut != "0" ]; then
  echo "Timeout --> set timeout=$MyTimeOut"
  sed -i "s/^set timeout=.*$/set timeout=$MyTimeOut/" $SynoBoot/grub/grub.cfg
  cat $SynoBoot/grub/grub.cfg | grep -ai "set timeout="
  sleep 4
fi

#  Si changement mode verbeux demandé 
if [ $Verbose != "0" ]; then
  # On cible la chaine de caractères "elevator quiet syno_port_thaw"
  # pour la sustituer à ............."elevator syno_port_thaw"
  echo "Verbose mode..."
  sed -i 's/elevator quiet syno_port_thaw/elevator syno_port_thaw/' $SynoBoot/grub/grub.cfg
  cat $SynoBoot/grub/grub.cfg | grep -ai "syno_port_thaw"
  sleep 4
fi

# 2.4.1 umount
echo umount $SynoBoot
umount $SynoBoot
sleep 1

# 2.4.2 retirer les mapp
echo kpartx -dv $LVBootFullName
kpartx -dv $LVBootFullName

#-----------------------------------------------------------------------
# Etape 3 : Creation de la VM avec :
#           - Le LV contenant l'imge du boot
#           - un LV de 10Go pour accueillir le système (DSM)

# 3.2 Suppression du LV if exist
if [ -b $LVDSMFullName ]; then
  echo "Suppression de $LVDSMFullName"
  lvremove -f $LVDSMFullName
fi
sleep 1

# 3.3 Creat if not exist
if [ ! -b $LVDSMFullName ]; then
  echo "lvcreate $VGName -n $LVDSMName -L $LVDSMSize --wipesignatures n"
  lvcreate $VGName -n $LVDSMName -L $LVDSMSize --wipesignatures n
fi
sleep 1

# Creat de vm en cli (voir https://linuxconfig.org/how-to-create-and-manage-kvm-virtual-machines-from-cli)
# https://linux.goffinet.org/administration/virtualisation-kvm/

# Stop and undefine the VM
echo virsh destroy $VMname; virsh undefine $VMname
virsh destroy $VMname; virsh undefine $VMname
sleep 1

virt-install \
--name=$VMname \
--memory=$VMram \
--vcpus=$VMcpus \
--os-type=$VMOStype \
--os-variant=$VMOSvariant \
--disk=$VMBootDisk \
--import \
--disk=$VMDSMDisk \
--graphics=$VMgraphics \
--network=$VMnetwork \
--print-xml > $VMname.xml
sleep 1

# Create VM via le fichier xml généné par virt-install
echo virsh define $VMname.xml --validate
virsh define $VMname.xml --validate
sleep 1

# Demarrage de la VM en se mettant en ecoute : 
# - mode verbeux demandé dans le fichier grub.cfg 
echo virsh start $VMname; echo virsh console $VMname --force
virsh start $VMname; virsh console $VMname --force
