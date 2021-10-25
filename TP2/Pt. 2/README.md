# TP2 pt. 2 : Maintien en condition opérationnelle

# Sommaire

- [TP2 pt. 2 : Maintien en condition opérationnelle](#tp2-pt-2--maintien-en-condition-opérationnelle)
- [Sommaire](#sommaire)
- [0. Prérequis](#0-prérequis)
  - [Checklist](#checklist)
- [I. Monitoring](#i-monitoring)
  - [1. Le concept](#1-le-concept)
  - [2. Setup](#2-setup)
- [II. Backup](#ii-backup)
  - [1. Intwo bwo](#1-intwo-bwo)
  - [2. Partage NFS](#2-partage-nfs)
  - [3. Backup de fichiers](#3-backup-de-fichiers)
  - [4. Unité de service](#4-unité-de-service)
    - [A. Unité de service](#a-unité-de-service)
    - [B. Timer](#b-timer)
    - [C. Contexte](#c-contexte)
  - [5. Backup de base de données](#5-backup-de-base-de-données)
  - [6. Petit point sur la backup](#6-petit-point-sur-la-backup)
- [III. Reverse Proxy](#iii-reverse-proxy)
  - [1. Introooooo](#1-introooooo)
  - [2. Setup simple](#2-setup-simple)
  - [3. Bonus HTTPS](#3-bonus-https)
- [IV. Firewalling](#iv-firewalling)
  - [1. Présentation de la syntaxe](#1-présentation-de-la-syntaxe)
  - [2. Mise en place](#2-mise-en-place)
    - [A. Base de données](#a-base-de-données)
    - [B. Serveur Web](#b-serveur-web)
    - [C. Serveur de backup](#c-serveur-de-backup)
    - [D. Reverse Proxy](#d-reverse-proxy)
    - [E. Tableau récap](#e-tableau-récap)

## Checklist

A chaque machine déployée, vous **DEVREZ** vérifier la 📝**checklist**📝 :

- [x] IP locale, statique ou dynamique
- [x] hostname défini
- [x] firewall actif, qui ne laisse passer que le strict nécessaire
- [x] SSH fonctionnel avec un échange de clé
- [x] accès Internet (une route par défaut, une carte NAT c'est très bien)
- [x] résolution de nom
  - résolution de noms publics, en ajoutant un DNS public à la machine
  - résolution des noms du TP, à l'aide du fichier `/etc/hosts`
- [ ] monitoring (oui, toutes les machines devront être surveillées)

# I. Monitoring

## 1. Le concept

**Dans notre cas on va surveiller deux choses :**

- d'une part, les machines : ***monitoring système***. Par exemple :
  - remplissage disque/RAM
  - charge CPU/réseau
- d'autre part, nos applications : ***monitoring applicatif***. Ici :
  - serveur Web
  - base de données

## 2. Setup

#### **🌞 Setup Netdata**

- **y'a plein de méthodes d'install pour Netdata**
- **on va aller au plus simple, exécutez, sur toutes les machines que vous souhaitez monitorer :**
    ```bash
    # Passez en root pour cette opération
    $ sudo su -

    # Install de Netdata via le script officiel statique
    $ bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh)

    # Quittez la session de root
    $ exit
    ```

#### **🌞 Manipulation du *service* Netdata**

- **Un *service* `netdata` a été créé**
- **Déterminer s'il est actif, et s'il est paramétré pour démarrer au boot de la machine**
  - Si ce n'est pas le cas, faites en sorte qu'il démarre au boot de la machine
    ```bash
    # Vérifier s'il est démarré
    [yrlan@web ~]$ sudo systemctl is-active netdata
    active
    # Vérifier s'il est activé au boot
    [yrlan@web ~]$ sudo systemctl is-enabled netdata
    enabled
    ```

- **Déterminer à l'aide d'une commande `ss` sur quel port Netdata écoute**
    - **Autoriser ce port dans le firewall**
    ```bash
    # On repère sur quel port netdata écoute
    [yrlan@web ~]$ sudo ss -alnpt | grep netdata
    LISTEN 0      128        127.0.0.1:8125       0.0.0.0:*    users:(("netdata",pid=2305,fd=45))
    LISTEN 0      128          0.0.0.0:19999      0.0.0.0:*    users:(("netdata",pid=2305,fd=5))
    LISTEN 0      128            [::1]:8125          [::]:*    users:(("netdata",pid=2305,fd=44))
    LISTEN 0      128             [::]:19999         [::]:*    users:(("netdata",pid=2305,fd=6))

    # Ajout des ports que netdata utilisent dans le pare-feu
    [yrlan@web ~]$ sudo firewall-cmd --add-port=19999/tcp --permanent; sudo firewall-cmd --add-port=8125/tcp --permanent
    success
    success
    
    # Actualisation du pare-feu + affichage des règles
    [yrlan@web ~]$ sudo firewall-cmd --reload; sudo firewall-cmd --list-all
    success
    public (active)
      target: default
      icmp-block-inversion: no
      interfaces: enp0s3 enp0s8
      sources:
      services: ssh
      ports: 80/tcp 19999/tcp 8125/tcp
      protocols:
      masquerade: no
      forward-ports:
      source-ports:
      icmp-blocks:
      rich rules:
      
    # Vérification depuis mon hôte powershell ( sur mon pc )
    PS C:\Users\yrlan> curl http://web.tp2.linux:19999/
    <!doctype html><html lang="en"><head><title>netdata dashboard</title>[...]</body></html>
    ```

#### **🌞 Setup Alerting**

- **Ajustez la conf de Netdata pour mettre en place des alertes Discord**
  - **Ui ui c'est bien ça : vous recevrez un message Discord quand un seul critique est atteint**
  - **Noubliez pas que la conf se trouve pour nous dans `/opt/netdata/etc/netdata/`**
    ```bash
    [yrlan@web ~]$ sudo cat /opt/netdata/etc/netdata/health_alarm_notify.conf
    ###############################################################################
    # sending discord notifications

    # note: multiple recipients can be given like this:
    #                  "CHANNEL1 CHANNEL2 ..."

    # enable/disable sending discord notifications
    SEND_DISCORD="YES"

    # Create a webhook by following the official documentation -
    # https://support.discordapp.com/hc/en-us/articles/228383668-Intro-to-Webhooks
    DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/897110887889006612/v-wKtDiq2QJYE6M1WMCPndNokPf6fbP-Ei33eGfhZ_DfnWXi0BfgDow4DQGfanYbAff2"

    # if a role's recipients are not configured, a notification will be send to
    # this discord channel (empty = do not send a notification for unconfigured
    # roles):
    DEFAULT_RECIPIENT_DISCORD="alarms"
    ``` 

- **Vérifiez le bon fonctionnement de l'alerting sur Discord**
    ```bash
    [yrlan@web ~]$ sudo su -s /bin/bash netdata
    bash-4.4$ export NETDATA_ALARM_NOTIFY_DEBUG=1
    bash-4.4$ /opt/netdata/usr/libexec/netdata/plugins.d/alarm-notify.sh test
    
    # SENDING TEST WARNING ALARM TO ROLE: sysadmin
    2021-10-25 02:46:43: alarm-notify.sh: INFO: sent discord notification for: web.tp2.linux test.chart.test_alarm is WARNING to 'alarms'
    # OK

    # SENDING TEST CRITICAL ALARM TO ROLE: sysadmin
    2021-10-25 02:46:43: alarm-notify.sh: INFO: sent discord notification for: web.tp2.linux test.chart.test_alarm is CRITICAL to 'alarms'
    # OK

    # SENDING TEST CLEAR ALARM TO ROLE: sysadmin
    2021-10-25 02:46:44: alarm-notify.sh: INFO: sent discord notification for: web.tp2.linux test.chart.test_alarm is CLEAR to 'alarms'
    # OK
    ```

**⚠️⚠️⚠️ Une fois que vos tests d'alertes fonctionnent, vous DEVEZ taper la commande qui suit pour que votre alerting fonctionne correctement ⚠️⚠️⚠️**
```bash
[yrlan@web ~]$ sudo sed -i 's/curl=""/curl="\/opt\/netdata\/bin\/curl -k"/' /opt/netdata/etc/netdata/health_alarm_notify.conf
```    

# **II. Backup**

🖥️ **VM `backup.tp2.linux`**

**Déroulez la [📝**checklist**📝](#checklist) sur cette VM.**

## **1. Intwo bwo**

**La backup consiste à extraire des données de leur emplacement original afin de les stocker dans un endroit dédié.**
**Cet endroit dédié est un endroit sûr** : le but est d'assurer la perennité des données sauvegardées, tout en maintenant leur niveau de sécurité.
Pour la sauvegarde, il existe plusieurs façon de procéder. Pour notre part, nous allons procéder comme suit :


- **création d'un serveur de stockage**
	- il hébergera les sauvegardes de tout le monde
	- ce sera notre "endroit sûr"
	- ce sera un partage NFS
	- ainsi, toutes les machines qui en ont besoin pourront accéder à un dossier qui leur est dédié sur ce serveur de stockage, afin d'y stocker leurs sauvegardes
- **développement d'un script de backup**
    - ce script s'exécutera en local sur les machines à sauvegarder
	- il s'exécute à intervalles de temps réguliers
	- il envoie les données à sauvegarder sur le serveur NFS
	- du point de vue du script, c'est un dossier local. Mais en réalité, ce dossier est monté en NFS.





## **2. Partage NFS**

#### **🌞 Setup environnement**

- **Créer un dossier `/srv/backup/`**
    ```bash
    [yrlan@backup ~]$ sudo mkdir /srv/backup/
    ```
- **Il contiendra un sous-dossier ppour chaque machine du parc**
    - **Commencez donc par créer le dossier `/srv/backup/web.tp2.linux/`**
    ```bash
    [yrlan@backup ~]$ sudo mkdir -p /srv/backup/web.tp2.linux/
    ```
- **Il existera un partage NFS pour chaque machine (principe du moindre privilège)**
    ```bash
    [yrlan@backup ~]$ sudo mkdir -p /srv/backup/db.tp2.linux/
    ```

#### **🌞 Setup partage NFS**

- **Je crois que vous commencez à connaître la chanson... Google "nfs server rocky linux"**
    - [ce lien me semble être particulièrement simple et concis](https://www.server-world.info/en/note?os=Rocky_Linux_8&p=nfs&f=1)
```bash
# Installer les nfs-utils
# On indique le domaine ( a faire aussi sur web / db )
[yrlan@backup ~]$ sudo dnf install -y nfs-utils
[yrlan@backup ~]$ sudo vi /etc/idmapd.conf
[yrlan@backup ~]$ sudo cat /etc/idmapd.conf | grep Domain
Domain = tp2.linux

# On indique les dossier à exporter avec l'IP qui correspond à la VM
# Permettre l'accès aux dossiers de la machine backup a des machines du réseau
[yrlan@backup ~]$ sudo vi /etc/exports
[yrlan@backup ~]$ sudo cat /etc/exports
/srv/backup/web.tp2.linux 10.102.1.11/24(rw,no_root_squash)
/srv/backup/db.tp2.linux 10.102.1.12/24(rw,no_root_squash)

# On autorise le services nfs (ports 111 et 2049)
[yrlan@backup backup]$ sudo firewall-cmd --add-service=nfs --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --list-all
success
success
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: nfs ssh
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
  
[yrlan@backup backup]$ sudo systemctl enable --now rpcbind nfs-server
```

#### **🌞 Setup points de montage sur `web.tp2.linux`**

- **[Sur le même site, y'a ça](https://www.server-world.info/en/note?os=Rocky_Linux_8&p=nfs&f=2)**
    ```bash
    [yrlan@web ~]$ sudo dnf -y install nfs-utils
    [yrlan@web ~]$ sudo cat /etc/idmapd.conf | grep Domain
    Domain = tp2.linux
    ```
- **Monter le dossier `/srv/backups/web.tp2.linux` du serveur NFS dans le dossier `/srv/backup/` du serveur Web**
    ```bash
    [yrlan@web ~]$ sudo mkdir /srv/backup
    [yrlan@web ~]$ sudo mount -t nfs backup.tp2.linux:/srv/backup/web.tp2.linux /srv/backup
    ```
- **Vérifier...**
    - **Avec une commande `mount` que la partition est bien montée**
    ```bash
    [yrlan@web ~]$ sudo mount | grep backup
    backup.tp2.linux:/srv/backup/web.tp2.linux on /srv/backup type nfs4 (rw,relatime,vers=4.2,rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.102.1.11,local_lock=none,addr=10.102.1.13)
    ```

    - **Avec une commande `df -h` qu'il reste de la place**
    ```bash
    [yrlan@web ~]$ sudo df -h | grep backup
    backup.tp2.linux:/srv/backup/web.tp2.linux  6.2G  2.2G  4.1G  35% /srv/backup
    ```

    - **Avec une commande `touch` que vous avez le droit d'écrire dans cette partition**
    ```bash
    # Création d'un fichier `testttt` dans /srv/backup
    [yrlan@web ~]$ sudo touch /srv/backup/testttt
    [yrlan@web ~]$ sudo ls -l /srv/backup/
    total 0
    -rw-r--r--. 1 root root 0 Oct 12 03:22 testttt
    
    # Il apparait bien dans le dossier /srv/backup/web.tp2.linux/ sur la machine backup
    [yrlan@backup ~]$ ls -l /srv/backup/web.tp2.linux/
    total 0
    -rw-r--r--. 1 root root 0 Oct 12 03:22 testttt
    ```

- **Faites en sorte que cette partition se monte automatiquement grâce au fichier `/etc/fstab`**
    ```bash
    # Conf montage auto
    [yrlan@web ~]$ sudo vi /etc/fstab
    [yrlan@web ~]$ sudo cat /etc/fstab | grep backup
    backup.tp2.linux:/srv/backup/web.tp2.linux /srv/backup nfs defaults 0 0
    
    # Test : 
    [yrlan@web ~]$ sudo umount /srv/backup
    [yrlan@web ~]$ sudo mount -av | grep /srv/backup
    /srv/backup              : successfully mounted
    ```
    
#### **🌟 BONUS : partitionnement avec LVM**

- **Ajoutez un disque à la VM `backup.tp2.linux` (disque = sdb)**
- **Utilisez LVM pour créer une nouvelle partition (5Go ça ira)**
```bash
[yrlan@backup ~]$ lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda           8:0    0    8G  0 disk
├─sda1        8:1    0    1G  0 part /boot
└─sda2        8:2    0    7G  0 part
  ├─rl-root 253:0    0  6.2G  0 lvm  /
  └─rl-swap 253:1    0  820M  0 lvm  [SWAP]
sdb           8:16   0    8G  0 disk
sr0          11:0    1 1024M  0 rom

## On crée un Physical Volume sur le disque qu'on a repéré
[yrlan@backup ~]$ sudo pvcreate /dev/sdb; sudo pvs
  Physical volume "/dev/sdb" successfully created.
  
  PV         VG Fmt  Attr PSize  PFree
  /dev/sda2  rl lvm2 a--  <7.00g    0
  /dev/sdb      lvm2 ---   8.00g 8.00g  
    
# On crée un Volume Group
[yrlan@backup ~]$ sudo vgcreate backup /dev/sdb; sudo vgs
  Volume group "backup" successfully created
  VG     #PV #LV #SN Attr   VSize  VFree
  backup   1   0   0 wz--n- <8.00g <8.00g
  rl       1   2   0 wz--n- <7.00g     0
    
# On crée un Logical Volume ( Logical Volume = Partition )
[yrlan@backup ~]$ sudo lvcreate -L 5G backup -n Backup
  Logical volume "Backup" created.
[yrlan@backup ~]$ sudo lvs
  LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  Backup backup -wi-a-----   5.00g
  root   rl     -wi-ao----  <6.20g
  swap   rl     -wi-ao---- 820.00m

# Formater partition en ext4
[yrlan@backup ~]$ sudo mkfs -t ext4 /dev/mapper/backup-Backup
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 1310720 4k blocks and 327680 inodes
Filesystem UUID: 2c1c6c5b-62bf-4ee2-b96f-2750feaed879
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

# Montage de la partition ( notre Lv ) sur /srv/backup
[yrlan@backup ~]$ sudo mount /dev/backup/Backup /srv/backup

# Vérifs :
[yrlan@backup ~]$ df -h | grep backup
/dev/mapper/backup-Backup  4.9G   20M  4.6G   1% /srv/backup

[yrlan@backup ~]$ lsblk | grep backup
└─backup-Backup 253:2    0    5G  0 lvm  /srv/backup
```

- **Monter automatiquement cette partition au démarrage du système à l'aide du fichier `/etc/fstab`**
- **Cette nouvelle partition devra être montée sur le dossier `/srv/backup/`**

```bash
# Config
[yrlan@backup ~]$ sudo cat /etc/fstab | grep /dev/backup/Backup
/dev/backup/Backup /srv/backup ext4 defaults 0 0

# Vérif montage auto partition sur /srv/backup
[yrlan@backup ~]$ sudo umount /srv/backup
[yrlan@backup ~]$ sudo mount -av | grep /srv/backup
/srv/backup              : successfully mounted

# Vérif montage sur machine Web
[yrlan@web ~]$ sudo umount /srv/backup
[yrlan@web ~]$ sudo mount -av | grep /srv/backup
/srv/backup              : successfully mounted

# C'est bien notre partition de 5Go qui est utilisé pour le dossier /srv/backup
[yrlan@web ~]$ df -h | grep backup
backup.tp2.linux:/srv/backup/web.tp2.linux  4.9G   20M  4.6G   1% /srv/backup

[yrlan@db ~]$ df -h | grep backup
backup.tp2.linux:/srv/backup/db.tp2.linux  4.9G   20M  4.6G   1% /srv/backup

[yrlan@backup ~]$ df -h | grep backup
/dev/mapper/backup-Backup  4.9G   20M  4.6G   1% /srv/backup

[yrlan@backup ~]$ lsblk | grep backup
└─backup-Backup 253:2    0    5G  0 lvm  /srv/backup
```

## **3. Backup de fichiers**

#### **🌞 Rédiger le script de backup `/srv/tp2_backup.sh`**

- **Le script crée une archive compressée `.tar.gz` du dossier ciblé**
- **L'archive générée doit s'appeler** `tp2_backup_YYMMDD_HHMMSS.tar.gz`
- **Le script utilise la commande `rsync` afin d'envoyer la sauvegarde dans le dossier de destination**
- **Il DOIT pouvoir être appelé de la sorte :**
```bash
$ ./tp2_backup.sh <DESTINATION> <DOSSIER_A_BACKUP>
```

```bash
#!/bin/bash
# Simple backup script
# Yrlan - 12/10/2021

destination=$1
folder2backup=$2

if [ -z "$destination" ]; then

  echo "Donnez le nom de dossier en tant qu'argument."
  exit 0
fi


if [ -d "$destination" ]; then
        filename="${folder2backup}_$(date '+%y-%m-%d_%H-%M-%S').tar.gz"
        tar -czf "$filename" "$folder2backup"
        rsync -av $filename $destination
        echo "Archive successfully created."
        else
        echo "ATTENTION: Le dossier de destination n'existe pas: $destination"

fi
```
    
> 📁 **[Fichier `/srv/tp2_backup.sh`](./script/tp2_backup.sh)**

#### **🌞 Tester le bon fonctionnement**

- **Exécuter le script sur le dossier de votre choix**
    ```bash
    [yrlan@backup ~]$ sudo bash -x /srv/tp2_backup.sh /srv/backup/Archives/ /srv/backup/web.tp2.linux

    + destination=/srv/backup/Archives/
    + folder2backup=/srv/backup/web.tp2.linux
    + '[' -z /srv/backup/Archives/ ']'
    + '[' -d /srv/backup/Archives/ ']'
    ++ date +%y-%m-%d_%H-%M-%S
    + filename=/srv/backup/web.tp2.linux_21-10-24_23-07-47.tar.gz
    + tar -czf /srv/backup/web.tp2.linux_21-10-24_23-07-47.tar.gz /srv/backup/web.tp2.linux
    tar: Removing leading `/' from member names
    + rsync -av /srv/backup/web.tp2.linux_21-10-24_23-07-47.tar.gz /srv/backup/Archives/
    sending incremental file list
    web.tp2.linux_21-10-24_23-07-47.tar.gz

    sent 289 bytes  received 35 bytes  648.00 bytes/sec
    total size is 166  speedup is 0.51
    + echo 'Archive successfully created.'
    Archive successfully created.
    ```
- **prouvez que la backup s'est bien exécutée**
    ```bash
    [yrlan@backup backup]$ ls -l Archives/ | grep web.tp2.linux_21-10-24_23-07-47.tar.gz
    -rw-r--r--. 1 root root 166 Oct 24 23:07 web.tp2.linux_21-10-24_23-07-47.tar.gz
    ```
- **tester de restaurer les données**
  - récupérer l'archive générée, et vérifier son contenu
    ```bash
    [yrlan@backup ~]$ sudo tar zxvf /srv/backup/Archives/tp2_backup_211025_031915.tar.gz
    [...]
    
    [yrlan@backup backup]$ ls -l srv/backup/web.tp2.linux/
    total 0
    -rw-r--r--. 1 root root 0 Oct 12 16:55 testfile
    ```

🌟 **BONUS**

- faites en sorte que votre script ne conserve que les 5 backups les plus récentes après le `rsync`
- faites en sorte qu'on puisse passer autant de dossier qu'on veut au script : `./tp2_backup.sh <DESTINATION> <DOSSIER1> <DOSSIER2> <DOSSIER3>...` et n'obtenir qu'une seule archive
- utiliser [Borg](https://borgbackup.readthedocs.io/en/stable/) plutôt que `rsync`

## 4. Unité de service

Lancer le script à la main c'est bien. **Le mettre dans une joulie *unité de service* et l'exécuter à intervalles réguliers, de manière automatisée, c'est mieux.**

Le but va être de créer un *service* systemd pour que vous puissiez interagir avec votre script de sauvegarde en faisant :

```bash
$ sudo systemctl start tp2_backup
$ sudo systemctl status tp2_backup
```

---

### A. Unité de service

#### **🌞 Créer une *unité de service*** pour notre backup

- **C'est juste un fichier texte hein**
- **Doit se trouver dans le dossier `/etc/systemd/system/`**
- **Doit s'appeler `tp2_backup.service`**
    ```bash
    [yrlan@backup ~]$ sudo nano /etc/systemd/system/tp2_backup.service
    ```
- **le contenu :**
    ```bash
    [yrlan@backup ~]$ sudo cat /etc/systemd/system/tp2_backup.service
    [Unit]
    Description=Our own lil backup service (TP2)

    [Service]
    ExecStart=/srv/tp2_backup.sh /srv/backup/Archives /srv/backup/web.tp2.linux
    ExecStart=/srv/tp2_backup.sh /srv/backup/Archives /srv/backup/db.tp2.linux
    Type=oneshot
    RemainAfterExit=no

    [Install]
    WantedBy=multi-user.target
    ```

> Pour les tests, sauvegardez le dossier de votre choix, peu importe lequel.

#### **🌞 Tester le bon fonctionnement**

- **N'oubliez pas d'exécuter `sudo systemctl daemon-reload` à chaque ajout/modification d'un *service***
- **Essayez d'effectuer une sauvegarde avec `sudo systemctl start tp2_backup`**
- **Prouvez que la backup s'est bien exécutée**
  - **Vérifiez la présence de la nouvelle archive**
    ```bash
    [yrlan@backup backup]$ sudo systemctl daemon-reload
    [yrlan@backup backup]$ sudo systemctl start tp2_backup
    [yrlan@backup backup]$ ls -l Archives/
    total 8
    -rw-r--r--. 1 root root 126 Oct 24 23:19 db.tp2.linux_21-10-24_23-19-52.tar.gz
    -rw-r--r--. 1 root root 166 Oct 24 23:19 web.tp2.linux_21-10-24_23-19-52.tar.gz
    ```
---

### **B. Timer**

Un *`timer systemd`* permet l'exécution d'un *service* à intervalles réguliers.

#### **🌞 Créer le *timer* associé à notre `tp2_backup.service`**

- **Toujours juste un fichier texte**
- **Dans le dossier `/etc/systemd/system/` aussi**
- **Fichier `tp2_backup.timer`**
    ```bash
    [yrlan@backup backup]$ sudo nano /etc/systemd/system/tp2_backup.timer
    ```
- **Contenu du fichier :**
    ```bash
    [yrlan@backup backup]$ sudo cat /etc/systemd/system/tp2_backup.timer

    [Unit]
    Description=Periodically run our TP2 backup script
    Requires=tp2_backup.service

    [Timer]
    Unit=tp2_backup.service
    OnCalendar=*-*-* *:*:00

    [Install]
    WantedBy=timers.target
    [yrlan@backup backup]$
    ```

> Le nom du *timer* doit être rigoureusement identique à celui du *service*. Seule l'extension change : de `.service` à `.timer`. C'est notamment grâce au nom identique que systemd sait que ce *timer* correspond à un *service* précis.

#### **🌞 Activez le timer**

- **Démarrer le *timer* : `sudo systemctl start tp2_backup.timer`**
- **Activer le au démarrage avec une autre commande `systemctl` :**
    ```bash
    [yrlan@backup srv]$ sudo systemctl enable tp2_backup.timer
    Created symlink /etc/systemd/system/timers.target.wants/tp2_backup.timer → /etc/systemd/system/tp2_backup.timer.
    ```
- **Prouver que...**
    - **Le *timer* est actif actuellement** = 
    ```bash
    [yrlan@backup ~]$ sudo systemctl is-active tp2_backup.timer 
    active
    ```
    - **Qu'il est paramétré pour être actif dès que le système boot**
    ```bash
    [yrlan@backup ~]$ sudo systemctl is-enabled tp2_backup.timer
    enabled
    ```
    
#### **🌞 Tests !**

- **Avec la ligne `OnCalendar=*-*-* *:*:00`, le *timer* déclenche l'exécution du *service* toutes les minutes**
- **Vérifiez que la backup s'exécute correctement**
    ```bash
    [yrlan@backup backup]$ ls -l Archives/
    total 40
    -rw-r--r--. 1 root root 126 Oct 24 23:23 db.tp2.linux_21-10-24_23-23-03.tar.gz
    -rw-r--r--. 1 root root 126 Oct 24 23:24 db.tp2.linux_21-10-24_23-24-03.tar.gz
    -rw-r--r--. 1 root root 126 Oct 24 23:25 db.tp2.linux_21-10-24_23-25-03.tar.gz
    -rw-r--r--. 1 root root 166 Oct 24 23:23 web.tp2.linux_21-10-24_23-23-03.tar.gz
    -rw-r--r--. 1 root root 166 Oct 24 23:24 web.tp2.linux_21-10-24_23-24-03.tar.gz
    -rw-r--r--. 1 root root 166 Oct 24 23:25 web.tp2.linux_21-10-24_23-25-03.tar.gz
    ```

---

### **C. Contexte**

#### **🌞 Faites en sorte que...**

- **Votre backup s'exécute sur la machine `web.tp2.linux`**
- **Le dossier sauvegardé est celui qui contient le site NextCloud (quelque part dans `/var/`)**
- **La destination est le dossier NFS monté depuis le serveur `backup.tp2.linux`**
    ```bash
    [yrlan@web nextcloud]$ sudo mount | grep backup
    backup.tp2.linux:/srv/backup/web.tp2.linux on /var/www/sub-domains/web.tp2.linux type nfs4

    [yrlan@backup backup]$ sudo systemctl start tp2_backup
    [yrlan@backup backup]$ ls -l Archives/
    total 142312
    -rw-r--r--. 1 root root 145725914 Oct 25 00:04 web.tp2.linux_21-10-25_00-03-41.tar.gz
    ```
- **La sauvegarde s'exécute tous les jours à 03h15 du matin**
    ```bash
    [yrlan@backup backup]$ sudo cat /etc/systemd/system/tp2_backup.timer | grep "OnCalendar"
    OnCalendar=*-*-* 3:15:00
    ```
- **Prouvez avec la commande `sudo systemctl list-timers` que votre *service* va bien s'exécuter la prochaine fois qu'il sera 03h15**
    ```bash
    [yrlan@backup backup]$ sudo systemctl list-timers
    NEXT                          LEFT         LAST                          PASSED      UNIT                         ACTIVATES
    Mon 2021-10-25 00:29:33 CEST  16min left   Sun 2021-10-24 23:09:03 CEST  1h 3min ago dnf-makecache.timer          dnf-makecache.service
    Mon 2021-10-25 03:15:00 CEST  3h 2min left n/a                           n/a         tp2_backup.timer             tp2_backup.service
    Mon 2021-10-25 23:11:03 CEST  22h left     Sun 2021-10-24 23:11:03 CEST  1h 1min ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service

    3 timers listed.
    Pass --all to see loaded but inactive timers, too.
    ```

**[📁 Fichier `/etc/systemd/system/tp2_backup.timer`](./service/tp2_backup.timer)**  
**[📁 Fichier `/etc/systemd/system/tp2_backup.service`](./service/tp2_backup.service)**

## 5. Backup de base de données

Sauvegarder des dossiers c'est bien. Mais sauvegarder aussi les bases de données c'est mieux.

🌞 **Création d'un script `/srv/tp2_backup_db.sh`**

- il utilise la commande `mysqldump` pour récupérer les données de la base de données
- cela génère un fichier `.sql` qui doit ensuite être compressé en `.tar.gz`
- il s'exécute sur la machine `db.tp2.linux`
- il s'utilise de la façon suivante :

```bash
$ ./tp2_backup_db.sh <DESTINATION> <DATABASE>
```

**📁 Fichier `/srv/tp2_backup_db.sh`**  

🌞 **Restauration**

- tester la restauration de données
- c'est à dire, une fois la sauvegarde effectuée, et le `tar.gz` en votre possession, tester que vous êtes capables de restaurer la base dans l'état au moment de la sauvegarde
  - il faut réinjecter le fichier `.sql` dans la base à l'aide d'une commmande `mysql`

#### **🌞 Unité de service**
- **Pareil que pour la sauvegarde des fichiers ! On va faire de ce script une *unité de service*.**
- **Votre script `/srv/tp2_backup_db.sh` doit pouvoir se lancer grâce à un *service* `tp2_backup_db.service`**
    ```bash
    [yrlan@db ~]$ sudo cat /etc/systemd/system/tp2_backup_db.service
    [Unit]
    Description=Service de backup de base de donnée (TP2)

    [Service]
    ExecStart=sudo bash /srv/tp2_backup_db.sh /srv/backup/DBBackup/ nextcloud
    Type=oneshot
    RemainAfterExit=no

    [Install]
    WantedBy=multi-user.target

    [yrlan@db ~]$ sudo systemctl start tp2_backup_db.service
    [yrlan@db ~]$ ls /srv/backup/DBBackup
    tp2_backup_21-10-25_00-12-21.tar.gz
    ```
- **Le service est exécuté tous les jours à 03h30 grâce au timer`tp2_backup_db.timer`**
    ```bash
    [yrlan@db ~]$ sudo cat /etc/systemd/system/tp2_backup_db.timer
    Description=Lance le service de sauvegarde de base de donnée à 3h30
    Requires=tp2_backup_db.service

    [Timer]
    Unit=tp2_backup_db.service
    OnCalendar=*-*-* 3:30:00

    [Install]
    WantedBy=timers.target
    ```
- **Prouvez le bon fonctionnement du *service* ET du *timer***
    ```bash
    [yrlan@db ~]$ sudo systemctl daemon-reload
    sudo systemctl start tp2_backup_db.timer
    [yrlan@db ~]$ sudo systemctl enable tp2_backup_db.timer
    Created symlink /etc/systemd/system/timers.target.wants/tp2_backup_db.timer → /etc/systemd/system/tp2_backup_db.timer.
    [yrlan@db ~]$ sudo systemctl is-enabled tp2_backup_db.timer
    enabled
    [yrlan@db ~]$ sudo systemctl is-active tp2_backup_db.timer
    active
    
    [yrlan@db ~]$ sudo systemctl list-timers
    NEXT                          LEFT     LAST                          PASSED   UNIT                   >
    Mon 2021-10-25 03:30:00 CEST  11h left n/a                           n/a      tp2_backup_db.timer    >
    ```

📁 **Fichier [`/etc/systemd/system/tp2_backup_db.timer`](./service/tp2_backup_db.timer)**  
📁 **Fichier [`/etc/systemd/system/tp2_backup_db.service`](./service/tp2_backup_db.service)**

## 6. Petit point sur la backup

A ce stade vous avez :

- un script qui tourne sur `web.tp2.linux` et qui **sauvegarde les fichiers de NextCloud**
- un script qui tourne sur `db.tp2.linux` et qui **sauvegarde la base de données de NextCloud**
- toutes **les backups sont centralisées** sur `backup.tp2.linux`
- **tout est géré de façon automatisée**
  - les scripts sont packagés dans des *services*
  - les services sont déclenchés par des *timers*
  - tout est paramétré pour s'allumer quand les machines boot (les *timers* comme le serveur NFS)

🔥🔥 **That is clean shit.** 🔥🔥

# III. Reverse Proxy

## 2. Setup simple

> **🖥️ VM `front.tp2.linux`**

**Déroulez la [📝**checklist**📝](#checklist) sur cette VM.**

#### **🌞 Installer NGINX**

- **Vous devrez d'abord installer le paquet `epel-release` avant d'installer `nginx`**
    ```bash
    [yrlan@front ~]$ sudo dnf install -y epel-release;sudo dnf install -y nginx
    ```
- **Le fichier de conf principal de NGINX est `/etc/nginx/nginx.conf`**
    ```bash
    [yrlan@front ~]$ head -8 /etc/nginx/nginx.conf
    # For more information on configuration, see:
    #   * Official English Documentation: http://nginx.org/en/docs/
    #   * Official Russian Documentation: http://nginx.org/ru/docs/

    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log;
    pid /run/nginx.pid;
    ```

#### **🌞 Tester !**

- **Lancer le *service* `nginx`**
- **Le paramétrer pour qu'il démarre seul quand le système boot**
    ```bash
    [yrlan@front ~]$ sudo systemctl start nginx
    [yrlan@front ~]$ sudo systemctl enable nginx
    Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
    [yrlan@front ~]$ sudo systemctl is-active nginx
    active
    [yrlan@front ~]$ sudo systemctl is-enabled nginx
    enabled
    ```
- **Repérer le port qu'utilise NGINX par défaut, pour l'ouvrir dans le firewall**
    ```bash
    [yrlan@front ~]$ sudo ss -alnpt | grep nginx
    LISTEN 0      128          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=4046,fd=8),("nginx",pid=4045,fd=8))
    LISTEN 0      128             [::]:80           [::]:*    users:(("nginx",pid=4046,fd=9),("nginx",pid=4045,fd=9))

    [yrlan@front ~]$ sudo firewall-cmd --add-port=80/tcp --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --list-all
    success
    success
    success
    public (active)
      target: default
      icmp-block-inversion: no
      interfaces: enp0s3 enp0s8
      sources:
      services: ssh
      ports: 80/tcp
      protocols:
      masquerade: no
      forward-ports:
      source-ports:
      icmp-blocks:
      rich rules:
    ```
- **Vérifier que vous pouvez joindre NGINX avec une commande `curl` depuis votre PC**
    ```powershell
    PS C:\Users\yrlan> curl front.tp2.linux:80
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
      <head>
        <title>Test Page for the Nginx HTTP Server on Rocky Linux</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        [...]
      </body>
    </html>
    ```

#### **🌞 Explorer la conf par défaut de NGINX**

- **Repérez l'utilisateur qu'utilise NGINX par défaut**
    ```bash
    [yrlan@front ~]$ sudo ps -ef | grep nginx
    root        4045       1  0 00:41 ?        00:00:00 nginx: master process /usr/sbin/nginx
    nginx       4046    4045  0 00:41 ?        00:00:00 nginx: worker process
    ```
- **Dans la conf NGINX, on utilise le mot-clé `server` pour ajouter un nouveau site**
    - **Repérez le bloc `server {}` dans le fichier de conf principal**
    ```bash
    [yrlan@front ~]$ sudo cat /etc/nginx/nginx.conf
    [...]
    server {
      listen       80 default_server;
      listen       [::]:80 default_server;
      server_name  _;
      root         /usr/share/nginx/html;

      # Load configuration files for the default server block.
      include /etc/nginx/default.d/*.conf;

      location / {
      }

      error_page 404 /404.html;
          location = /40x.html {
      }

      error_page 500 502 503 504 /50x.html;
          location = /50x.html {
      }
    }
    ```
- **Par défaut, le fichier de conf principal inclut d'autres fichiers de conf**
    - **Mettez en évidence ces lignes d'inclusion dans le fichier de conf principal**
    ```bash
    [yrlan@front ~]$ sudo cat /etc/nginx/nginx.conf | grep include
    include /usr/share/nginx/modules/*.conf;
        include             /etc/nginx/mime.types;
        # See http://nginx.org/en/docs/ngx_core_module.html#include
        include /etc/nginx/conf.d/*.conf;
            include /etc/nginx/default.d/*.conf;
    #        include /etc/nginx/default.d/*.conf;
    ```


#### **🌞 Modifier la conf de NGINX**

- **Pour que ça fonctionne, le fichier `/etc/hosts` de la machine DOIT être rempli correctement, conformément à la** **[📝**checklist**📝](#checklist)**
    ```bash
    [yrlan@front ~]$ cat /etc/hosts | grep 10.102.1.
    10.102.1.11 web.tp2.linux
    10.102.1.12 db.tp2.linux
    10.102.1.13 backup.tp2.linux
    ```
- **Supprimer le bloc `server {}` par défaut, pour ne plus présenter la page d'accueil NGINX**
- **Créer un fichier `/etc/nginx/conf.d/web.tp2.linux.conf` avec le contenu suivant :**
    ```bash
    [yrlan@front ~]$ sudo cat /etc/nginx/conf.d/web.tp2.linux.conf
    server {
        listen 80;

        server_name web.tp2.linux;

        location / {
            proxy_pass http://web.tp2.linux;
        }
    }
    
    # Vérifications, c'est bien l'interface de nextcloud qui s'affiche
    [yrlan@front ~]$ curl http://10.102.1.14/index.php
    <!DOCTYPE html>
    <html class="ng-csp" data-placeholder-focus="false" lang="en" data-locale="en" >
            <head
     data-requesttoken="BsKY0nCYJj157Ym/P1/lpO3y/jvhBXn4sl7kFI/boh8=:VIrSpETcUmtK3LjRXG68z6yrxgyZcjyBwjq+cf6L5jA=">
                    <meta charset="utf-8">
                    <title>
                    Nextcloud               
                    </title>
                    <meta http-equiv="X-UA-Compatible" content="IE=edge">
                    [...]
    ```
## **3. Bonus HTTPS**

**Etape bonus** : mettre en place du chiffrement pour que nos clients accèdent au site de façon plus sécurisée.

#### **🌟 Générer la clé et le certificat pour le chiffrement**

- **Nous allons générer en une commande la clé et le certificat**
- **Puis placer la clé et le cert dans les endroits standards pour la distribution Rocky Linux**
    ```bash
    # Génération de la clé et du certificat
    [yrlan@front ~]$ openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.crt
    Generating a RSA private key
    [...]
    -----
    Country Name (2 letter code) [XX]:
    State or Province Name (full name) []:
    Locality Name (eg, city) [Default City]:
    Organization Name (eg, company) [Default Company Ltd]:
    Organizational Unit Name (eg, section) []:
    Common Name (eg, your name or your server's hostname) []:web.tp2.linux
    Email Address []:
    
    # On déplace la clé et le certificat dans les dossiers standards sur Rocky
    # En le renommant
    [yrlan@front ~]$ sudo mv server.key /etc/pki/tls/private/web.tp2.linux.key
    [yrlan@front ~]$ sudo mv server.crt /etc/pki/tls/certs/web.tp2.linux.crt
    
    #Setup des permissions restrictives
    [yrlan@front ~]$ sudo chown root:root /etc/pki/tls/private/web.tp2.linux.key
    [yrlan@front ~]$ sudo chown root:root /etc/pki/tls/certs/web.tp2.linux.crt
    [yrlan@front ~]$ sudo chmod 400 /etc/pki/tls/private/web.tp2.linux.key
    [yrlan@front ~]$ sudo chmod 644 /etc/pki/tls/certs/web.tp2.linux.crt
    ```
    
#### **🌟 Modifier la conf de NGINX**

- **Inspirez-vous de ce que vous trouvez sur internet**
- **Il n'y a que deux lignes à ajouter**
	- **Une ligne pour préciser le chemin du certificat**
    ```
    ssl_certificate     /etc/pki/tls/certs/web.tp2.linux.crt
    ```
	- **Une ligne pour préciser le chemin de la clé**
    ```
    ssl_certificate_key /etc/pki/tls/private/web.tp2.linux.key
    ```
- **Et une ligne à modifier**
	- **Préciser qu'on écoute sur le port 443, avec du chiffrement**
    ```
    listen 443 ssl;
    ```
    
---
    
- **Fichier final :**    
    ```bash
    [yrlan@front ~]$ sudo cat /etc/nginx/conf.d/web.tp2.linux.conf
    server {
            listen 443 ssl;
            server_name web.tp2.linux;

            ssl_certificate     /etc/pki/tls/certs/web.tp2.linux.crt
            ssl_certificate_key /etc/pki/tls/private/web.tp2.linux.key

            location / {
                    proxy_pass http://web.tp2.linux;
            }
    }
    ```
- **n'oubliez pas d'ouvrir le port 443/tcp dans le firewall**
    ```bash
    [yrlan@front ~]$ sudo firewall-cmd --add-port=443/tcp --permanent; sudo firewall-cmd --remove-port=80/tcp --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --list-all
    success
    success
    success
    public (active)
      target: default
      icmp-block-inversion: no
      interfaces: enp0s3 enp0s8
      sources:
      services: ssh
      ports: 443/tcp
      protocols:
      masquerade: no
      forward-ports:
      source-ports:
      icmp-blocks:
      rich rules:
    ```

#### **🌟 TEST**

- **connectez-vous sur `https://web.tp2.linux` depuis votre PC**
- **petite avertissement de sécu : normal, on a signé nous-mêmes le certificat**
  - **vous pouvez donc "Accepter le risque" (le nom du bouton va changer suivant votre navigateur)**
  - **avec `curl` il faut ajouter l'option `-k` pour désactiver cette vérification**

# IV. Firewalling

## 1. Présentation de la syntaxe

**Première étape** : définir comme politique par défaut de TOUT DROP. On refuse tout, et on whiteliste après.

Il existe déjà une zone appelée `drop` qui permet de jeter tous les paquets. Il suffit d'ajouter nos interfaces dans cette zone.

```bash
$ sudo firewall-cmd --list-all # on voit qu'on est par défaut dans la zone "public"
$ sudo firewall-cmd --set-default-zone=drop # on configure la zone "drop" comme zone par défaut
$ sudo firewall-cmd --zone=drop --add-interface=enp0s8 # ajout explicite de l'interface host-only à la zone "drop"
```

**Ensuite**, on peut créer une nouvelle zone, qui autorisera le trafic lié à telle ou telle IP source :

```bash
$ sudo firewall-cmd --add-zone=ssh # le nom "ssh" est complètement arbitraire. C'est clean de faire une zone par service.
```

**Puis** on définit les règles visant à autoriser un trafic donné :

```bash
$ sudo firewall-cmd --zone=ssh --add-source=10.102.1.1/32 # 10.102.1.1 sera l'IP autorisée
$ sudo firewall-cmd --zone=ssh --add-port=22/tcp # uniquement le trafic qui vient 10.102.1.1, à destination du port 22/tcp, sera autorisé
```

**Le comportement de FirewallD sera alors le suivant :**

- si l'IP source d'un paquet est `10.102.1.1`, il traitera le paquet comme étant dans la zone `ssh`
- si l'IP source est une autre IP, et que le paquet arrive par l'interface `enp0s8` alors le paquet sera géré par la zone `drop` (le paquet sera donc *dropped* et ne sera jamais traité)

> *L'utilisation de la notation `IP/32` permet de cibler une IP spécifique. Si on met le vrai masque `10.102.1.1/24` par exemple, on autorise TOUT le réseau `10.102.1.0/24`, et non pas un seul hôte. Ce `/32` c'est un truc qu'on voit souvent en réseau, pour faire référence à une IP unique.*


## 2. Mise en place

### A. Base de données

🌞 **Restreindre l'accès à la base de données `db.tp2.linux`**

- **Seul le serveur Web doit pouvoir joindre la base de données sur le port 3306/tcp**
    ```bash
    [yrlan@db ~]$ sudo firewall-cmd --set-default-zone=drop
    sucess
    [yrlan@db ~]$ sudo firewall-cmd --new-zone=db --permanent; sudo firewall-cmd --zone=db --add-source=10.102.1.11/32 --permanent-; sudo firewall-cmd --zone=db --add-port=3306/tcp --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --zone=db --set-target=DROP --permanent
    success
    success
    success
    success
    success
    ```
- **Vous devez aussi autoriser votre accès SSH**
    ```bash
    sudo firewall-cmd --new-zone=ssh --permanent; sudo firewall-cmd --zone=ssh --add-source=10.102.1.1/32 --permanent; sudo firewall-cmd --zone=ssh --add-port=22/tcp --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --zone=ssh --set-target=DROP --permanent
    success
    success
    success
    success
    success
    ```
- **N'hésitez pas à multiplier les zones (une zone `ssh` et une zone `db` par exemple)**

#### **🌞 Montrez le résultat de votre conf avec une ou plusieurs commandes `firewall-cmd`**
```bash
[yrlan@db ~]$ sudo firewall-cmd --get-default-zone; sudo firewall-cmd --get-active-zones; sudo firewall-cmd --list-all; sudo firewall-cmd --list-all --zone=db;sudo firewall-cmd --list-all --zone=ssh
drop
db
  sources: 10.102.1.11/32
drop
  interfaces: enp0s8 enp0s3
ssh
  sources: 10.102.1.1/32
drop (active)
  target: DROP
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services:
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
db (active)
  target: DROP
  icmp-block-inversion: no
  interfaces:
  sources: 10.102.1.11/32
  services:
  ports: 3306/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
ssh (active)
  target: DROP
  icmp-block-inversion: no
  interfaces:
  sources: 10.102.1.1/32
  services:
  ports: 22/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

### B. Serveur Web

#### **🌞 Restreindre l'accès au serveur Web `web.tp2.linux`**

- **seul le reverse proxy `front.tp2.linux` doit accéder au serveur web sur le port 80**
    ```bash
    [yrlan@web ~]$ sudo firewall-cmd --set-default-zone=drop
    [yrlan@web ~]$ sudo firewall-cmd --new-zone=web --permanent; sudo firewall-cmd --zone=web --add-source=10.102.1.14/32 --permanent; sudo firewall-cmd --zone=web --add-port=80/tcp --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --zone=web --set-target=DROP --permanent
    success
    success
    success
    success
    success
    ```
- **n'oubliez pas votre accès SSH**
    ```bash
    [yrlan@web ~]$ sudo firewall-cmd --new-zone=ssh --permanent; sudo firewall-cmd --zone=ssh --add-source=10.102.1.1/32 --permanent; sudo firewall-cmd --zone=ssh --add-port=22/tcp --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --zone=ssh --set-target=DROP --permanent
    success
    success
    success
    success
    success
    ```

#### **🌞 Montrez le résultat de votre conf avec une ou plusieurs commandes `firewall-cmd`**
```bash
[yrlan@web ~]$ sudo firewall-cmd --get-default-zone; sudo firewall-cmd --get-active-zones; sudo firewall-cmd --list-all; sudo firewall-cmd --list-all --zone=web;sudo firewall-cmd --list-all --zone=ssh
[sudo] password for yrlan:
drop
drop
  interfaces: enp0s8 enp0s3
ssh
  sources: 10.102.1.1/32
web
  sources: 10.102.1.14/32
drop (active)
  target: DROP
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services:
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
web (active)
  target: DROP
  icmp-block-inversion: no
  interfaces:
  sources: 10.102.1.14/32
  services:
  ports: 80/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
ssh (active)
  target: DROP
  icmp-block-inversion: no
  interfaces:
  sources: 10.102.1.1/32
  services:
  ports: 22/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

### C. Serveur de backup

#### **🌞 Restreindre l'accès au serveur de backup `backup.tp2.linux`**

- **Seules les machines qui effectuent des backups doivent être autorisées à contacter le serveur de backup *via* NFS**
    ```bash
    [yrlan@backup ~]$ sudo firewall-cmd --set-default-zone=drop
    [yrlan@backup ~]$ sudo firewall-cmd --new-zone=backups --permanent; sudo firewall-cmd --zone=backups --add-source=10.102.1.11/32 --permanent; sudo firewall-cmd --zone=backups --add-source=10.102.1.12/32 --permanent; sudo firewall-cmd --zone=backups --add-service=nfs --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --zone=backups --set-target=DROP --permanent
    success
    success
    success
    success
    success
    ```
- **N'oubliez pas votre accès SSH**
    ```bash
    [yrlan@backup ~]$ sudo firewall-cmd --new-zone=ssh --permanent; sudo firewall-cmd --zone=ssh --add-source=10.102.1.1/32 --permanent; sudo firewall-cmd --zone=ssh --add-port=22/tcp --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --zone=ssh --set-target=DROP --permanent
    success
    success
    success
    success
    success
    ```

#### **🌞 Montrez le résultat de votre conf avec une ou plusieurs commandes `firewall-cmd`**
```bash
[yrlan@backup ~]$ sudo firewall-cmd --get-default-zone; sudo firewall-cmd --get-active-zones; sudo firewall-cmd --list-all --zone=drop; sudo firewall-cmd --list-all --zone=backups; sudo firewall-cmd --list-all --zone=ssh
drop

backups
  sources: 10.102.1.11/32 10.102.1.12/32
drop
  interfaces: enp0s8 enp0s3
ssh
  sources: 10.102.1.1/32
  
drop (active)
  target: DROP
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services:
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
backups (active)
  target: DROP
  icmp-block-inversion: no
  interfaces:
  sources: 10.102.1.11/32 10.102.1.12/32
  services: nfs
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
ssh (active)
  target: DROP
  icmp-block-inversion: no
  interfaces:
  sources: 10.102.1.1/32
  services:
  ports: 22/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```


### D. Reverse Proxy

#### **🌞 Restreindre l'accès au reverse proxy `front.tp2.linux`**

- **Seules les machines du réseau `10.102.1.0/24` doivent pouvoir joindre le proxy**
    ```bash
    [yrlan@front ~]$ sudo firewall-cmd --new-zone=proxy --permanent; sudo firewall-cmd --zone=proxy --add-source=10.102.1.0/24 --permanent; sudo firewall-cmd --zone=proxy --add-port=443/tcp --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --zone=proxy --set-target=DROP --permanent
    [sudo] password for yrlan:
    success
    success
    success
    success
    success
    [yrlan@front ~]$ sudo firewall-cmd --zone=proxy --set
    ```
- **N'oubliez pas votre accès SSH**
    ```bash
    [yrlan@front ~]$ sudo firewall-cmd --new-zone=ssh --permanent; sudo firewall-cmd --zone=ssh --add-source=10.102.1.1/32 --permanent; sudo firewall-cmd --zone=ssh --add-port=22/tcp --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --zone=ssh --set-target=DROP --permanent
    success
    success
    success
    success
    success
    ```

#### **🌞 Montrez le résultat de votre conf avec une ou plusieurs commandes `firewall-cmd`**
```bash
[yrlan@front ~]$ sudo firewall-cmd --get-default-zone; sudo firewall-cmd --get-active-zones; sudo firewall-cmd --list-all; sudo firewall-cmd --list-all --zone=proxy;sudo firewall-cmd --list-all --zone=ssh
drop
drop
  interfaces: enp0s8 enp0s3
proxy
  sources: 10.102.1.0/24
ssh
  sources: 10.102.1.1/32
drop (active)
  target: DROP
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services:
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
proxy (active)
  target: DROP
  icmp-block-inversion: no
  interfaces:
  sources: 10.102.1.0/24
  services:
  ports: 443/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
ssh (active)
  target: DROP
  icmp-block-inversion: no
  interfaces:
  sources: 10.102.1.1/32
  services:
  ports: 22/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

### **E. Tableau récap**

#### **🌞 Rendez-moi le tableau suivant, correctement rempli :**

| Machine            | IP            | Service                 | Port ouvert                             | IPs autorisées                    |
|--------------------|---------------|-------------------------|-----------------------------------------|-----------------------------------|
| `web.tp2.linux`    | `10.102.1.11` | Serveur Web             | `22/tcp`, `80/tcp`                      | `10.102.1.14/32`                  |
| `db.tp2.linux`     | `10.102.1.12` | Serveur Base de Données | `22/tcp`, `3306/tcp`                    | `10.102.1.11/32`                  |
| `backup.tp2.linux` | `10.102.1.13` | Serveur de Backup (NFS) | `22/tcp`, `111/tcp&udp`, `2049/tcp&udp` | `10.102.1.11/32` `10.102.1.12/32` |
| `front.tp2.linux`  | `10.102.1.14` | Reverse Proxy           | `22/tcp`, `443/tcp`                     | `10.102.1.0/24`                   |
