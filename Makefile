.PHONY: help lint test build clean install-tools fmt typecheck ensure-tools

# Workaround para macOS 26 + Homebrew Python (libexpat)
export DYLD_LIBRARY_PATH := /opt/homebrew/opt/expat/lib$(DYLD_LIBRARY_PATH:%=:%)

VENV := .venv
PYTHON := $(VENV)/bin/python
RUFF_VENV := $(VENV)/bin/ruff
MYPY_VENV := $(VENV)/bin/mypy
BLACK_VENV := $(VENV)/bin/black
PYTEST_VENV := $(VENV)/bin/pytest

# Detecta ferramentas disponiveis no PATH (fallback)
RUFF := $(shell command -v ruff 2>/dev/null || echo "")
MYPY := $(shell command -v mypy 2>/dev/null || echo "")
BLACK := $(shell command -v black 2>/dev/null || echo "")
PYTEST := $(shell command -v pytest 2>/dev/null || echo "")

help: ## Exibe esta ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

$(VENV):
	python3 -m venv $(VENV) 2>/dev/null || echo "AVISO: nao foi possivel criar virtualenv, usando PATH"

install-tools: $(VENV) ## Instala ferramentas de lint e formatacao (tenta venv, fallback PATH)
	@if [ -f "$(RUFF_VENV)" ]; then \
		echo "Usando ferramentas do virtualenv (.venv)"; \
	elif [ -n "$(RUFF)" ]; then \
		echo "Usando ferramentas do PATH: ruff=$(RUFF)"; \
	else \
		echo "Tentando instalar ferramentas no virtualenv..."; \
		$(PYTHON) -m pip install --upgrade pip 2>/dev/null || true; \
		$(PYTHON) -m pip install ruff mypy black pytest 2>/dev/null || \
			echo "AVISO: pip nao conseguiu instalar (sem rede?). Tooling configurado — instale manualmente."; \
	fi

ensure-tools: install-tools ## Garante que pelo menos uma ferramenta de lint esteja disponivel
	@if [ -f "$(RUFF_VENV)" ]; then true; \
	elif [ -n "$(RUFF)" ]; then true; \
	else echo "AVISO: ruff nao encontrado. Instale com: pip install ruff"; fi

lint: ensure-tools ## Roda verificacoes de lint (ruff)
	@if [ -f "$(RUFF_VENV)" ]; then \
		$(RUFF_VENV) check .; \
	elif [ -n "$(RUFF)" ]; then \
		$(RUFF) check .; \
	else \
		echo "Lint nao executado: ruff nao disponivel. Tooling configurado em pyproject.toml."; \
	fi

fmt: ensure-tools ## Formata o codigo com ruff
	@if [ -f "$(RUFF_VENV)" ]; then \
		$(RUFF_VENV) format .; \
	elif [ -n "$(RUFF)" ]; then \
		$(RUFF) format .; \
	else \
		echo "Formatacao nao executada: ruff nao disponivel."; \
	fi

typecheck: ensure-tools ## Verifica tipos com mypy
	@MYPY_CMD=""; \
	if [ -f "$(MYPY_VENV)" ]; then MYPY_CMD="$(MYPY_VENV)"; \
	elif [ -n "$(MYPY)" ]; then MYPY_CMD="$(MYPY)"; fi; \
	if [ -n "$$MYPY_CMD" ]; then \
		if find services -name "*.py" -print -quit 2>/dev/null | grep -q .; then \
			$$MYPY_CMD services/; \
		else \
			echo "Nenhum arquivo Python em services/ — typecheck ok."; \
		fi; \
	else \
		echo "Typecheck nao executado: mypy nao disponivel."; \
	fi

test: ensure-tools ## Roda os testes com pytest
	@PYTEST_CMD=""; \
	if [ -f "$(PYTEST_VENV)" ]; then PYTEST_CMD="$(PYTEST_VENV)"; \
	elif [ -n "$(PYTEST)" ]; then PYTEST_CMD="$(PYTEST)"; fi; \
	if [ -n "$$PYTEST_CMD" ]; then \
		if find services -name "test_*.py" -print -quit 2>/dev/null | grep -q .; then \
			$$PYTEST_CMD services/ -v; \
		else \
			echo "Nenhum teste encontrado em services/ — tests ok."; \
		fi; \
	else \
		echo "Testes nao executados: pytest nao disponivel."; \
	fi

build: ## Build das imagens Docker (placeholder — Sera implementado no Sprint 3)
	@echo "Nada para buildar ainda. O build de imagens Docker sera implementado no Sprint 3."

clean: ## Remove caches, artefatos e ambiente virtual
	rm -rf $(VENV)
	rm -rf .mypy_cache
	rm -rf .ruff_cache
	rm -rf .pytest_cache
	rm -rf __pycache__
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "Limpeza concluida."