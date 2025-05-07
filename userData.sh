#!/bin/bash
set -e

# Atualiza pacotes e instala Docker + Compose
apt-get update -y
apt-get install -y docker.io curl unzip

# Ativa Docker
systemctl start docker
systemctl enable docker

# Instala Docker Compose manualmente
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Cria novo usuário
useradd -m -s /bin/bash devuser
usermod -aG docker devuser

# Copia chave SSH do ubuntu para devuser
mkdir -p /home/devuser/.ssh
cp /home/ubuntu/.ssh/authorized_keys /home/devuser/.ssh/
chown -R devuser:devuser /home/devuser/.ssh
chmod 700 /home/devuser/.ssh
chmod 600 /home/devuser/.ssh/authorized_keys

# Cria diretório do projeto
mkdir -p /home/devuser/wordpress
chown devuser:devuser /home/devuser/wordpress

# Instala utilitários para EFS
apt-get install -y nfs-common

# Cria ponto de montagem local para o efs
mkdir -p /mnt/efs

# Monta o EFS (substitua fs-xxxxxx com o ID do seu EFS)
mount -t nfs4 -o nfsvers=4.1 fs-xxxxx:/ /mnt/efs

# Garante que o diretório exista para o volume
mkdir -p /mnt/efs/html
chown -R devuser:devuser /mnt/efs/html

# Adiciona docker-compose.yml com conexão RDS (substitua os valores)
cat <<EOF > /home/devuser/wordpress/docker-compose.yml
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: seuendpointRDS:3306
      WORDPRESS_DB_NAME: nomedobanco
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: suaSenha
    volumes:
      - /mnt/efs/html:/var/www/html
EOF

# Sobe o container com Docker Compose
cd /home/devuser/wordpress
sudo -u devuser docker-compose up -d