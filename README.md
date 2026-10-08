# Cloud-Native Platform

Plataforma de microserviços demonstrando proficiência em Linux, Python, Docker, LocalStack + Terraform, Kubernetes, Istio e GitHub Actions.

## Serviços

| Serviço | Responsabilidade | Stack |
|---------|-----------------|-------|
| API Gateway | Roteamento, health check agregado, rate limiting | FastAPI + httpx |
| Products Service | CRUD de produtos | FastAPI + PostgreSQL |
| Orders Service | CRUD de pedidos | FastAPI + PostgreSQL |

## Stack

- **Runtime:** Python 3.12+, FastAPI, Uvicorn
- **Banco:** PostgreSQL 16
- **Containers:** Docker (multi-stage, non-root)
- **IaC:** Terraform + LocalStack
- **Orquestração:** Kubernetes (kind) + Istio
- **CI/CD:** GitHub Actions

## Começando

```bash
# Clonar o repositório
git clone <repo-url>
cd cloud-native-platform

# Instalar ferramentas de desenvolvimento
make install-tools

# Rodar lint
make lint

# Rodar testes
make test
```

## Documentação

- [Backlog do projeto](https://github.com/luissantos/llm-devops-studies/blob/main/backlog-projeto-cloud-native.md)
- [Roadmap Cloud Engineer → LLMOps 2026](https://github.com/luissantos/llm-devops-studies/blob/main/roadmap-cloud-llmops-2026.md)

## Licença

MIT