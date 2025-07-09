#!/bin/bash

# Script de instalação do AtoM no OpenShift
# Uso: ./install-atom.sh [environment] [namespace]

set -e

# Configurações padrão
ENVIRONMENT=${1:-"development"}
NAMESPACE=${2:-"atom"}
RELEASE_NAME="atom"
CHART_PATH="./atom"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funções de log
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se o helm está instalado
check_helm() {
    if ! command -v helm &> /dev/null; then
        log_error "Helm não está instalado"
        exit 1
    fi
    log_info "Helm encontrado: $(helm version --short)"
}

# Verificar se o oc está instalado
check_oc() {
    if ! command -v oc &> /dev/null; then
        log_error "OpenShift CLI (oc) não está instalado"
        exit 1
    fi
    log_info "OpenShift CLI encontrado: $(oc version --client)"
}

# Verificar conectividade com o cluster
check_cluster() {
    if ! oc auth can-i create deployment &> /dev/null; then
        log_error "Não foi possível conectar ao cluster OpenShift ou usuário não tem permissões"
        exit 1
    fi
    log_info "Conectado ao cluster: $(oc whoami --show-server)"
}

# Criar namespace se não existir
create_namespace() {
    if ! oc get namespace "$NAMESPACE" &> /dev/null; then
        log_info "Criando namespace: $NAMESPACE"
        oc create namespace "$NAMESPACE"
    else
        log_info "Namespace $NAMESPACE já existe"
    fi
}

# Validar templates do helm
validate_templates() {
    log_info "Validando templates do Helm..."
    helm template "$RELEASE_NAME" "$CHART_PATH" --namespace "$NAMESPACE" > /dev/null
    log_info "Templates validados com sucesso"
}

# Instalar ou atualizar o chart
install_chart() {
    local values_file=""
    
    case "$ENVIRONMENT" in
        "production")
            values_file="values-production.yaml"
            ;;
        "development")
            values_file="values.yaml"
            ;;
        *)
            log_error "Ambiente inválido: $ENVIRONMENT. Use 'development' ou 'production'"
            exit 1
            ;;
    esac
    
    if [ -f "$values_file" ]; then
        log_info "Usando arquivo de valores: $values_file"
        values_arg="-f $values_file"
    else
        log_warn "Arquivo de valores não encontrado: $values_file"
        values_arg=""
    fi
    
    # Verificar se o release já existe
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        log_info "Atualizando release existente: $RELEASE_NAME"
        helm upgrade "$RELEASE_NAME" "$CHART_PATH" --namespace "$NAMESPACE" $values_arg
    else
        log_info "Instalando novo release: $RELEASE_NAME"
        helm install "$RELEASE_NAME" "$CHART_PATH" --namespace "$NAMESPACE" $values_arg
    fi
}

# Aguardar pods ficarem prontos
wait_for_pods() {
    log_info "Aguardando pods ficarem prontos..."
    
    # Aguardar até 10 minutos
    local timeout=600
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if oc get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" | grep -q "Running"; then
            local ready=$(oc get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" --no-headers | awk '{print $2}' | grep -c "1/1" || echo "0")
            local total=$(oc get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" --no-headers | wc -l)
            
            if [ "$ready" -eq "$total" ] && [ "$total" -gt 0 ]; then
                log_info "Todos os pods estão prontos ($ready/$total)"
                return 0
            fi
            
            log_info "Aguardando pods ficarem prontos ($ready/$total)..."
        fi
        
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    log_error "Timeout aguardando pods ficarem prontos"
    return 1
}

# Verificar status da aplicação
check_application() {
    log_info "Verificando status da aplicação..."
    
    # Verificar route
    local route_host=$(oc get route -n "$NAMESPACE" -o jsonpath='{.items[0].spec.host}' 2>/dev/null || echo "")
    
    if [ -n "$route_host" ]; then
        log_info "Aplicação acessível em: https://$route_host"
        
        # Testar conectividade
        if curl -s -k "https://$route_host" > /dev/null; then
            log_info "Aplicação respondendo corretamente"
        else
            log_warn "Aplicação não está respondendo"
        fi
    else
        log_warn "Route não encontrada"
    fi
}

# Exibir informações úteis
show_info() {
    log_info "Informações da instalação:"
    echo "  - Release: $RELEASE_NAME"
    echo "  - Namespace: $NAMESPACE"
    echo "  - Ambiente: $ENVIRONMENT"
    echo ""
    
    log_info "Comandos úteis:"
    echo "  - Status dos pods: oc get pods -n $NAMESPACE"
    echo "  - Logs da aplicação: oc logs -n $NAMESPACE -l app.kubernetes.io/component=atom"
    echo "  - Logs do worker: oc logs -n $NAMESPACE -l app.kubernetes.io/component=worker"
    echo "  - Desinstalar: helm uninstall $RELEASE_NAME -n $NAMESPACE"
    echo ""
    
    # Exibir notas do helm
    helm get notes "$RELEASE_NAME" -n "$NAMESPACE" 2>/dev/null || true
}

# Função principal
main() {
    log_info "Iniciando instalação do AtoM..."
    log_info "Ambiente: $ENVIRONMENT"
    log_info "Namespace: $NAMESPACE"
    
    check_helm
    check_oc
    check_cluster
    create_namespace
    validate_templates
    install_chart
    wait_for_pods
    check_application
    show_info
    
    log_info "Instalação concluída com sucesso!"
}

# Executar função principal
main "$@"
