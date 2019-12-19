# Create-Xpenology-VM-KVM
Script Bash to Create Xpenology VM KVM

Script de création d'une VM sous KVM pour xpesynology
Version : 00
@DJR le : 17/12/19

Version du loader            : Loader Jun v1.03b DS3615xs
Nom du fichier               : SynoBoot_3615.zip
Lien vers les fichiers img   : https://xpenology.com/forum/topic/8024-liens-vers-toutes-les-versions-des-loaders/

Version du DSM correspondant : DSM_DS3615xs_24922.pat
Lien le fichier DSM          : https://archive.synology.com/download/DSM/release/6.2.2/24922/

Pré-requis pour la VM
 - kvm installé et fonctionnel
 - 10Go minimum pour le disque (LV) correspondant au DSM (sinon erreur lors de l'installation)
 - 50Mo pour le LV qui contiendra l'image du fichier IMG correspondant au SynoBoot

Pré-requis fichier IMG + version
 - Avoir chargé et décompressé le fichier SynoBoot_3615.zip correspondant à la version Jun v1.03b DS3615xs
 - Avoir chargé le DSM DSM_DS3615xs_24922.pat

Pré-requis logiciels pour linux :
 - kpartx, p7zip (ou équivalent)

-----------------------------------------------------------------------
Variables utilisées dans le script de création

Nom du VG utilisé pour la création des VM
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

# Taille du LV pour le  DSM 
# NB : 10Go mini 
LVDSMSize=10G

# Full name pour le LV DSM
LVDSMFullName=/dev/$VGName/$LVDSMName

# Point de montage pour la partition contenant le fichier grub.cfg
# qui sera modifé
SynoBoot=/mnt/synology

# Optionnel :
#  - Numéro de série à mettre dans le fichier grub.cfg
#  - Laisser à la valeur 0 (zéro) sinon
MySerialNumber=1230LWN010284

# Optionnel :
#  - timeout à mettre dans le fichier grub.cfg
#  - Laisser à la valeur 0 (zéro) sinon
MyTimeOut=3

# Optionnel :
#  - Passer le boot en mode verbeux 
#  - Laisser à la valeur 0 (zéro) sinon
Verbose=1

# Paramètres pour la création de la VM

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
# VMDSMDisk="path=$LVDSMFullName,bus=sata,target.dev=sda,address.type=drive"

# Remote display : VNC, spice, ...
VMgraphics="spice"

# Conf Network : en bridge chez moi
# modèle de la carte 
VMnetwork="network=bridge,model.type=e1000e"

