.PHONY: help lint test build clean install-tools fmt

VENV := .venv
PYTHON := $(VENV)/bin/python
RUFF := $(VENV)/bin/ruff
MYPY := $(VENV)/bin/mypy
BLACK := $(VENV)/bin/black

help: ## Exibe esta ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

$(VENV):
	python3 -m venv $(VENV)
	$(PYTHON) -m pip install --upgrade pip

install-tools: $(VENV) ## Instala ferramentas de lint e formatação
	$(PYTHON) -m pip install ruff mypy black pytest

lint: install-tools ## Roda verificações de lint (ruff)
	$(RUFF) check .

fmt: install-tools ## Formata o código com ruff
	$(RUFF) format .

typecheck: install-tools ## Verifica tipos com mypy
	$(MYPY) services/

test: install-tools ## Roda os testes com pytest
	$(PYTHON) -m pytest services/ -v

build: ## Build das imagens Docker (placeholder — será implementado no Sprint 3)
	@echo "Nada para buildar ainda. O build de imagens Docker será implementado no Sprint 3."

clean: ## Remove caches, artefatos e ambiente virtual
	rm -rf $(VENV)
	rm -rf .mypy_cache
	rm -rf .ruff_cache
	rm -rf .pytest_cache
	rm -rf __pycache__
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "Limpeza concluída."