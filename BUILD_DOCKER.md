# Como Criar a Imagem Docker do Chatwoot

Este guia explica como construir a imagem Docker do Chatwoot a partir do código fonte.

## Pré-requisitos

- Docker instalado
- Git (para clonar o repositório, se necessário)

## Método 1: Build Simples (Recomendado)

### Construir a imagem

```bash
# Na raiz do projeto
docker build -f docker/Dockerfile -t chatwoot:latest .
```

### Construir com tag personalizada

```bash
docker build -f docker/Dockerfile -t seu-registro/chatwoot:v1.0.0 .
```

### Construir para produção (otimizado)

```bash
docker build \
  -f docker/Dockerfile \
  --build-arg RAILS_ENV=production \
  --build-arg BUNDLE_WITHOUT="development:test" \
  -t chatwoot:production \
  .
```

## Método 2: Build com Variáveis de Ambiente

### Build com configurações customizadas

```bash
docker build \
  -f docker/Dockerfile \
  --build-arg RAILS_ENV=production \
  --build-arg NODE_VERSION=24.13.0 \
  --build-arg PNPM_VERSION=10.2.0 \
  --build-arg BUNDLE_WITHOUT="development:test" \
  -t chatwoot:custom \
  .
```

## Método 3: Build Multi-stage (Otimizado)

O Dockerfile já usa multi-stage build por padrão, mas você pode otimizar ainda mais:

```bash
# Build apenas o stage de produção
docker build \
  -f docker/Dockerfile \
  --target pre-builder \
  -t chatwoot:builder \
  .

# Build final
docker build \
  -f docker/Dockerfile \
  -t chatwoot:latest \
  .
```

## Publicar a Imagem

### Para Docker Hub

```bash
# Fazer login
docker login

# Tag da imagem
docker tag chatwoot:latest seu-usuario/chatwoot:latest

# Push
docker push seu-usuario/chatwoot:latest
```

### Para GitHub Container Registry (ghcr.io)

```bash
# Fazer login
echo $GITHUB_TOKEN | docker login ghcr.io -u SEU_USUARIO --password-stdin

# Tag da imagem
docker tag chatwoot:latest ghcr.io/seu-usuario/chatwoot:latest

# Push
docker push ghcr.io/seu-usuario/chatwoot:latest
```

### Para o registro usado no projeto (ghcr.io/fazer-ai)

```bash
# Fazer login no GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u fazer-ai --password-stdin

# Tag da imagem
docker tag chatwoot:latest ghcr.io/fazer-ai/chatwoot:latest

# Push
docker push ghcr.io/fazer-ai/chatwoot:latest
```

## Build Arguments Disponíveis

O Dockerfile aceita os seguintes argumentos de build:

- `RAILS_ENV`: Ambiente Rails (padrão: `production`)
- `BUNDLE_WITHOUT`: Gems a excluir (padrão: `development:test`)
- `NODE_VERSION`: Versão do Node.js (padrão: `24.13.0`)
- `PNPM_VERSION`: Versão do pnpm (padrão: `10.2.0`)
- `RAILS_SERVE_STATIC_FILES`: Servir arquivos estáticos (padrão: `true`)
- `BUNDLE_FORCE_RUBY_PLATFORM`: Forçar plataforma Ruby (padrão: `1`)

## Exemplo Completo

```bash
# 1. Construir a imagem
docker build \
  -f docker/Dockerfile \
  --build-arg RAILS_ENV=production \
  --build-arg NODE_VERSION=24.13.0 \
  --build-arg PNPM_VERSION=10.2.0 \
  -t ghcr.io/fazer-ai/chatwoot:latest \
  .

# 2. Testar localmente (opcional)
docker run -p 3000:3000 ghcr.io/fazer-ai/chatwoot:latest

# 3. Publicar
docker push ghcr.io/fazer-ai/chatwoot:latest
```

## Verificar a Imagem

```bash
# Listar imagens
docker images | grep chatwoot

# Inspecionar a imagem
docker inspect chatwoot:latest

# Ver histórico de layers
docker history chatwoot:latest
```

## Dicas de Otimização

### 1. Usar BuildKit (mais rápido)

```bash
DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile -t chatwoot:latest .
```

### 2. Cache de layers

O Dockerfile já está otimizado para cache, mas você pode forçar rebuild:

```bash
# Sem cache
docker build --no-cache -f docker/Dockerfile -t chatwoot:latest .

# Com cache específico
docker build --cache-from chatwoot:previous -f docker/Dockerfile -t chatwoot:latest .
```

### 3. Build paralelo

```bash
# Usar múltiplos workers (se disponível)
docker buildx build --platform linux/amd64,linux/arm64 -f docker/Dockerfile -t chatwoot:latest .
```

## Troubleshooting

### Erro: "Cannot find Dockerfile"

Certifique-se de estar na raiz do projeto e use o caminho correto:

```bash
docker build -f docker/Dockerfile -t chatwoot:latest .
```

### Erro: "Out of memory"

Aumente a memória disponível para Docker ou use:

```bash
docker build --memory=4g -f docker/Dockerfile -t chatwoot:latest .
```

### Build muito lento

Use BuildKit e cache:

```bash
DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile -t chatwoot:latest .
```

## Usar a Imagem Construída

Após construir, você pode usar no `docker-compose.coolify.yaml`:

```yaml
services:
  rails:
    image: 'ghcr.io/fazer-ai/chatwoot:latest'  # ou sua tag
    # ... resto da configuração
```

Ou executar diretamente:

```bash
docker run -p 3000:3000 \
  -e RAILS_ENV=production \
  -e POSTGRES_HOST=postgres \
  -e REDIS_URL=redis://redis:6379 \
  chatwoot:latest
```
