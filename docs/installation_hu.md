# Magento 2.4.7 Telepítési Útmutató

## Előfeltételek Ellenőrzése

✅ PHP 8.3 - Teljesítve (php:8.3-fpm image)
✅ MySQL 8.0 - Teljesítve (mysql:8.0 image)
✅ OpenSearch 2.12 - Teljesítve (opensearchproject/opensearch:2.12.0 image)
✅ Redis 7.2 - Teljesítve (redis:7.2-alpine image)
✅ RabbitMQ 3.13 - Teljesítve (rabbitmq:3.13-management-alpine image)
✅ Nginx 1.24 - Teljesítve (nginx:1.24-alpine image)
✅ Composer 2.7 - Teljesítve (composer:2.7 image)

## 1. Környezeti Változók Beállítása

Hozza létre vagy módosítsa a `.env` fájlt a projekt gyökérkönyvtárában a Docker szolgáltatások konfigurálásához:

```env
# Projekt
COMPOSE_PROJECT_NAME=magento-local

# Adatbázis
MYSQL_ROOT_PASSWORD=magento
MYSQL_DATABASE=magento
MYSQL_USER=magento
MYSQL_PASSWORD=magento

# Redis
REDIS_PASSWORD=magento

# RabbitMQ
RABBITMQ_DEFAULT_USER=magento
RABBITMQ_DEFAULT_PASS=magento

# PHP
PHP_MEMORY_LIMIT=4G
PHP_OPCACHE_REVALIDATE_FREQ=0
PHP_MAX_EXECUTION_TIME=1800

# OpenSearch
OPENSEARCH_DISABLE_SECURITY=true
OPENSEARCH_DISABLE_DEMO=true
OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m
```

## 2. Docker Környezet Indítása

```bash
# Minden szolgáltatás indítása
docker compose --profile full up -d

# Szolgáltatások állapotának ellenőrzése
docker compose ps
```

Várjon, amíg minden szolgáltatás "healthy" státuszba kerül.

## 3. Magento Telepítése

### 3.1. Könyvtárszerkezet Előkészítése

```bash
# src könyvtár törlése (ha létezik)
rm -rf src
mkdir src
```

### 3.2. Magento Letöltése

```bash
# Magento letöltése Composer segítségével
docker compose run --rm php composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:2.4.7 .
```

Amikor kéri:

1. Adja meg a Magento Marketplace hitelesítési adatait:
   - Felhasználónév: Az Ön `Public Key`-e
   - Jelszó: Az Ön `Private Key`-e
2. Válaszoljon `yes`-szel a "Do you want to store credentials for repo.magento.com in /var/www/.composer/auth.json ?" kérdésre

### 3.3. Jogosultságok Beállítása

```bash
# Jogosultságok beállítása
docker compose exec php chmod -R 777 var generated pub/static pub/media app/etc
```

### 3.4. Magento Telepítése

```bash
docker compose exec php bin/magento setup:install \
  --base-url=http://localhost/ \
  --db-host=mysql \
  --db-name=magento \
  --db-user=magento \
  --db-password=magento \
  --admin-firstname=Admin \
  --admin-lastname=User \
  --admin-email=admin@example.com \
  --admin-user=admin \
  --admin-password=admin123 \
  --language=hu_HU \
  --currency=HUF \
  --timezone=Europe/Budapest \
  --use-rewrites=1 \
  --search-engine=opensearch \
  --opensearch-host=opensearch \
  --opensearch-port=9200 \
  --opensearch-index-prefix=magento2 \
  --opensearch-enable-auth=0 \
  --cache-backend=redis \
  --cache-backend-redis-server=redis \
  --cache-backend-redis-port=6379 \
  --cache-backend-redis-password=magento \
  --cache-backend-redis-db=0 \
  --page-cache=redis \
  --page-cache-redis-server=redis \
  --page-cache-redis-port=6379 \
  --page-cache-redis-password=magento \
  --page-cache-redis-db=1 \
  --session-save=redis \
  --session-save-redis-host=redis \
  --session-save-redis-port=6379 \
  --session-save-redis-password=magento \
  --session-save-redis-db=2 \
  --amqp-host=rabbitmq \
  --amqp-port=5672 \
  --amqp-user=magento \
  --amqp-password=magento
```

## 4. Telepítés Utáni Beállítások

### 4.1. Fejlesztői Mód Beállítása

```bash
# Fejlesztői mód beállítása
docker compose exec php bin/magento deploy:mode:set developer

# Statikus tartalom telepítése
docker compose exec php bin/magento setup:static-content:deploy -f hu_HU en_US

# Gyorsítótár ürítése
docker compose exec php bin/magento cache:flush
```

### 4.2. Magyar Nyelvi Csomag Telepítése és Beállítása

```bash
# Magyar nyelvi csomag telepítése
docker compose exec php composer require snowdog/language-hu_hu

# Nyelvi csomag regisztrálása
docker compose exec php bin/magento setup:static-content:deploy hu_HU

# Alapértelmezett terület beállítása
docker compose exec php bin/magento config:set general/locale/code hu_HU

# Időzóna beállítása
docker compose exec php bin/magento config:set general/locale/timezone Europe/Budapest

# Pénznem beállítása
docker compose exec php bin/magento config:set currency/options/base HUF
docker compose exec php bin/magento config:set currency/options/default HUF
docker compose exec php bin/magento config:set currency/options/allow HUF

# Súlymértékegység beállítása kilogrammra
docker compose exec php bin/magento config:set general/locale/weight_unit kgs
```

### 4.3. Indexek Újraépítése

```bash
docker compose exec php bin/magento indexer:reindex
```

## 5. Kétfaktoros Hitelesítés (2FA) Kikapcsolása

A Magento 2.4.7 alapértelmezetten bekapcsolt 2FA-val települ. Fejlesztői környezetben általában kikapcsoljuk:

```bash
# Adobe IMS 2FA modul kikapcsolása
docker compose exec php bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth

# Alap 2FA modul kikapcsolása
docker compose exec php bin/magento module:disable Magento_TwoFactorAuth

# Gyorsítótár ürítése
docker compose exec php bin/magento cache:flush

# Adatbázis séma és adatok frissítése
docker compose exec php bin/magento setup:upgrade
```

## 6. Telepítés Ellenőrzése

A telepítés után ellenőrizze a következő URL-eket:

- Frontend: http://localhost/
- Admin: http://localhost/admin_XXXXX
  - Az admin URL egyedi, a telepítés során generálódik
  - Felhasználónév: admin
  - Jelszó: admin123
- OpenSearch: http://localhost:9200
- RabbitMQ: http://localhost:15672
  - Felhasználónév: magento
  - Jelszó: magento

## 7. Hibaelhárítás

### Gyorsítótár Problémák

```bash
# Minden gyorsítótár ürítése
docker compose exec php bin/magento cache:flush

# var könyvtár tisztítása
docker compose exec php rm -rf var/cache/* var/page_cache/* var/view_preprocessed/*
```

### Jogosultsági Problémák

```bash
# Jogosultságok visszaállítása
docker compose exec php chmod -R 777 var generated pub/static pub/media app/etc
```

### Adatbázis Problémák

```bash
# Adatbázis elérés ellenőrzése
docker compose exec mysql mysql -u magento -pmagento magento

# Felhasználói jogosultságok ellenőrzése
docker compose exec mysql mysql -u root -pmagento -e "SHOW GRANTS FOR 'magento'@'%';"

# Adatbázis újralétrehozása (ha szükséges)
docker compose exec mysql mysql -u root -pmagento -e "DROP DATABASE magento; CREATE DATABASE magento CHARACTER SET utf8mb4 COLLATE utf8mb4_hungarian_ci;"
```

### OpenSearch Problémák

```bash
# OpenSearch állapot ellenőrzése
curl http://localhost:9200/_cluster/health?pretty

# Indexek listázása
curl http://localhost:9200/_cat/indices?v
```

### Szolgáltatások Újraindítása

```bash
# Minden szolgáltatás újraindítása
docker compose --profile full restart

# Egy specifikus szolgáltatás újraindítása
docker compose restart [szolgáltatás-név]
```

### Környezet Újraépítése

```bash
# Konténerek leállítása és törlése a volume-okkal együtt
docker compose down -v

# Volume-ok ellenőrzése és törlése ha szükséges
docker volume ls
docker volume rm magento-local_mysql_data

# Környezet újraindítása
docker compose --profile full up -d
```

## További Megjegyzések

- A `.env` fájlt csak a Docker szolgáltatások konfigurálására használja
- A Magento telepítési paramétereit explicit módon adja meg a biztonságos működés érdekében
- A Docker környezet különböző profilokkal rendelkezik (web, db, cache, search, queue, full)
- Figyelje a szolgáltatások állapotát a telepítés során
- A Composer hitelesítési adatok megőrződnek a jövőbeli telepítésekhez
- Ne verziókezelje a `.env` fájlt, használja helyette a `.env.example` fájlt
- A Docker környezet megfelel minden Magento 2.4.7 rendszerkövetelménynek
- A magyar nyelvi csomag és a magyar területi beállítások alapértelmezetten telepítésre kerülnek
- A magyar adószám és számlázási beállítások külön konfigurálást igényelnek
- A fejlesztői környezetben ajánlott a 2FA kikapcsolása a könnyebb hozzáférés érdekében

### Hasznos Magyar Beállítások

#### Számlázási Beállítások

```bash
# ÁFA beállítása
docker compose exec php bin/magento config:set tax/defaults/country HU

# Adószám megjelenítése
docker compose exec php bin/magento config:set customer/address/taxvat_show 1

# Irányítószám formátum
docker compose exec php bin/magento config:set customer/address/postcode_validation_pattern "^[0-9]{4}$"
```

#### Megjelenítési Beállítások

```bash
# Dátum formátum
docker compose exec php bin/magento config:set general/locale/dateformat_full "Y. MM. d. H:mm:ss"
docker compose exec php bin/magento config:set general/locale/dateformat_medium "Y. MM. d."
docker compose exec php bin/magento config:set general/locale/dateformat_short "Y. MM. d."

# Telefonszám formátum
docker compose exec php bin/magento config:set customer/address/telephone_validation_pattern "^[0-9]{2}[0-9]{7}$"
```

#### Email Beállítások

```bash
# Email küldő beállítása
docker compose exec php bin/magento config:set trans_email/ident_general/name "Webáruház"
docker compose exec php bin/magento config:set trans_email/ident_general/email "webshop@example.com"

# Kapcsolat email
docker compose exec php bin/magento config:set trans_email/ident_support/name "Ügyfélszolgálat"
docker compose exec php bin/magento config:set trans_email/ident_support/email "support@example.com"
```
