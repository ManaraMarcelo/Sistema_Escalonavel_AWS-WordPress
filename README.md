# Projeto AWS: Ambiente Escalável para WordPress com EFS, RDS e Auto Scaling

Este projeto tem como objetivo criar uma infraestrutura escalável e altamente disponível na AWS para hospedar uma aplicação WordPress com persistência de dados e automação completa, utilizando EC2, Load Balancer, EFS, RDS e Auto Scaling.

## ✅ Funcionalidades

- **Ambiente escalável com Auto Scaling Group**
- **Persistência de arquivos com Amazon EFS**
- **Banco de dados gerenciado com Amazon RDS (MySQL)**
- **Balanceamento de carga com Elastic Load Balancer**
- **Deploy automatizado via script de inicialização (User Data)**
- **Segurança com Security Groups bem definidos**

---

## 📁 Estrutura de Serviços Utilizados

- **VPC personalizada**
  - 2 Subnets públicas (EC2 + Load Balancer)
  - 2 Subnets privadas (EFS + RDS)
- **Amazon EC2**
  - Docker Compose com WordPress
  - Instância base para Auto Scaling (Launch Template)
- **Amazon RDS (MySQL)**
  - Banco de dados do WordPress
- **Amazon EFS**
  - Armazenamento de arquivos persistente e compartilhado
- **Elastic Load Balancer (Classic)**
  - Acesso externo ao site WordPress
- **Auto Scaling Group**
  - 2 instâncias (padrão, podendo variar de 1 a 3) com verificação de saúde e alta disponibilidade

---

## ⚙️ Passos de Configuração

### 1. Criar a VPC
![rotas vpc](images/vpc01.png)
- Subnets públicas para o Load Balancer
- Subnets privadas para EC2 e RDS

### 2. Configurar Security Groups
- SG do ALB (Load Balancer):
    - inbound rules:  
    all trafic -> 0.0.0.0/0   
    all trafic -> ::/0
    - outbound rules:   
    deixar vazio
      
- SG da EC2:
    - inbound rules:   
    SSH -> TCP -> 22 -> My IP [para configuração e conexão como dev]   
    HTTP -> TCP -> 80 -> SG-ALB [entrada do Load Balancer]   
    NFS -> TCP -> 2049 -> SG-EFS [entrada do Elástic File System]     
    - outbound rules:    
    ALL trafic -> 0.0.0.0/0

- SG do RDS:
    - inbound rules:   
    MYSQL/Aurora -> TCP -> 3306 -> SG-EC2 [entrada da ec2 apenas]
    - outbound rules:    
    ALL trafic -> 0.0.0.0/0

- SG do EFS:
    - inbound rules:   
    NFS -> TCP -> 2049 -> SG-EC2
    - outbound rules: 
    ALL trafic -> 0.0.0.0/0

### 3. Criar o File System (EFS)
- Integrado com as subnets privadas
- Montado em todas as instâncias EC2 via Docker

### 4. Criar o banco de dados RDS (MySQL)
- Na mesma VPC e subnets privadas
- Configurar endpoint, nome do banco, usuário e senha

### 5. Criar a Instância EC2 base
- Utilizar AMI Ubuntu
- Adicionar script no **User Data** para:
  - Instalar Docker ou containerd
  - Montar EFS
  - Rodar container do WordPress com variáveis de ambiente do RDS
  - Criar usuário para não usar o ubuntu com permissão root
- User data utilizado: [`userData.sh`](./userData.sh)

### 6. Criar Template de Lançamento (Launch Template)
- Baseado na instância EC2 configurada
- Deve conter:
  - AMI ubuntu
  - Par de chaves (opcional caso precise conectar via SSH)
  - Security Group da EC2 (SG-EC2)
  - Script de **User Data**

### 7. Criar o Target Group

![](images/targetgroup01.png)
![](images/targetgroup012.png)
![](images/targetgroup03.png)
    - em Health Check colocamos o seguinte caminho:

    ```sh
    /wp-admin/images/wordpress-logo.svg
    ```


### 8. Criar o Load Balancer Application
- Tipo: Application Load Balancer
- Subnets: públicas
- Listeners:
  - HTTP na porta 80 direcionando para a porta 80 da instância
- Health Check:
  - Caminho: `Targuet Group`

  ![](images/loadbalancer03.png)

  - Porta: 80
  - Tempo entre verificações: 30s
  - Thresholds padrão (pode ser ajustado)

### 9. Criar Auto Scaling Group
- Baseado no Launch Template criado anteriormente    
    - Dê nome e escolha o template
![inicioAutoScaling](images/autoscaling01.png)

- Em Network: 
    - Escolhemos nossa VPC padrão e nossas subnets publicas 
    ![network autoscaling](images/autoscaling02.png)   

- Também: 
    - Selecione nosso Load Balancer que estará conectado ao Target Group
    ![selecione loadbalancer](images/autoscaling03.png)
- Configurações:
  - Mínimo: 1 instância
  - Desejado: 2 instâncias
  - Máximo: 3 instâncias
  - Health Check ativado (EC2 + Load Balancer)
    - Para verificar o Health Check usaremos o seguinte ping: /wp-admin/images/wordpress-logo.svg
  - Arquilo que não foi configurado, deixe como padrão






---

## 🐳 Docker & User Data

O script de User Data prepara automaticamente o ambiente com Docker Compose ou containerd, monta o EFS e inicia o WordPress:

🔗 **Link para o script `user_data.sh`:** [user_data.sh](./caminho/do/arquivo/user_data.sh)

---

## 🔐 Considerações de Segurança

- Nenhuma instância EC2 fica com IP público exposto diretamente.
- Acesso ao WordPress ocorre **somente via Load Balancer**.
- Acesso por SSH restrito apenas ao IP do desenvolvedor.
- Separação de Security Groups por função (EC2, ALB, EFS, RDS).
- Utilização de EFS permite compartilhamento de arquivos entre instâncias do Auto Scaling sem perda de dados.

---

## 📸 Screenshots da Arquitetura

> (Você pode adicionar imagens salvas localmente, como explicado anteriormente)

```markdown
![Arquitetura AWS](assets/arquitetura-aws.png)
