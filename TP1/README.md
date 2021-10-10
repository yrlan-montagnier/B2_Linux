
# TP1 Linux - B2B - MONTAGNIER Yrlan

## **0. Préparation des VM**
### **🌞 Setup de deux machines Rocky Linux configurées de façon basique**

#### **Un accès internet (via la carte NAT)**
- **Carte réseau dédiée**
    ```
    [yrlan@node1 ~]$ ip a
    [...]
    2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
        link/ether 08:00:27:3e:e9:bd brd ff:ff:ff:ff:ff:ff
        inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
           valid_lft 86223sec preferred_lft 86223sec
        inet6 fe80::a00:27ff:fe3e:e9bd/64 scope link noprefixroute
           valid_lft forever preferred_lft forever
    [...]
    ```
- **Route par défaut**
    ```
    [yrlan@node1 ~]$ ip r s
    default via 10.0.2.2 dev enp0s3 proto dhcp metric 100
    10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100
    10.101.1.0/24 dev enp0s8 proto kernel scope link src 10.101.1.11 metric 101
    ```

#### **Un accès à un réseau local (les deux machines peuvent se ping) (via la carte Host-Only)**

- **Carte réseau dédiée** (host-only sur VirtualBox)
```
[yrlan@node1 ~]$ ip a
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:6e:96:f1 brd ff:ff:ff:ff:ff:ff
    inet 10.101.1.11/24 brd 10.101.1.255 scope global noprefixroute enp0s8
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe6e:96f1/64 scope link
       valid_lft forever preferred_lft forever
```
- **Les machines doivent posséder une IP statique sur l'interface host-only**

`sudo nano /etc/sysconfig/network-scripts/ifcfg-enp0s8`

**REMPLACER** dans ce fichier :
1. `BOOTPROTO=dhcp` => `BOOTPROTO=static` pour passer en IP statique
2. `ONBOOT=no` => `ONBOOT=yes` 

On **rajoute** ces 2 lignes sous **BOOTPROTO** ( adresse IP et masque utilisé ): 
```
[...]
BOOTPROTO=static
IPADDR=10.101.1.11 (1ère VM) ||| 10.101.1.12 (2ème VM)
NETMASK=255.255.255.0
[...]
```
On **reboot l'interface réseau** avec : `sudo nmcli con reload` puis `sudo nmcli con up enp0s8`
```
[yrlan@node1 ~]$ cat /etc/sysconfig/network-scripts/ifcfg-enp0s8
TYPE=Ethernet
BOOTPROTO=static
IPADDR=10.101.1.11
NETMASK=255.255.255.0
DEFROUTE=yes
NAME=enp0s8
UUID=c077c523-fb65-4a2a-8998-c40b1466e030
DEVICE=enp0s8
ONBOOT=yes

[yrlan@node2 ~]$ cat /etc/sysconfig/network-scripts/ifcfg-enp0s8
TYPE=Ethernet
BOOTPROTO=static
IPADDR=10.101.1.12
NETMASK=255.255.255.0
DEFROUTE=yes
NAME=enp0s8
UUID=c077c523-fb65-4a2a-8998-c40b1466e030
DEVICE=enp0s8
ONBOOT=yes
```

#### **Vous n'utilisez QUE ssh pour administrer les machines**

![](/img/SSH.png)

#### **Les machines doivent avoir un nom**
-  `sudo nano /etc/hostname` => Remplacer par `node1.tp1.b2` // `node2.tp1.b2`
- `sudo reboot now` => on reboot puis on peut vérifier la prise en compte avec la commande `hostname`: 
```
[yrlan@node1 ~]$ hostname
node1.tp1.b2

[yrlan@node2 ~]$ hostname
node2.tp1.b2
```

#### **Utiliser 1.1.1.1 comme serveur DNS**
- `sudo nano /etc/resolv.conf` => On enlève les lignes nameserver et on remplace par **nameserver 1.1.1.1**
- Vérifier avec le bon fonctionnement avec la commande dig

`dig ynov.com` ===> ![](/img/YnovDIG.png)


#### **Les machines doivent pouvoir se joindre par leurs noms respectifs**
`sudo nano /etc/hosts` => On rajoute l'IP puis les nom de la machine correspondante : 
- **1ère machine** => `10.101.1.12 node2.tp1.b2`
```
[yrlan@node1 ~]$ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.101.1.12 node2.tp1.b2

[yrlan@node1 ~]$ ping node2.tp1.b2
PING node2.tp1.b2 (10.101.1.12) 56(84) bytes of data.
64 bytes from node2.tp1.b2 (10.101.1.12): icmp_seq=1 ttl=64 time=0.800 ms
64 bytes from node2.tp1.b2 (10.101.1.12): icmp_seq=2 ttl=64 time=0.817 ms
64 bytes from node2.tp1.b2 (10.101.1.12): icmp_seq=3 ttl=64 time=0.837 ms
^C
--- node2.tp1.b2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2010ms
rtt min/avg/max/mdev = 0.800/0.818/0.837/0.015 ms
```
- **2ème machine** => `10.101.1.11 node1.tp1.b2`
```
[yrlan@node2 ~]$ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.101.1.11 node1.tp1.b2

[yrlan@node2 ~]$ ping node1.tp1.b2
PING node1.tp1.b2 (10.101.1.11) 56(84) bytes of data.
64 bytes from node1.tp1.b2 (10.101.1.11): icmp_seq=1 ttl=64 time=0.847 ms
64 bytes from node1.tp1.b2 (10.101.1.11): icmp_seq=2 ttl=64 time=0.967 ms
64 bytes from node1.tp1.b2 (10.101.1.11): icmp_seq=3 ttl=64 time=0.847 ms
^C
--- node1.tp1.b2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.847/0.887/0.967/0.056 ms
```
On peut maintenant faire `ping node2.tp1.b2` sur la 1ère machine ou `ping node1.tp1.b2` sur la 2ème.

#### **Le pare-feu est configuré pour bloquer toutes les connexions exceptées celles qui sont nécessaires**
```
[yrlan@node1 ~]$ sudo firewall-cmd --permanent --remove-service=cockpit 
success
[yrlan@node1 ~]$ sudo firewall-cmd --permanent --remove-service=dhcpv6-client
success
[yrlan@node1 ~]$ sudo firewall-cmd --reload ( on redémarre le pare-feu pour que les règles soit appliquées )
success
[yrlan@node1 ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: ssh
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```
Ici, j'ai laissé juste le service SSH qui me sert à me connecter depuis mon terminal windows, toutes les autres connexions sont bloquées.

## **I. Utilisateurs**
### **1. Création et configuration**

#### **🌞 Ajouter un utilisateur à la machine, qui sera dédié à son administration. Précisez des options sur la commande d'ajout pour que :**
```
[yrlan@node1 ~]$ sudo useradd yrlan2 -m -s /bin/bash
[yrlan@node1 ~]$ sudo cat /etc/passwd
yrlan:x:1000:1000:yrlan:/home/yrlan:/bin/bash
yrlan2:x:1001:1001::/home/yrlan2:/bin/bash
```

#### **🌞 Créer un nouveau groupe admins qui contiendra les utilisateurs de la machine ayant accès aux droits de root via la commande sudo.**
```
[yrlan@node1 ~]$ sudo groupadd admins
[yrlan@node1 ~]$ visudo
[yrlan@node1 ~]$ sudo cat /etc/sudoers
[...]
## Allows people in group wheel to run all commands
%wheel  ALL=(ALL)       ALL
%admins  ALL=(ALL)       ALL
[...]
```

#### **🌞 Ajouter votre utilisateur à ce groupe admins.**
```
[yrlan@node1 ~]$ sudo usermod -aG admins yrlan2
[yrlan@node1 ~]$ groups yrlan2
yrlan2 : yrlan2 admins
```

### **2. SSH**
#### **Configurer un échange de clés SSH lorsque l'on se connecte à la machine**
- **🌞 Générer une clé sur le poste client de l'administrateur qui se connectera à distance (vous :) )**
	```
	PS C:\Users\yrlan> ssh-keygen -t rsa -b 4096
	Generating public/private rsa key pair.
	Enter file in which to save the key (C:\Users\yrlan/.ssh/id_rsa):
	C:\Users\yrlan/.ssh/id_rsa already exists.
	```

- **🌞 Déposer la clé dans le fichier `/home/<USER>/.ssh/authorized_keys` de la machine que l'on souhaite administrer**
```
PS C:\Users\yrlan> type $env:USERPROFILE\.ssh\id_rsa.pub | ssh yrlan2@10.101.1.11 "mkdir .ssh ; cat >> .ssh/authorized_keys"

[yrlan2@node1 ~]$ cat .ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwM32JCKeM4NyDV/6UX/5ZpVI8wr2PMRWysrYNEyvF/5MeKTzfk3aWmHS/heG5wMRpAC/mhgYLyuCDMlJKHFQZ4fBs8eGmsN2gxQ/W2RM1k1Y3+nzpiQRqOEdss79+wPNl4K+pdNcnnTWwOuk9268IBeiO9nkqsdDBoB3iJBLa0cnyPdJsHpnRuiLP1XoR0GECWjspGi7qD3lqs0Cw05jhB4EYY6N2V5hd1XahYHdh6dMRORp3CI7FZ/LxbzsA9LN5E2elv2VitkL4pS7yKOiupvkF7ybADpcLi4waT55AClrhgoeRgVpG2VVvZkr/BtLt6ZU9uyzoofQdKl21IuZ0FyofdMeU9q6AUwmZuZJwQ6e9D+LvrVNVu2Bm3OU1P1Q/VnJcRK9/92SyMjoh7oOOJhpxnzpDQ+8BmV4tQXxLklYZHdgRA05B7aH6NQBa6CzrP5sDreQAIiiWsHELcfyVPSa9bnhf7XMBkrQwzyeE+2Rv/X4Pb5Ox1zyUs0+O92zVC6z9i4pKQXpoHc27VhNK67NvIHKWN+bmgCA9oW5H5F6LKb48S05cLAXfkwURLZMN61JO8qNNok9k3y2Hl63isTeM4CASVpCKnIaEB2kdGW2ykUpxNFV3eCT3of8jTNRtq3LSi562KaOOJNWP1Uogw5NJtbZwCAab5jF2+EUHQQ== yrlan@MSI-9SEXR

[yrlan2@node1 ~] chmod 600 .ssh/authorized_keys
[yrlan2@node1 ~] chmod 700 .ssh
```
- **🌞 Assurez vous que la connexion SSH est fonctionnelle, sans avoir besoin de mot de passe.**
```
PS C:\Users\yrlan> ssh yrlan2@10.101.1.11
Activate the web console with: systemctl enable --now cockpit.socket

Last login: Wed Sep 22 19:09:17 2021 from 10.101.1.1
[yrlan2@node1 ~]$
```

## **II. Partitionnement**
### **1. Préparation de la VM**
![](/img/Disques.png)

### **2. Partitionnement**
##### **🌞 Utilisez LVM pour :**
- **Agréger les deux disques en un seul volume group**
```
[yrlan2@node1 ~]$ lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda           8:0    0    8G  0 disk
├─sda1        8:1    0    1G  0 part /boot
└─sda2        8:2    0    7G  0 part
  ├─rl-root 253:0    0  6.2G  0 lvm  /
  └─rl-swap 253:1    0  820M  0 lvm  [SWAP]
sdb           8:16   0    3G  0 disk ## Premier disque de 3Go
sdc           8:32   0    3G  0 disk ## Deuxième disque de 3Go
sr0          11:0    1 1024M  0 rom

[yrlan2@node1 ~]$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[yrlan2@node1 ~]$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
  
[yrlan2@node1 ~]$ sudo pvs
  PV         VG Fmt  Attr PSize  PFree
  /dev/sda2  rl lvm2 a--  <7.00g    0
  /dev/sdb      lvm2 ---   3.00g 3.00g
  /dev/sdc      lvm2 ---   3.00g 3.00g
  
[yrlan2@node1 ~]$ sudo vgcreate group /dev/sdb
  Volume group "group" successfully created
[yrlan2@node1 ~]$ sudo vgextend group /dev/sdc
  Volume group "group" successfully extended
  
[yrlan2@node1 ~]$ sudo vgs
  VG    #PV #LV #SN Attr   VSize  VFree
  group   2   0   0 wz--n-  5.99g 5.99g
  rl      1   2   0 wz--n- <7.00g    0
```
- **Créer 3 logical volumes de 1 Go chacun**
```
[yrlan2@node1 ~]$ sudo lvcreate -L 1G group -n lv1
  Logical volume "lv1" created.
[yrlan2@node1 ~]$ sudo lvcreate -L 1G group -n lv2
  Logical volume "lv2" created.
[yrlan2@node1 ~]$ sudo lvcreate -L 1G group -n lv3
  Logical volume "lv3" created.
```
- **Formater ces partitions en ext4**
```
[yrlan2@node1 ~]$ sudo mkfs -t ext4 /dev/mapper/group-lv1/lv1
mke2fs 1.45.6 (20-Mar-2020)
Could not open /dev/mapper/group-lv1/lv1: Not a directory
[yrlan2@node1 ~]$
[yrlan2@node1 ~]$ sudo mkfs -t ext4 /dev/group/lv1
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: c65ccaec-b58c-4467-8987-675ff2451824
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
----------------------------------------------------------------
[yrlan2@node1 ~]$ sudo mkfs -t ext4 /dev/group/lv2
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: 02b6db8d-f827-4941-af8c-1fd1f6b44e1c
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
----------------------------------------------------------------
[yrlan2@node1 ~]$ sudo mkfs -t ext4 /dev/group/lv3
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: 436edb8c-b9c0-4502-a6fd-449a318f5563
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```
- **Monter ces partitions pour qu'elles soient accessibles aux points de montage /mnt/part1, /mnt/part2 et /mnt/part3.**
```
[yrlan2@node1 ~]$ sudo mkdir /mnt/part1
[yrlan2@node1 ~]$ sudo mkdir /mnt/part2
[yrlan2@node1 ~]$ sudo mkdir /mnt/part3
[yrlan2@node1 ~]$ sudo mount /dev/group/lv1 /mnt/part1
[yrlan2@node1 ~]$ sudo mount /dev/group/lv2 /mnt/part2
[yrlan2@node1 ~]$ sudo mount /dev/group/lv3 /mnt/part3
[yrlan2@node1 ~]$ df -h

Filesystem             Size  Used Avail Use% Mounted on
devtmpfs               891M     0  891M   0% /dev
[...]
/dev/mapper/group-lv1  976M  2.6M  907M   1% /mnt/part1
/dev/mapper/group-lv2  976M  2.6M  907M   1% /mnt/part2
/dev/mapper/group-lv3  976M  2.6M  907M   1% /mnt/part3
[...]
```

####  **🌞 Grâce au fichier /etc/fstab, faites en sorte que cette partition soit montée automatiquement au démarrage du système.**
```
[yrlan2@node1 ~]$ sudo nano /etc/fstab
[yrlan2@node1 ~]$ sudo cat /etc/fstab
[...]
/dev/group/lv1 /mnt/part1 ext4 defaults 0 0
/dev/group/lv2 /mnt/part2 ext4 defaults 0 0
/dev/group/lv3 /mnt/part3 ext4 defaults 0 0

[yrlan2@node1 ~]$ sudo umount /mnt/part1
[yrlan2@node1 ~]$ sudo umount /mnt/part2
[yrlan2@node1 ~]$ sudo umount /mnt/part3

[yrlan2@node1 ~]$ sudo mount -av
/                        : ignored
/boot                    : already mounted
none                     : ignored
mount: /mnt/part1 does not contain SELinux labels.
       You just mounted an file system that supports labels which does not
       contain labels, onto an SELinux box. It is likely that confined
       applications will generate AVC messages and not be allowed access to
       this file system.  For more details see restorecon(8) and mount(8).
/mnt/part1               : successfully mounted
mount: /mnt/part2 does not contain SELinux labels.
       You just mounted an file system that supports labels which does not
       contain labels, onto an SELinux box. It is likely that confined
       applications will generate AVC messages and not be allowed access to
       this file system.  For more details see restorecon(8) and mount(8).
/mnt/part2               : successfully mounted
mount: /mnt/part3 does not contain SELinux labels.
       You just mounted an file system that supports labels which does not
       contain labels, onto an SELinux box. It is likely that confined
       applications will generate AVC messages and not be allowed access to
       this file system.  For more details see restorecon(8) and mount(8).
/mnt/part3               : successfully mounted
[...]
```

## **III. Gestion de services**
### **1. Interaction avec un service existant**
#### **🌞 Assurez-vous que :**
- L'unité est démarrée
    ```
    [yrlan2@node1 ~]$ systemctl is-active firewalld
    active
    ```
- L'unitée est activée (elle se lance automatiquement au démarrage)
    ```
    [yrlan2@node1 ~]$ systemctl is-enabled firewalld
    enabled
    ```

### **2. Création de service**
#### **A. Unité simpliste**
- **🌞 Créer un fichier qui définit une unité de service `web.service` dans le répertoire `/etc/systemd/system`.**
```
[yrlan2@node1 ~]$ sudo touch web.service /etc/systemd/system
[yrlan2@node1 ~]$ sudo nano /etc/systemd/system/web.service
[yrlan2@node1 ~]$ cat /etc/systemd/system/web.service
[Unit]
Description=Very simple web service

[Service]
ExecStart=/bin/python3 -m http.server 8888

[Install]
WantedBy=multi-user.target
```
- **🌞Une fois le service démarré, assurez-vous que pouvez accéder au serveur web : avec un navigateur ou la commande `curl` sur l'IP de la VM, port 8888.**
```
[yrlan2@node1 ~]$ sudo firewall-cmd --add-port=8888/tcp --permanent
success
[yrlan2@node1 ~]$ sudo firewall-cmd --reload
success
[yrlan2@node1 ~]$ sudo systemctl daemon-reload
[yrlan2@node1 ~]$ sudo systemctl start web.service
[yrlan2@node1 ~]$ sudo systemctl enable web.service
Created symlink /etc/systemd/system/multi-user.target.wants/web.service → /etc/systemd/system/web.service.
[yrlan2@node1 ~]$ sudo systemctl status web.service
● web.service - Very simple web service
   Loaded: loaded (/etc/systemd/system/web.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2021-09-23 02:23:35 CEST; 13s ago
 Main PID: 7988 (python3)
    Tasks: 1 (limit: 11397)
   Memory: 9.4M
   CGroup: /system.slice/web.service
           └─7988 /bin/python3 -m http.server 8888

Sep 23 02:23:35 node1.tp1.b2 systemd[1]: Started Very simple web service.

[yrlan2@node1 ~]$ curl 10.101.1.11:8888
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="bin/">bin@</a></li>
<li><a href="boot/">boot/</a></li>
<li><a href="dev/">dev/</a></li>
<li><a href="etc/">etc/</a></li>
<li><a href="home/">home/</a></li>
<li><a href="lib/">lib@</a></li>
<li><a href="lib64/">lib64@</a></li>
<li><a href="media/">media/</a></li>
<li><a href="mnt/">mnt/</a></li>
<li><a href="opt/">opt/</a></li>
<li><a href="proc/">proc/</a></li>
<li><a href="root/">root/</a></li>
<li><a href="run/">run/</a></li>
<li><a href="sbin/">sbin@</a></li>
<li><a href="srv/">srv/</a></li>
<li><a href="sys/">sys/</a></li>
<li><a href="tmp/">tmp/</a></li>
<li><a href="usr/">usr/</a></li>
<li><a href="var/">var/</a></li>
</ul>
<hr>
</body>
</html>
```
[](/img/web.service.png)

#### **B. Modification de l'unité**
- **🌞 Créer un utilisateur `web`.**
	`[yrlan2@node1 ~]$ sudo useradd web`
- **🌞 Modifiez l'unité de service `web.service` créée précédemment en ajoutant les clauses :**
	-   `User=` afin de lancer le serveur avec l'utilisateur `web` dédié
	-   `WorkingDirectory=` afin de lancer le serveur depuis un dossier spécifique, choisissez un dossier que vous avez créé dans `/srv`
	-   ces deux clauses sont à positionner dans la section `[Service]` de votre unité
```
[yrlan2@node1 ~]$ sudo mkdir /srv/tp1
[yrlan2@node1 ~]$ sudo nano /etc/systemd/system/web.service
[yrlan2@node1 ~]$ cat /etc/systemd/system/web.service
[Unit]
Description=Very simple web service

[Service]
ExecStart=/bin/python3 -m http.server 8888
User=web
WorkingDirectory=/srv/tp1

[Install]
WantedBy=multi-user.target
```

- **🌞 Placer un fichier de votre choix dans le dossier créé dans `/srv` et tester que vous pouvez y accéder une fois le service actif. Il faudra que le dossier et le fichier qu'il contient appartiennent à l'utilisateur `web`.**
```
[yrlan2@node1 ~]$ cd /srv/tp1
[yrlan2@node1 tp1]$ touch test
[yrlan2@node1 tp1]$ sudo chown web /srv/tp1/test
[yrlan2@node1 tp1]$ sudo chown web /srv/tp1
[yrlan2@node1 tp1]$ ls -al
total 0
drwxr-xr-x. 2 web  root 18 Sep 23 02:42 . ||| ## Le dossier tp1 appartient bien a l'utilisateur web
drwxr-xr-x. 3 root root 17 Sep 23 02:42 ..
-rw-r--r--. 1 web  root  0 Sep 23 02:42 test ||| ## Le fichier également

[yrlan2@node1 ~]$ systemctl daemon-reload
```
Le fichier est maintenant disponible dans `/srv/tp1` à l'adresse http://10.101.1.11:8888/srv/tp1/

- **🌞 Vérifier le bon fonctionnement avec une commande `curl`**
```
[yrlan2@node1 ~]$ curl 10.101.1.11:8888/srv/
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /srv/</title>
</head>
<body>
<h1>Directory listing for /srv/</h1>
<hr>
<ul>
<li><a href="tp1/">tp1/</a></li>
</ul>
<hr>
</body>
</html>
```
[](/img/web.service_end.png)
