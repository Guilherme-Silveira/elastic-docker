# Elastic Stack on Docker

Execute a versão mais recente da Elastic Stack com Docker e Docker Compose.

Ele oferece a capacidade de analisar qualquer conjunto de dados usando os recursos de pesquisa/agregação do Elasticsearch e
o poder de visualização de Kibana.


*O cluster é pré-configurado com uma licença Platinum Trial (consulte [Como desativar recursos pagos](#how-to-disable-paid-features) para desativá-los). **A
licença [trial-license] é válida por 30 dias**. Depois que esta licença expirar, você poderá continuar usando os recursos gratuitos
perfeitamente, sem perder nenhum dado.*

---

# Sumário

---
- [Elastic Stack on Docker](#elastic-stack-on-docker)
- [Sumário](#sumário)
- [Requisitos](#requisitos)
    - [Configurações necessárias](#configurações-necessárias)
    - [Configurações de memória da Stack](#configurações-de-memória-da-stack)
    - [Frozen Cache](#frozen-cache)
    - [Portas expostas pela Elastic Stack](#portas-expostas-pela-elastic-stack)
    - [Docker Desktop](#docker-desktop)
      - [macOS](#macos)
- [Execução](#execução)
    - [Versão da Stack](#versão-da-stack)
    - [Senha dos usuários de sistema](#senha-dos-usuários-de-sistema)
    - [Executar a Stack](#executar-a-stack)
    - [Executar a Stack Hot-Warm-Cold-Frozen](#executar-a-stack-hot-warm-cold-frozen)
    - [Upgrade de versão](#upgrade-de-versão)
    - [Upgrade a Stack Hot-Warm-Cold-Frozen](#upgrade-a-stack-hot-warm-cold-frozen)
    - [Desligar a Stack](#desligar-a-stack)
    - [Desligar a Stack Hot-Warm-Cold-Frozen](#desligar-a-stack-hot-warm-cold-frozen)
    - [Remover Stack](#remover-stack)
    - [Remover a Stack Hot-Warm-Cold-Frozen](#remover-a-stack-hot-warm-cold-frozen)
- [Initial setup](#initial-setup)
    - [Autenticação](#autenticação)
    - [Acessar Kibana](#acessar-kibana)
- [Configuração](#configuração)
    - [Diretório de configuração de cada componente](#diretório-de-configuração-de-cada-componente)
    - [Expiração da Licença](#expiração-da-licença)
- [Extensão](#extensão)
    - [Como adicionar plugins](#como-adicionar-plugins)
- [Fleet/APM](#fleetapm)

---
# Requisitos
---
### Configurações necessárias

* [Docker Engine](https://docs.docker.com/install/) versão **17.05** ou mais recente
* [Docker Compose](https://docs.docker.com/compose/install/) versão **1.20.0** ou mais recente
* 8GB of RAM (Mínimo)

### Configurações de memória da Stack

- **docker-compose.yaml**

  Os serviços do Elasticsearch, Logstash e Enterprise Search possuem configurações de JVM Heap Size. Em todos eles, essa memória é configurada em variáveis de ambiente em cada um dos containers, então por favor, altere os valores de acordo com o seu ambiente.

- **docker-compose-hwcf.yaml**

  Os serviços do ES01, ES02, ES03, ES04, Logstash e Enterprise Search possuem configurações de JVM Heap Size. Em todos eles, essa memória é configurada em variáveis de ambiente em cada um dos containers, então por favor, altere os valores de acordo com o seu ambiente.

**Elasticsearch Heap**:
  
  - ES_JAVA_OPTS: "-Xmx2048m -Xms2048m"

**Logstash Heap**:

  - LS_JAVA_OPTS: "-Xmx512m -Xms512m"
  
**Enterprise Search Heap**:

  - "JAVA_OPTS=-Xms512m -Xmx512m"

### Frozen Cache

  Na Stack Hot-Warm-Cold-Frozen (docker-compose-hwcf.yaml), no serviço `es04` (frozen node), foi definido o parâmetro `xpack.searchable.snapshot.shared_cache.size=5GB` nas variáveis de ambiente. Esse parâmetro define o quanto do disco da sua máquina será utilizado para cache no frozen node. O valor default é `5GB`, porém é válido ajustar esse parâmetro de acordo com o disco da sua máquina e do seu caso de uso.

---
### Portas expostas pela Elastic Stack

* 5044: Logstash Beats input
* 9600: Logstash monitoring API
* 9200: Elasticsearch HTTP
* 9300: Elasticsearch TCP transport
* 5601: Kibana
* 3002: Enterprise Search
* 8200: APM Server Integration
* 8220: Fleet Server

---
### Docker Desktop


#### macOS

A configuração padrão do _Docker Desktop para Mac_ permite montar arquivos de `/Users/`, `/Volume/`, `/private/`,
`/tmp` e `/var/folders` exclusivamente. Certifique-se de que o repositório está clonado em um desses locais.

---
# Execução
---
### Versão da Stack

Esse repositório está configurado com a versão 8.7.0 da Elastic Stack. Para mudar a versão da Stack, accesse o arquivo `.env` que está localizado na raiz desse repositório e mude o valor da variável de ambiente `ELK_VERSION` para a versão desejada.

---
### Senha dos usuários de sistema

Para trocar a senha dos usuários de sistema, incluindo a senha do usuário `elastic`, acesse o arquivo `.env` que está localizado na raiz desse repositório e mude o valor das variáveis de ambiente `ELASTIC_PASSWORD`, `LOGSTASH_INTERNAL_PASSWORD` e `KIBANA_SYSTEM_PASSWORD`.

---
### Executar a Stack

No diretório raiz do projeto, execute o seguinte comando:

```console
$ docker compose up -d
```

### Executar a Stack Hot-Warm-Cold-Frozen

No caso da execução da Stack HWCF, existe um pré requisito. É necessário configurar o parâmetro `vm.max_map_count` no seu Sistema Operacional. Para fazer isso no seu sistema operacional (Linux, Mac ou Windows), siga as instruções descritas [aqui](https://www.elastic.co/guide/en/elasticsearch/reference/master/docker.html#_set_vm_max_map_count_to_at_least_262144). 

No diretório raiz do projeto, execute o seguinte comando:

```console
$ docker compose -f docker-compose-hwcf.yaml up -d 
```

Obs: Nesse projeto, o bucket para snapshot no Minio é criado automaticamente e, no Elasticsarch, o repositório de Snapshot e a SLM Policy (snapshots diários) também são criados automaticamente.

---
### Upgrade de versão

Para atualizar a versão da Stack, acesse o arquivo `.env` localizado no diretório raiz do repositório e modifique a veriável de ambiente `ELK_VERSION` para a versão desejada. Para efetivamente aplicar a nova versão, remova os containers em execução:
 ```console
 $ docker-compose down
 ```
  **NÃO USE O `-v`, PARA EVITAR QUE OS DADOS SEJAM REMOVIDOS NO PROCESSO** e, em seguida execute os seguintes comandos:

```console
$ docker-compose build
$ docker-compose up -d
```

Uma alternativa ao comandos de `build` e `up` acima seria executar o seguinte comando:

```console
$ docker-compose up -d --build
```

**:Aviso: Você também precisa reconstruir as imagens da Stack executando o comando `docker-compose build` toda vez que você modificar alguma configuração nos arquivos yaml dos componentes da Stack.**

Se você está executando esse Stack pela primeira vez, por favor, leia atentamente o bloco acima.

### Upgrade a Stack Hot-Warm-Cold-Frozen

Siga os mesmos passos acima, porém inclua o `-f docker-compose-hwcf.yaml` entre o statement `docker-compose` e a ação que será executada (e.g., `up -d --build`). Exemplificando o resultado final, ficaria assim:

```console
$ docker-compose -f docker-compose-hwcf.yaml up -d --build
```

---
### Desligar a Stack

Para simplesmente parar os containers da Stack que estão em execução e não remover os dados, execute o seguinte comando:

```console
$ docker-compose stop
```

### Desligar a Stack Hot-Warm-Cold-Frozen

No diretório raiz do projeto, execute o seguinte comando:

```console
$ docker compose -f docker-compose-hwcf.yaml stop
```

---
### Remover Stack

Os dados do Elasticsearch são persistidos em um volume por padrão. 

Para remover completamente a Stack, incluindo os dados persistidos, execute o seguinte comando:

```console
$ docker-compose down -v
```

### Remover a Stack Hot-Warm-Cold-Frozen

No diretório raiz do projeto, execute o seguinte comando:

```console
$ docker compose -f docker-compose-hwcf.yaml down -v
```

---
# Initial setup

---
### Autenticação

A Stack é pré-configurada, por padrão, com as seguintes credenciais:

* user: *elastic*
* password: *changeme*

---
### Acessar Kibana

Após mais ou menos 1 minuto, o Kibana já deve estar operacional. Para acessá-lo, entre no seu navegador e acesse a seguinte URL <http://localhost:5601> 

Credenciais:

* user: *elastic*
* password: *\<senha definida no arquivo `.env`>*

---
# Configuração

---
Configurações nos arquivos YAML não são dinâmicas, ou seja, caso mude alguma das configurações definidas por padrão, reconstrua as imagens (`docker-compose build`) e reinicie o ambiente (`docker-compose down` e depois `docker-compose up -d`).

---
### Diretório de configuração de cada componente

* Elasticsearch: `elasticsearch/config/`
* Kibana: `kibana/config/`
* Logstash : `logstash/config/`
* Fleet Server: `agent-data/` **Esse diretório só será criado após a primeira execução da Stack**

**Enterprise Search e Fleet Server são configurados com variáveis de ambiente no próprio docker-compose.yaml**

---

### Expiração da Licença

Após 30 dias, a licença Platinum Trial irá expirar. Caso você não precisa dos dados que estão atualmente armazenados no cluster e queira continuar usando a licença Platinum, remova toda a Stack, incluindo os volumes:

```console
$ docker-compose down -v
```

e crie a Stack novamente:

```console
$ docker-compose up -d
```

Esse novo ambiente estará com uma nova licença de 30 dias, porém todos os dados que você tinha anteriormente serão perdidos, então use esse approach com cautela.

---
# Extensão

---
### Como adicionar plugins

Para adicionar plugins aos componentes da Elastic Stack, siga os seguintes passos:

1. Adicione uma cláusula `RUN`  ao `Dockerfile` correspondente (eg. `RUN logstash-plugin install logstash-filter-json`)
2. Reconstrua as imagens usando o comando `docker-compose build`

---
# Fleet/APM

---
Eu fiz algumas pesquisas e tive muita dificuldade em achar algum ambiente que o Elastic Agent já executasse automaticamente a integração do Fleet Server e do APM. Devido a isso, gostaria de compartilhar como criar uma Agent Policy pré-configurada usando parâmetros no arquivo `kibana/config/kibana.yml` para configurar as integrações do Fleet Server e do APM:
   ```yaml
    xpack.fleet.packages:
    - name: apm
    version: latest
    - name: elastic_agent
    version: latest
    - name: fleet_server
    version: latest
    - name: system
    version: latest

    xpack.fleet.agentPolicies:
    - name: Fleet APM Server
    id: fleet-server
    namespace: default
    is_default_fleet_server: true
    unenroll_timeout: 900
    monitoring_enabled:
    - logs
    - metrics
    is_default: true
    package_policies:
    - name: apm-1
      id: apm-1
      package:
        name: apm
      inputs:
      - type: apm
        keep_enabled: true
        vars:
        - name: host
          value: 0.0.0.0:8200
          frozen: true
        - name: url
          value: "http://0.0.0.0:8200"
          frozen: true
        - name: enable_rum
          value: true
          frozen: true
    - name: fleet_server-1
      id: fleet_server-1
      package:
        name: fleet_server

    xpack.fleet.agents.elasticsearch.hosts: ["http://elasticsearch:9200"]
    xpack.fleet.agents.fleet_server.hosts: ["http://fleet-server:8220"]
   ```
