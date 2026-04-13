.PHONY: help dev debug app-logs preflight check-docker up down restart logs ps db-sh db-login pgadmin-logs db-logs clean rebuild

help:
	@echo "Available targets:"
	@echo "  make up           - Build and start services"
	@echo "  make dev          - Start app with hot reload in container"
	@echo "  make debug        - Start app in Docker with Delve"
	@echo "  make down         - Stop services"
	@echo "  make restart      - Restart services"
	@echo "  make logs         - Show all logs"
	@echo "  make ps           - Show container status"
	@echo "  make app-logs     - Show app logs"
	@echo "  make debug-logs   - Show app-debug logs"
	@echo "  make db-sh     - Enter db container shell"
	@echo "  make db-login     - Login to PostgreSQL"
	@echo "  make db-logs      - Show db logs"
	@echo "  make pgadmin-logs - Show pgadmin logs"
	@echo "  make rebuild      - Rebuild images"
	@echo "  make clean        - Stop and remove containers, networks, volumes"

dev: preflight
	docker compose up --build db pgadmin app

debug: preflight
	docker compose up --build db pgadmin app-debug

preflight: check-docker

check-docker:
	@docker info >/dev/null 2>&1 || (echo "ERROR: Docker が起動していません。Docker Desktop を起動してください。" >&2; exit 1)

up: preflight
	docker compose up -d --build db pgadmin app

down:
	docker compose down

restart: preflight
	docker compose down
	docker compose up -d --build db pgadmin app

logs:
	docker compose logs -f

ps:
	docker compose ps

db-sh:
	docker compose exec db sh

db-login:
	@docker compose exec db sh -c 'PGPASSWORD="$$POSTGRES_PASSWORD" psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

db-logs:
	docker compose logs -f db

pgadmin-logs:
	docker compose logs -f pgadmin

app-logs:
	docker compose logs -f app

debug-logs:
	docker compose logs -f app-debug

rebuild:
	docker compose build --no-cache

clean:
	docker compose down -v
