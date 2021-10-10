# TP2 pt. 1 : Gestion de service

# Sommaire

- [TP2 pt. 1 : Gestion de service](#tp2-pt-1--gestion-de-service)
- [Sommaire](#sommaire)
- [I. Un premier serveur web](#i-un-premier-serveur-web)
  - [1. Installation](#1-installation)
  - [2. Avancer vers la maîtrise du service](#2-avancer-vers-la-maîtrise-du-service)
- [II. Une stack web plus avancée](#ii-une-stack-web-plus-avancée)
  - [1. Intro](#1-intro)
  - [2. Setup](#2-setup)
    - [A. Serveur Web et NextCloud](#a-serveur-web-et-nextcloud)
    - [B. Base de données](#b-base-de-données)
    - [C. Finaliser l'installation de NextCloud](#c-finaliser-linstallation-de-nextcloud)

# I. Un premier serveur web

## 1. Installation

> **🖥️ VM web.tp2.linux**

#### **🌞 Installer le serveur Apache**

- **paquet `httpd`**
    ```
    [yrlan@web ~]$ sudo dnf install -y httpd
    ```

- **La conf se trouve dans `/etc/httpd/`**
  - **Le fichier de conf principal est `/etc/httpd/conf/httpd.conf`**
  - **Je vous conseille vivement de virer tous les commentaire du fichier, à défaut de les lire, vous y verrez plus clair**
    - **Avec `vim` vous pouvez tout virer avec `:g/^ *#.*/d`**
    ```
    [yrlan@web ~]$ sudo vim /etc/httpd/conf/httpd.conf
    :g/^ *#.*/d

    [yrlan@web ~]$ sudo cat /etc/httpd/conf/httpd.conf | grep IncludeOptional
    IncludeOptional conf.d/*.conf
    IncludeOptional conf/sites-enabled/*    
    ```
    
🌞 **Démarrer le service Apache**

- **Le service s'appelle `httpd` (raccourci pour `httpd.service` en réalité)**
  - **Démarrez le**
    ```
    [yrlan@web ~]$ sudo systemctl start httpd.service
    ```

  - **Faites en sorte qu'Apache démarre automatique au démarrage de la machine**
    ```
    [yrlan@web ~]$ sudo systemctl enable httpd.service
    Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.
    ```

  - **ouvrez le port firewall nécessaire**
    - **utiliser une commande `ss` pour savoir sur quel port tourne actuellement Apache**
    - **[une petite portion du mémo est consacrée à `ss`](https://gitlab.com/it4lik/b2-linux-2021/-/blob/main/cours/memo/commandes.md#r%C3%A9seau)**
    ```
    [yrlan@web ~]$ sudo ss -alnpt | grep httpd
    LISTEN 0      128                *:80              *:*    users:(("httpd",pid=2465,fd=4),("httpd",pid=2464,fd=4),("httpd",pid=2463,fd=4),("httpd",pid=2460,fd=4))
    
    [yrlan@web ~]$ sudo firewall-cmd --add-port=80/tcp --zone=public --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --list-all
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

#### 🌞 **TEST**

- **Vérifier que le service est démarré**
    ```
    [yrlan@web ~]$ sudo systemctl is-active httpd.service
    active
    ```

- **Vérifier qu'il est configuré pour démarrer automatiquement**
    ```
    [yrlan@web ~]$ sudo systemctl is-enabled httpd.service
    enabled
    ```

- **Vérifier avec une commande `curl localhost` que vous joignez votre serveur web localement**
  ```
  [yrlan@web ~]$ curl localhost
  <!doctype html>
  <html>
  [...]
  </html>
  ```

- **Vérifier avec votre navigateur (sur votre PC) que vous accéder à votre serveur web**

> Depuis PowerShell sur mon Windows
  ```
  PS C:\Users\yrlan> curl 10.102.1.11:80
  <!doctype html>
  <html>
  [...]
  </html>
  ```

## 2. Avancer vers la maîtrise du service

#### 🌞 **Le service Apache...**

- **Donnez la commande qui permet d'activer le démarrage automatique d'Apache quand la machine s'allume**
  ```
  [yrlan@web ~]$ sudo systemctl enable httpd.service
  ```

- **Prouvez avec une commande qu'actuellement, le service est paramétré pour démarré quand la machine s'allume**
  ```
  [yrlan@web ~]$ sudo systemctl is-enabled httpd.service
  enabled
  ```

- **Affichez le contenu du fichier `httpd.service` qui contient la définition du service Apache**
  ```
  [yrlan@web ~]$ cat /usr/lib/systemd/system/httpd.service
  [Unit]
  Description=The Apache HTTP Server
  Wants=httpd-init.service
  After=network.target remote-fs.target nss-lookup.target httpd-init.service
  Documentation=man:httpd.service(8)

  [Service]
  Type=notify
  Environment=LANG=C

  ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
  ExecReload=/usr/sbin/httpd $OPTIONS -k graceful

  # Send SIGWINCH for graceful stop
  KillSignal=SIGWINCH
  KillMode=mixed
  PrivateTmp=true

  [Install]
  WantedBy=multi-user.target
  ```

#### 🌞 **Déterminer sous quel utilisateur tourne le processus Apache**

- **Mettez en évidence la ligne dans le fichier de conf qui définit quel user est utilisé**
  ```
  [yrlan@web ~]$ sudo cat /etc/httpd/conf/httpd.conf | grep User
  User apache
  ```

- **Utilisez la commande `ps -ef` pour visualiser les processus en cours d'exécution et confirmer que apache tourne bien sous l'utilisateur mentionné dans le fichier de conf**
  ```
  [yrlan@web ~]$ ps -ef | grep apache
  apache      2708    2706  0 16:45 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
  apache      2709    2706  0 16:45 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
  apache      2710    2706  0 16:45 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
  apache      2711    2706  0 16:45 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
  ```
  > **On voit que le nom d'utilisateur du processus `/usr/sbin/httpd` est défini sur `apache`**
 
- **La page d'accueil d'Apache se trouve dans `/usr/share/testpage/`**
  - **Vérifiez avec un ls -al que tout son contenu est accessible en lecture
  à l'utilisateur mentionné dans le fichier de conf**

  > **On a bien les accès en lecture (r)**
  ```
  [yrlan@web testpage]$ ls -l /usr/share/testpage/
  total 8
  -rw-r--r--. 1 root root 7621 Jun 11 17:23 index.html
  ```

#### **🌞 Changer l'utilisateur utilisé par Apache**

- **Créez le nouvel utilisateur**
  - **Pour les options de création, inspirez-vous de l'utilisateur Apache existant**
    - **Le fichier `/etc/passwd` contient les informations relatives aux utilisateurs existants sur la machine**
    - **Servez-vous en pour voir la config actuelle de l'utilisateur Apache par défaut**
    ```
    [yrlan@web ~]$ sudo cat /etc/passwd | grep apache
    apache:x:48:48:Apache:/usr/share/httpd:/sbin/nologin

    [yrlan@web ~]$ sudo useradd apache2 -d /usr/share/httpd -s /sbin/nologin
    useradd: warning: the home directory already exists.
    Not copying any file from skel directory into it.

    [yrlan@web ~]$ sudo cat /etc/passwd | grep apache
    apache:x:48:48:Apache:/usr/share/httpd:/sbin/nologin
    apache2:x:1001:1001::/usr/share/httpd:/sbin/nologin
    ```

- **Modifiez la configuration d'Apache pour qu'il utilise ce nouvel utilisateur**
  ```
  [yrlan@web ~]$ sudo nano /etc/httpd/conf/httpd.conf
  [yrlan@web ~]$ sudo cat /etc/httpd/conf/httpd.conf | grep apache2
  User apache2
  Group apache2
  ```

- **Redémarrez Apache**
  - `sudo systemctl restart httpd`

- **Utilisez une commande `ps` pour vérifier que le changement a pris effet**
  ```
  [yrlan@web ~]$ ps -ef | grep apache
  apache2     1878    1876  0 15:48 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
  apache2     1879    1876  0 15:48 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
  apache2     1880    1876  0 15:48 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
  apache2     1881    1876  0 15:48 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
  ```

#### **🌞 Faites en sorte que Apache tourne sur un autre port**

- **Modifiez la configuration d'Apache pour lui demande d'écouter sur un autre port**
  ```
  [yrlan@web ~]$ sudo cat /etc/httpd/conf/httpd.conf | grep Listen
  Listen 8000
  ```

- **Ouvrez un nouveau port firewall, et fermez l'ancien**
  ```
  [yrlan@web ~]$ sudo firewall-cmd --add-port=8000/tcp --zone=public --permanent; sudo firewall-cmd --remove-port=80/tcp --zone=public --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --list-all
  success
  success
  success
  public (active)
    target: default
    icmp-block-inversion: no
    interfaces: enp0s3 enp0s8
    sources:
    services: ssh
    ports: 8000/tcp
    protocols:
    masquerade: no
    forward-ports:
    source-ports:
    icmp-blocks:
    rich rules:
  ```

- **Redémarrez Apache**
  ```
  [yrlan@web ~]$ sudo systemctl restart httpd
  ```

- **Prouvez avec une commande `ss` que Apache tourne bien sur le nouveau port choisi**
  ```
  [yrlan@web ~]$ sudo ss -alnpt | grep httpd
  LISTEN 0      128                *:8000            *:*    users:(("httpd",pid=2196,fd=4),("httpd",pid=2195,fd=4),("http
  ",pid=2194,fd=4),("httpd",pid=2191,fd=4))
  ```

- **Vérifiez avec `curl` en local que vous pouvez joindre Apache sur le nouveau port**
  ```
  [yrlan@web ~]$ curl localhost:8000
  <!doctype html>
  <html>
  [...]
  </html>
  ```

- **Vérifiez avec votre navigateur que vous pouvez joindre le serveur sur le nouveau port**
  ```
  PS C:\Users\yrlan> curl 10.102.1.11:8000
  <!doctype html>
  <html>
  [...]
  </html>
  ```

> **📁 Fichier [/etc/httpd/conf/httpd.conf](./conf/httpd_8000.conf) (avec config utilisateur et groupe apache2 + écoute sur port 8000)**

# II. Une stack web plus avancée

## 2. Setup

> **🖥️ VM db.tp2.linux**

### A. Serveur Web et NextCloud

**Créez les 2 machines et déroulez la [📝**checklist**📝](#checklist).**

#### **🌞 Install du serveur Web et de NextCloud sur `web.tp2.linux`**
- **Je veux dans le rendu **toutes** les commandes réalisées**
  - **N'oubliez pas la commande `history` qui permet de voir toutes les commandes tapées précédemment**
```
# Install pré-requis + php compatible avec nextcloud
[yrlan@web ~]$ sudo dnf install -y epel-release; sudo dnf update -y
[yrlan@web ~]$ sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
[yrlan@web ~]$ sudo dnf module list php
[yrlan@web ~]$ sudo dnf module enable -y php:remi-7.4
[yrlan@web ~]$ sudo dnf module list php
# [e] pour enabled
php remi-7.4 [e] common [d], devel, minimal PHP scripting language 

[yrlan@web ~]$ sudo dnf install -y httpd mariadb-server vim wget zip unzip libxml2 openssl php74-php php74-php-ctype php74-php-curl php74-php-gd php74-php-iconv php74-php-json php74-php-libxml php74-php-mbstring php74-php-openssl php74-php-posix php74-php-session php74-php-xml php74-php-zip php74-php-zlib php74-php-pdo php74-php-mysqlnd php74-php-intl php74-php-bcmath php74-php-gmp

# Créations dossiers sites-available et sites-enabled + raccourci
[yrlan@web ~]$ sudo mkdir /etc/httpd/conf/sites-available
[yrlan@web ~]$ sudo mkdir /etc/httpd/conf/sites-enabled
[yrlan@web ~]$ sudo nano /etc/httpd/conf/sites-available/web.tp2.linux
[yrlan@web ~]$ sudo ln -s /etc/httpd/conf/sites-available/web.tp2.linux /etc/httpd/conf/sites-enabled/
[yrlan@web ~]$ cat /etc/httpd/conf/httpd.conf | grep "IncludeOptional"
IncludeOptional conf.d/*.conf
IncludeOptional conf/sites-enabled/*

# Téléchargement + install de nextcloud
[yrlan@web ~]$ wget https://download.nextcloud.com/server/releases/nextcloud-22.2.0.zip
[yrlan@web ~]$ unzip nextcloud-22.2.0.zip
[yrlan@web ~]$ cd nextcloud/
[yrlan@nextcloud]$ sudo mkdir -p /var/www/sub-domains/web.tp2.linux/html
[yrlan@nextcloud]$ sudo mkdir /var/www/sub-domains/web.tp2.linux/data
[yrlan@nextcloud]$ sudo cp -Rf * /var/www/sub-domains/web.tp2.linux/html/
[yrlan@nextcloud]$ sudo chown -R apache.apache /var/www/sub-domains/*

# Régler la langue pour NextCloud
[yrlan@web ~]$ timedatectl | grep "Time zone"
                Time zone: Europe/Paris (CEST, +0200)
[yrlan@web ~]$ sudo cat /etc/opt/remi/php74/php.ini | grep ";date.timezone ="
date.timezone = "Europe/Paris"

# Config Pare-Feu + relancer apache
[yrlan@web sub-domains]$ sudo firewall-cmd --add-port=80/tpc --zone=public --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --list-all
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

[yrlan@web ~]$ sudo systemctl restart httpd
```

**Une fois que vous avez la page d'accueil de NextCloud sous les yeux avec votre navigateur Web, NE VOUS CONNECTEZ PAS et continuez le TP**

**📁 Fichier [/etc/httpd/conf/httpd.conf](./conf/httpd_80.conf) (avec config de base : utilisateur et groupe apache + écoute sur port 80)****  
**📁 Fichier [/etc/httpd/conf/sites-available/web.tp2.linux](./conf/web.tp2.linux)**

### **B. Base de données**

#### **🌞 Install de MariaDB sur `db.tp2.linux`**

- **Je veux dans le rendu toutes les commandes réalisées**
```
[yrlan@db ~]$ sudo dnf install -y mariadb-server
[yrlan@db ~]$ sudo systemctl enable mariadb
Created symlink /etc/systemd/system/mysql.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/mysqld.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/multi-user.target.wants/mariadb.service → /usr/lib/systemd/system/mariadb.service.
[yrlan@db ~]$ sudo systemctl start mariadb

## Ici j'ai tout laisse par défaut [Y] et mis un pwd : root ( simple juste pour retenir pour le tp )
[yrlan@db ~]$ sudo mysql_secure_installation
```

- **Vous repérerez le port utilisé par MariaDB avec une commande `ss` exécutée sur `db.tp2.linux`**
```
[yrlan@db ~]$ sudo ss -alnpt | grep mysql
LISTEN 0      80                 *:3306            *:*    users:(("mysqld",pid=26461,fd=21))

[yrlan@db ~]$ sudo firewall-cmd --add-port=3306/tcp --zone=public --permanent; sudo firewall-cmd --reload; sudo firewall-cmd --list-all
success
success
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: ssh
  ports: 3306/tcp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

#### **🌞 Préparation de la base pour NextCloud**

- **Une fois en place, il va falloir préparer une base de données pour NextCloud :**
  - **Connectez-vous à la base de données à l'aide de la commande `sudo mysql -u root`**
  - **Exécutez les commandes SQL suivantes :**

```SQL
[yrlan@db ~]$ sudo mysql -u root -p

# Dans notre cas, c'est l'IP de web.tp2.linux
# "db_pwd" c'est le mot de passe :D
CREATE USER 'nextcloud'@'10.102.1.11' IDENTIFIED BY 'db_pwd';

# Création de la base de donnée qui sera utilisée par NextCloud
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

# On donne tous les droits à l'utilisateur nextcloud sur toutes les tables de la base qu'on vient de créer
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'10.102.1.11';

# Actualisation des privilèges
FLUSH PRIVILEGES;
```

#### 🌞 **Exploration de la base de données**

- **Afin de tester le bon fonctionnement de la base de données, vous allez essayer de vous connecter, comme NextCloud le fera :**
  - **Depuis la machine `web.tp2.linux` vers l'IP de `db.tp2.linux`**
  - **Vous pouvez utiliser la commande `mysql` pour vous connecter à une base de données depuis la ligne de commande**
    - **Par exemple `mysql -u <USER> -h <IP_DATABASE> -p`**
- **Utilisez les commandes SQL fournies ci-dessous pour explorer la base**

```sql
[yrlan@web ~]$ sudo mysql -u nextcloud -h 10.102.1.12 -p
Enter password: db_pwd

Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 19
Server version: 10.3.28-MariaDB MariaDB Server

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| nextcloud          |
+--------------------+
2 rows in set (0.002 sec)

MariaDB [(none)]> USE nextcloud
Database changed
MariaDB [nextcloud]> SHOW TABLES;
Empty set (0.001 sec)
```

- **Trouver une commande qui permet de lister tous les utilisateurs de la base de données**
  ```sql
  MariaDB [(none)]> GRANT ALL PRIVILEGES ON mysql.* TO 'nextcloud'@'10.102.1.11';

  MariaDB [(none)]> SELECT user,host FROM mysql.user;
  +-----------+-------------+
  | user      | host        |
  +-----------+-------------+
  | nextcloud | 10.102.1.11 |
  | root      | 127.0.0.1   |
  | root      | ::1         |
  | root      | localhost   |
  +-----------+-------------+
  4 rows in set (0.001 sec)
  ```

### **C. Finaliser l'installation de NextCloud**

#### **🌞 sur votre PC**

- **Modifiez votre fichier `hosts` (oui, celui de votre PC, de votre hôte)**
  - **Pour pouvoir joindre l'IP de la VM en utilisant le nom `web.tp2.linux`**
  ```
  # Sur mon Windows
  C:\Windows\System32\drivers\etc\hosts

  # J'ai rajouté 
  10.102.1.11 	web.tp2.linux
  ```

- **Avec un navigateur, visitez NextCloud à l'URL `http://web.tp2.linux`**
  ```
  PS C:\Users\yrlan> curl web.tp2.linux
  <!DOCTYPE html>
  <html>
  <head>
          <script> window.location.href="index.php"; </script>
          <meta http-equiv="refresh" content="0; URL=index.php">
  </head>
  </html>
  ```

- **Cliquez sur "Storage & Database" juste en dessous**

  > **Ici j'ai changé le répertoire des données comme indiqué sur la doc pour `/var/www/sub-domains/web.tp2.linux/data`**

  - **Choisissez "MySQL/MariaDB"**
  - **Saisissez les informations pour que NextCloud puisse se connecter avec votre base**
    - **database_user = `nextcloud`**
    - **dabate_pwd = `db_pwd`**
    - **database_name = `nextcloud`**
    - **database_host = `10.102.1.12`**

- **Saisissez l'identifiant et le mot de passe admin que vous voulez, et validez l'installation**
  - **user = `yrlan`**
  - **pwd = `root`**

#### **🌞 Exploration de la base de données**

- **Connectez vous en ligne de commande à la base de données après l'installation terminée**
  ```
  [yrlan@web nextcloud]$ sudo mysql -u nextcloud -h 10.102.1.12 -p
  ```

- **Déterminer combien de tables ont été crées par NextCloud lors de la finalisation de l'installation**
  - ***Bonus points*** **si la réponse à cette question est automatiquement donnée par une requête SQL**
  ```sql
  MariaDB [(none)]> SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'nextcloud';
  +----------+
  | COUNT(*) |
  +----------+
  |      108 |
  +----------+
  1 row in set (0.001 sec)
  ```

> **Ce tableau devra figurer à la fin du rendu, avec les ? remplacés par la bonne valeur (un seul tableau à la fin). Je vous le remets à chaque fois, à des fins de clarté, pour lister les machines qu'on a à chaque instant du TP.**

| Machine         | IP            | Service                 | Port ouvert | IP autorisées |
|-----------------|---------------|-------------------------|-------------|---------------|
| `web.tp2.linux` | `10.102.1.11` | Serveur Web             | 80          | 10.102.1.0/24 |
| `db.tp2.linux`  | `10.102.1.12` | Serveur Base de Données | 3306        | 10.102.1.11   |
