# AtoM Helm Chart

Este helm chart implanta a aplicação AtoM (Access to Memory) no OpenShift, incluindo todos os componentes necessários para um ambiente de produção.

## Componentes Incluídos

- **AtoM Application**: Aplicação principal PHP-FPM
- **AtoM Worker**: Processos worker para tarefas em background
- **Nginx**: Servidor web e proxy reverso
- **MySQL/Percona**: Banco de dados
- **Memcached**: Cache em memória
- **Gearman**: Sistema de filas de tarefas

## Pré-requisitos

- OpenShift 4.x ou Kubernetes 1.19+
- Helm 3.x
- Elasticsearch externo (não incluído neste chart)
- Storage class configurado para persistent volumes

## Instalação

### 1. Adicionar o repositório (se aplicável)

```bash
helm repo add atom-charts https://your-repo-url/
helm repo update
```

### 2. Instalar o chart

```bash
# Instalação básica
helm install atom ./atom

# Instalação com valores customizados
helm install atom ./atom -f values-production.yaml
```

### 3. Configurar valores personalizados

Crie um arquivo `values-production.yaml`:

```yaml
global:
  domain: "meu-dominio.com"
  imageRegistry: "registry.example.com"
  storageClass: "fast-ssd"

atom:
  replicaCount: 3
  env:
    elasticsearchHost: "elasticsearch.meu-dominio.com"
    elasticsearchPort: "9200"
    elasticsearchProtocol: "https"
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi

nginx:
  route:
    host: "atom-producao"

mysql:
  auth:
    rootPassword: "senha-super-secreta"
    password: "senha-atom-secreta"
  persistence:
    size: 100Gi
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
```

## Configuração do Elasticsearch

O Elasticsearch deve ser configurado externamente. Configure as variáveis no `values.yaml`:

```yaml
atom:
  env:
    elasticsearchHost: "seu-elasticsearch.exemplo.com"
    elasticsearchPort: "9200"
    elasticsearchProtocol: "https"
```

## Configuração do Domínio

Para usar o wildcard `*.k8s-npr.es.gov.br`, configure:

```yaml
global:
  domain: "k8s-npr.es.gov.br"

nginx:
  route:
    host: "atom"  # Resultará em atom.k8s-npr.es.gov.br
```

## Volumes Persistentes

O chart cria automaticamente os seguintes PVCs:

- `atom-mysql-pvc`: Dados do MySQL
- `atom-uploads-pvc`: Uploads da aplicação (compartilhado entre pods)
- `atom-cache-pvc`: Cache da aplicação (compartilhado entre pods)

## Segurança

O chart é configurado para ser compatível com OpenShift:

- Security Context Constraints (SCC) configurados
- Usuário não-root por padrão
- Contexto de segurança para pods e containers

## Monitoramento

Para verificar o status da aplicação:

```bash
# Status dos pods
kubectl get pods -l app.kubernetes.io/instance=atom

# Logs da aplicação
kubectl logs -l app.kubernetes.io/instance=atom,app.kubernetes.io/component=atom

# Logs do worker
kubectl logs -l app.kubernetes.io/instance=atom,app.kubernetes.io/component=worker

# Logs do nginx
kubectl logs -l app.kubernetes.io/instance=atom,app.kubernetes.io/component=nginx
```

## Escalabilidade

Para escalar os componentes:

```bash
# Escalar aplicação
helm upgrade atom ./atom --set atom.replicaCount=5

# Escalar workers
helm upgrade atom ./atom --set atomWorker.replicaCount=10
```

## Backup e Restore

### Backup do MySQL

```bash
kubectl exec -it deployment/atom-mysql -- mysqldump -u atom -p atom > backup-$(date +%Y%m%d).sql
```

### Backup dos uploads

```bash
kubectl exec -it deployment/atom -- tar -czf - /atom/src/uploads > uploads-backup-$(date +%Y%m%d).tar.gz
```

## Troubleshooting

### Problemas comuns

1. **Pods não conseguem se conectar ao Elasticsearch**
   - Verifique se o host do Elasticsearch está correto
   - Teste a conectividade de rede

2. **Erro de permissão nos volumes**
   - Verifique se o storage class suporta ReadWriteMany
   - Verifique as permissões do security context

3. **Aplicação não carrega**
   - Verifique se o job de inicialização do banco foi executado
   - Verifique se os assets foram compilados

### Comandos úteis

```bash
# Verificar eventos
kubectl get events --sort-by=.metadata.creationTimestamp

# Verificar configuração
kubectl get configmap atom-config -o yaml

# Verificar secrets
kubectl get secret atom-mysql-secret -o yaml

# Executar comando na aplicação
kubectl exec -it deployment/atom -- php symfony --version
```

## Parâmetros de Configuração

| Parâmetro | Descrição | Valor Padrão |
|-----------|-----------|--------------|
| `global.domain` | Domínio base para as routes | `k8s-npr.es.gov.br` |
| `global.imageRegistry` | Registry de imagens | `""` |
| `atom.replicaCount` | Número de réplicas da aplicação | `1` |
| `atom.image.repository` | Repositório da imagem | `atom` |
| `atom.image.tag` | Tag da imagem | `latest` |
| `atom.env.elasticsearchHost` | Host do Elasticsearch | `elasticsearch.external.example.com` |
| `atomWorker.replicaCount` | Número de workers | `2` |
| `nginx.route.host` | Hostname da route | `atom` |
| `mysql.auth.rootPassword` | Senha root do MySQL | `my-secret-pw` |
| `mysql.persistence.size` | Tamanho do volume MySQL | `10Gi` |

## Licença

Este helm chart está sob a mesma licença que a aplicação AtoM.

## Suporte

Para suporte, consulte:
- [Documentação oficial do AtoM](https://www.accesstomemory.org/)
- [Fórum da comunidade](https://groups.google.com/forum/#!forum/ica-atom-users)
- [GitHub do projeto](https://github.com/artefactual/atom)
