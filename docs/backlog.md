# Backlog — Projeto Integrador Cloud-Native

> Cada item do backlog é uma unidade independente de implementação, delegável a um agente separado.
> O judge (orquestrador) revisa cada entrega contra os critérios de aceitação antes de promover o item a `done`.

---

## Visão geral

Construir uma plataforma de microserviços que demonstre proficiência em Linux, Python, Docker, LocalStack + Terraform, Kubernetes, Istio e GitHub Actions. A aplicação de negócio é mantida simples de propósito — o foco é a infraestrutura e a operação.

### Serviços

| Serviço | Responsabilidade | Stack |
|---------|-----------------|-------|
| API Gateway | Roteamento, health check agregado, rate limiting básico | FastAPI + httpx |
| Products Service | CRUD de produtos (nome, preço, estoque) | FastAPI + PostgreSQL |
| Orders Service | CRUD de pedidos (cliente, itens, status) | FastAPI + PostgreSQL |

### Stack de infraestrutura

- **Runtime local:** Python 3.12+, FastAPI, Uvicorn
- **Banco:** PostgreSQL 16 (uma instância por serviço no K8s; compartilhada no Docker Compose)
- **Containers:** Docker (multi-stage, non-root)
- **Nuvem simulada:** LocalStack (S3, Secrets Manager, RDS simulado opcional)
- **IaC:** Terraform com módulos
- **Orquestração:** kind (Kubernetes in Docker)
- **Service Mesh:** Istio (Gateway, VirtualService, DestinationRule, mTLS, Kiali)
- **CI/CD:** GitHub Actions (build, test, lint, deploy)
- **Observabilidade:** logs estruturados (stdout/stderr), health checks, futura integração com Prometheus/Grafana

### Repositório

Monorepo em `Projetos/cloud-native-platform/` com a seguinte estrutura alvo:

```
cloud-native-platform/
├── services/
│   ├── gateway/
│   │   ├── app/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── products/
│   │   ├── app/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── orders/
│       ├── app/
│       ├── tests/
│       ├── Dockerfile
│       └── requirements.txt
├── docker/
│   └── docker-compose.yml
├── terraform/
│   ├── modules/
│   │   ├── networking/
│   │   ├── database/
│   │   └── storage/
│   ├── environments/
│   │   └── dev/
│   └── provider.tf
├── kubernetes/
│   ├── base/
│   │   ├── gateway/
│   │   ├── products/
│   │   └── orders/
│   └── overlays/
│       └── dev/
├── istio/
│   ├── gateway.yaml
│   ├── virtual-services.yaml
│   ├── destination-rules.yaml
│   └── peer-authentication.yaml
├── scripts/
│   ├── health-check.sh
│   ├── deploy-local.sh
│   └── diagnose.sh
├── .github/
│   └── workflows/
│       ├── build-test.yml
│       └── deploy.yml
├── docs/
│   ├── architecture.md
│   ├── adr/
│   └── runbook.md
└── README.md
```

---

## Backlog

### Sprint 0 — Fundação do repositório

#### B-00: Inicializar monorepo e tooling

- **Descrição:** criar a estrutura de diretórios do monorepo, inicializar git, configurar `.gitignore`, `.editorconfig`, `pyproject.toml` (ou `setup.cfg`) com black, flake8/ruff e mypy. Criar um `Makefile` com targets: `lint`, `test`, `build`, `clean`.
- **Dependências:** nenhuma.
- **Artefatos esperados:**
  - Estrutura de diretórios conforme a árvore acima (diretórios vazios são aceitáveis; placeholders com `.gitkeep`).
  - `.gitignore` cobrindo `__pycache__`, `.venv`, `.env`, `*.pyc`, `.terraform/`, `terraform.tfstate*`.
  - `Makefile` com targets `lint`, `test`, `build`, `clean`.
  - `README.md` inicial com título, descrição de uma frase e link para o backlog.
- **Critérios de aceitação:**
  - `make lint` não quebra (mesmo sem código — apenas tooling instalável/configurável).
  - `git init` executado; primeiro commit com a estrutura inicial.

---

### Sprint 1 — Serviços Python


#### B-01: Products Service

- **Descrição:** implementar o serviço de produtos com FastAPI. Endpoints: `POST /products`, `GET /products`, `GET /products/{id}`, `PUT /products/{id}`, `DELETE /products/{id}`. Modelo: `id` (UUID), `name` (str), `price` (float), `stock` (int). Persistência em PostgreSQL via SQLAlchemy (async). Validação com Pydantic. Tratamento de erros (404, 422, 500) e logging estruturado.
- **Dependências:** B-00 (estrutura).
- **Artefatos esperados:**
  - `services/products/app/main.py`, `models.py`, `schemas.py`, `database.py`.
  - `services/products/tests/test_products.py` com pelo menos 6 testes (CRUD + erro 404 + validação).
  - `services/products/requirements.txt`.
- **Critérios de aceitação:**
  - Testes passam com `pytest` (banco SQLite em memória nos testes).
  - Endpoints respondem corretamente via `curl` com o servidor rodando localmente.
  - Logs aparecem em stdout no formato `timestamp level message`.

#### B-02: Orders Service

- **Descrição:** implementar o serviço de pedidos com FastAPI. Endpoints: `POST /orders`, `GET /orders`, `GET /orders/{id}`, `PATCH /orders/{id}/status`. Modelo: `id` (UUID), `customer_name` (str), `items` (JSON), `status` (enum: pending, confirmed, shipped, delivered), `created_at`. Persistência em PostgreSQL via SQLAlchemy. Validação com Pydantic. Tratamento de erros e logging.
- **Dependências:** B-00.
- **Artefatos esperados:**
  - `services/orders/app/main.py`, `models.py`, `schemas.py`, `database.py`.
  - `services/orders/tests/test_orders.py` com pelo menos 6 testes.
  - `services/orders/requirements.txt`.
- **Critérios de aceitação:**
  - Testes passam com `pytest`.
  - Endpoints respondem corretamente.
  - Logs estruturados.

#### B-03: API Gateway

- **Descrição:** implementar o gateway com FastAPI. Endpoints: `GET /health` (agrega health dos serviços downstream), `GET /products` (proxy para Products Service), `GET /orders` (proxy para Orders Service). Usar `httpx` para chamadas downstream. Timeout de 5s, retry 1x em caso de falha transitória. Rate limiting básico (slowapi ou manual — 10 req/s por IP).
- **Dependências:** B-01, B-02 (precisa das interfaces dos serviços).
- **Artefatos esperados:**
  - `services/gateway/app/main.py`, `proxy.py`, `rate_limiter.py`.
  - `services/gateway/tests/test_gateway.py` com testes mockando os serviços downstream.
  - `services/gateway/requirements.txt`.
- **Critérios de aceitação:**
  - `GET /health` retorna 200 quando ambos os serviços respondem; 503 quando algum falha.
  - Proxy funciona com timeout e retry configuráveis via env.
  - Rate limiting rejeita com 429 após exceder o limite.

---

### Sprint 2 — Linux & Automação

#### B-04: Scripts de automação e diagnóstico

- **Descrição:** criar scripts bash para health check agregado, deploy local (subir todos os serviços com Uvicorn e PostgreSQL), e diagnóstico (coletar logs, status de processos, uso de disco, portas abertas). Criar arquivos `systemd` unit para cada serviço como referência (não precisam ser instalados — são ilustrativos do conhecimento de systemd).
- **Dependências:** B-01, B-02, B-03 (serviços existentes).
- **Artefatos esperados:**
  - `scripts/health-check.sh` — chama os endpoints de health de cada serviço e reporta status agregado com código de saída.
  - `scripts/deploy-local.sh` — sobe PostgreSQL (via Docker ou brew), instala dependências e inicia os 3 serviços.
  - `scripts/diagnose.sh` — coleta: processos Python rodando, portas em uso (`ss -tlnp`), espaço em disco (`df -h`), últimos 50 logs de cada serviço.
  - `scripts/systemd/` — arquivos `.service` para gateway, products e orders.
- **Critérios de aceitação:**
  - `health-check.sh` retorna 0 quando todos saudáveis, != 0 caso contrário.
  - `diagnose.sh` roda sem privilégios de root e produz saída legível.
  - Arquivos systemd seguem boas práticas (`User=`, `WorkingDirectory=`, `ExecStart=`, `Restart=`, `StandardOutput=journal`).

---

### Sprint 3 — Docker

> Os dois itens podem rodar em paralelo.

#### B-05: Dockerfiles

- **Descrição:** criar Dockerfiles multi-stage para cada serviço. Estágio de build (instala dependências) e estágio de runtime (imagem enxuta, non-root). Usar `python:3.12-slim` como base. Configurar health check via `HEALTHCHECK` no Dockerfile.
- **Dependências:** B-01, B-02, B-03.
- **Artefatos esperados:**
  - `services/gateway/Dockerfile`
  - `services/products/Dockerfile`
  - `services/orders/Dockerfile`
- **Critérios de aceitação:**
  - Build sem erros.
  - Container roda como usuário não-root (`whoami` != root).
  - `HEALTHCHECK` responde corretamente.
  - Imagem final < 300 MB.

#### B-06: Docker Compose

- **Descrição:** criar `docker-compose.yml` com os 3 serviços + PostgreSQL 16. Configurar redes (bridge), volumes para persistência do banco, variáveis de ambiente (banco, portas) e health checks via `depends_on` com condição `service_healthy`. Serviços acessam o banco via nome do serviço (DNS interno do Compose). Secrets simulados via arquivo `.env` (não commitado — criar `.env.example`).
- **Dependências:** B-05.
- **Artefatos esperados:**
  - `docker/docker-compose.yml`
  - `docker/.env.example`
- **Critérios de aceitação:**
  - `docker compose up` sobe todos os serviços.
  - Gateway acessível em `http://localhost:8000/health`.
  - `docker compose down -v` remove volumes.

---

### Sprint 4 — Infraestrutura como Código

> Os dois itens podem rodar em paralelo.

#### B-07: Terraform — Networking e Provider

- **Descrição:** configurar provider AWS apontando para LocalStack (`endpoints`). Criar módulo de networking: VPC, sub-redes públicas/privadas, Internet Gateway, NAT Gateway, route tables. Usar variáveis e outputs. State local (depois migrar para remoto). Documentar como iniciar LocalStack e aplicar o Terraform.
- **Dependências:** nenhuma de código, mas pressupõe LocalStack instalado.
- **Artefatos esperados:**
  - `terraform/provider.tf`
  - `terraform/modules/networking/` com `main.tf`, `variables.tf`, `outputs.tf`
  - `terraform/environments/dev/main.tf` (usa o módulo)
  - `terraform/environments/dev/terraform.tfvars.example`
- **Critérios de aceitação:**
  - `terraform validate` passa.
  - `terraform plan` contra LocalStack roda sem erros.
  - Outputs expõem VPC ID, subnet IDs.

#### B-08: Terraform — Aplicação

- **Descrição:** criar módulos para S3 (armazenamento de arquivos estáticos) e Secrets Manager (credenciais de banco). Módulos recebem variáveis do ambiente dev. Referenciar outputs do módulo de networking (VPC, subnets).
- **Dependências:** B-07.
- **Artefatos esperados:**
  - `terraform/modules/storage/`
  - `terraform/modules/secrets/`
  - Atualizar `environments/dev/main.tf` para usar ambos os módulos.
- **Critérios de aceitação:**
  - `terraform plan` contra LocalStack cria bucket S3 e secret.
  - Secrets não expostos em outputs (marcados como `sensitive = true`).

---

### Sprint 5 — Kubernetes

> Os dois itens podem rodar em paralelo.

#### B-09: Manifests base

- **Descrição:** criar manifests Kubernetes para os 3 serviços + PostgreSQL. Usar Deployments, Services (ClusterIP), ConfigMaps (variáveis não sensíveis). Estrutura com `base/` e `overlays/dev/` usando kustomize. Ingress para expor o gateway.
- **Dependências:** B-05 (imagens Docker).
- **Artefatos esperados:**
  - `kubernetes/base/gateway/deployment.yaml`, `service.yaml`
  - `kubernetes/base/products/deployment.yaml`, `service.yaml`
  - `kubernetes/base/orders/deployment.yaml`, `service.yaml`
  - `kubernetes/base/postgres/` (Deployment + Service)
  - `kubernetes/base/kustomization.yaml`
  - `kubernetes/overlays/dev/kustomization.yaml`
  - `kubernetes/overlays/dev/ingress.yaml`
- **Critérios de aceitação:**
  - `kubectl apply -k kubernetes/overlays/dev` sobe todos os recursos no kind.
  - `kubectl get pods` mostra todos Running.
  - Gateway acessível via Ingress.

#### B-10: Secrets, probes e resource limits

- **Descrição:** adicionar Secrets (credenciais de banco), liveness/readiness probes em todos os Deployments, resource requests/limits, e HPA para os serviços (min 1, max 3, CPU 70%). Configurar `securityContext` para non-root.
- **Dependências:** B-09.
- **Artefatos esperados:**
  - Atualização dos deployments com probes, resources, securityContext.
  - `kubernetes/base/secrets.yaml` (ou referência a sealed secrets).
  - `kubernetes/base/hpa/` com HPAs.
- **Critérios de aceitação:**
  - Probes respondem: `kubectl describe pod` mostra `Liveness: http-get...` e `Readiness: http-get...`.
  - Pods não rodam como root (`kubectl get pod -o jsonpath='{.spec.containers[*].securityContext}'`).
  - HPA criado e visível em `kubectl get hpa`.

---

### Sprint 6 — Istio

#### B-11: Gateway e VirtualServices

- **Descrição:** instalar Istio no cluster kind (perfil `demo`). Criar Istio Gateway para entrada de tráfego HTTP. Criar VirtualServices que roteiam para os serviços internos (gateway, products, orders). Expor o Istio Gateway via NodePort ou port-forward. Validar roteamento.
- **Dependências:** B-09 (serviços no K8s).
- **Artefatos esperados:**
  - `istio/gateway.yaml`
  - `istio/virtual-services.yaml`
  - Script ou instruções em `scripts/setup-istio.sh`
- **Critérios de aceitação:**
  - `istioctl analyze` não reporta erros.
  - Requisições via Istio Gateway chegam aos serviços corretos.
  - Roteamento por path: `/products` → Products Service, `/orders` → Orders Service.

#### B-12: DestinationRules, mTLS e Kiali

- **Descrição:** adicionar DestinationRules com políticas de load balancing (LEAST_REQUEST), circuit breaking (maxConnections: 100, http1MaxPendingRequests: 50) e retries (2 tentativas, timeout 2s). Ativar mTLS estrito via PeerAuthentication. Expor Kiali para visualização da malha.
- **Dependências:** B-11.
- **Artefatos esperados:**
  - `istio/destination-rules.yaml`
  - `istio/peer-authentication.yaml`
  - Atualização de `scripts/setup-istio.sh` com Kiali.
- **Critérios de aceitação:**
  - `istioctl proxy-config cluster` mostra circuit breakers configurados.
  - mTLS ativo: `istioctl authn tls-check` mostra `STATUS OK` e `SERVER mTLS`.
  - Kiali acessível e mostra o grafo de serviços.

---

### Sprint 7 — CI/CD

> Os dois itens podem rodar em paralelo.

#### B-13: Workflow de build e teste

- **Descrição:** criar GitHub Actions workflow que dispara em push e PR para `main`. Jobs: lint (ruff), test (pytest para cada serviço com matriz), build de imagens Docker (sem push — só validação). Usar cache de dependências Python.
- **Dependências:** B-01 a B-03 (código), B-05 (Dockerfiles).
- **Artefatos esperados:**
  - `.github/workflows/build-test.yml`
- **Critérios de aceitação:**
  - Workflow aparece na aba Actions do GitHub.
  - Push dispara: lint, test (3 serviços em paralelo), build.
  - Falha em qualquer job impede merge (branch protection opcional).

#### B-14: Workflow de deploy + segurança

- **Descrição:** workflow de deploy manual (`workflow_dispatch`) que aplica Terraform (plan + apply com approval), faz deploy no kind (cria cluster se não existir, aplica kustomize, aplica Istio), e roda smoke tests. Adicionar steps de segurança: scan de dependências (`pip-audit`), scan de imagens Docker (`trivy` ou `docker scout`).
- **Dependências:** B-07, B-08 (Terraform), B-09, B-10 (K8s), B-11, B-12 (Istio).
- **Artefatos esperados:**
  - `.github/workflows/deploy.yml`
  - `scripts/smoke-test.sh` (valida endpoints principais após deploy).
- **Critérios de aceitação:**
  - Workflow executável manualmente.
  - Scan de dependências reporta vulnerabilidades (não bloqueia se houver CVEs de baixa).
  - Smoke tests passam no final do pipeline.

---

### Sprint 8 — Documentação

#### B-15: README, ADRs e diagrama de arquitetura

- **Descrição:** produzir documentação completa do projeto. README com instruções de setup, deploy local e no K8s, arquitetura e decisões. Pelo menos 3 ADRs (Architecture Decision Records): escolha de FastAPI, escolha de PostgreSQL, escolha de Istio. Diagrama de arquitetura em ASCII ou Mermaid (embedado no markdown). Runbook com procedimentos de diagnóstico e recuperação para 3 cenários de falha.
- **Dependências:** todas as anteriores.
- **Artefatos esperados:**
  - `README.md` completo.
  - `docs/architecture.md` com diagrama.
  - `docs/adr/001-fastapi.md`, `docs/adr/002-postgresql.md`, `docs/adr/003-istio.md`.
  - `docs/runbook.md`.
- **Critérios de aceitação:**
  - README permite que uma pessoa clone o repo e execute o projeto localmente em até 30 minutos.
  - Diagrama de arquitetura mostra todos os componentes e fluxos.
  - ADRs seguem template: contexto, decisão, alternativas consideradas, consequências.
  - Runbook cobre: serviço fora do ar, banco inacessível, latência alta.

---

## Instruções para o Judge

1. Para cada item, delegar a um agente com o prompt descrevendo o item e seus critérios de aceitação.
2. Após a entrega, verificar:
   - Todos os artefatos esperados existem.
   - Todos os critérios de aceitação são satisfeitos.
   - Código compila/roda sem intervenção manual.
3. Se aprovado, marcar o item como `done` e liberar os itens dependentes.
4. Se reprovado, devolver ao agente com feedback específico e reavaliar.
5. Ao final de cada sprint, rodar uma verificação de integração (todos os serviços sobem juntos).

---

## Sequenciamento sugerido

```
B-00
 ├── B-01 ──┬── B-03
 ├── B-02 ──┘
 └── B-04
       ├── B-05 ── B-06
       ├── B-07 ── B-08
       ├── B-09 ── B-10 ── B-11 ── B-12
       └── B-13, B-14 (após builds)
             └── B-15
```

Itens no mesmo nível de indentação rodam em paralelo. Setas indicam dependências de dados (não apenas de existência de arquivo — por exemplo, B-03 precisa das interfaces dos serviços para construir o proxy corretamente).

---

*Backlog versão 1.0 — sujeito a refinamento pelo judge ao longo da execução.*
