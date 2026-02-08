#!/bin/bash

# Script para construir a imagem Docker do Chatwoot
# Uso: ./scripts/build-docker.sh [tag] [registry]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações padrão
DEFAULT_TAG="latest"
DEFAULT_REGISTRY="ghcr.io/fazer-ai"
DOCKERFILE_PATH="docker/Dockerfile"

# Parâmetros
TAG=${1:-$DEFAULT_TAG}
REGISTRY=${2:-$DEFAULT_REGISTRY}
IMAGE_NAME="${REGISTRY}/chatwoot:${TAG}"

echo -e "${GREEN}🐳 Construindo imagem Docker do Chatwoot${NC}"
echo -e "${YELLOW}Tag: ${IMAGE_NAME}${NC}"
echo ""

# Verificar se o Dockerfile existe
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo -e "${RED}❌ Erro: Dockerfile não encontrado em ${DOCKERFILE_PATH}${NC}"
    exit 1
fi

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Erro: Docker não está rodando${NC}"
    exit 1
fi

# Build com BuildKit (mais rápido)
echo -e "${GREEN}📦 Iniciando build...${NC}"
DOCKER_BUILDKIT=1 docker build \
    -f "$DOCKERFILE_PATH" \
    --build-arg RAILS_ENV=production \
    --build-arg BUNDLE_WITHOUT="development:test" \
    -t "$IMAGE_NAME" \
    -t "${REGISTRY}/chatwoot:latest" \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build concluído com sucesso!${NC}"
    echo -e "${GREEN}📦 Imagem: ${IMAGE_NAME}${NC}"
    echo ""
    echo -e "${YELLOW}Para publicar a imagem, execute:${NC}"
    echo -e "  docker push ${IMAGE_NAME}"
    echo ""
    echo -e "${YELLOW}Para testar localmente:${NC}"
    echo -e "  docker run -p 3000:3000 ${IMAGE_NAME}"
else
    echo ""
    echo -e "${RED}❌ Erro durante o build${NC}"
    exit 1
fi
