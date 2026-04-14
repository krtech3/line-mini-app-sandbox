.PHONY: help
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

.PHONY: dev
dev: preflight
	docker compose up --build db pgadmin app

.PHONY: debug
debug: preflight
	docker compose up --build db pgadmin app-debug

.PHONY: preflight
preflight: check-docker

.PHONY: check-docker
check-docker:
	@docker info >/dev/null 2>&1 || (echo "ERROR: Docker が起動していません。Docker Desktop を起動してください。" >&2; exit 1)

.PHONY: up
up: preflight
	docker compose up -d --build db pgadmin app

.PHONY: down
down:
	docker compose down

.PHONY: restart
restart: preflight
	docker compose down
	docker compose up -d --build db pgadmin app

.PHONY: logs
logs:
	docker compose logs -f

.PHONY: ps
ps:
	docker compose ps

.PHONY: db-sh
db-sh:
	docker compose exec db sh

.PHONY: db-login
db-login:
	@docker compose exec db sh -c 'PGPASSWORD="$$POSTGRES_PASSWORD" psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

.PHONY: db-logs
db-logs:
	docker compose logs -f db

.PHONY: pgadmin-logs
pgadmin-logs:
	docker compose logs -f pgadmin

.PHONY: app-logs
app-logs:
	docker compose logs -f app

.PHONY: debug-logs
debug-logs:
	docker compose logs -f app-debug

.PHONY: rebuild
rebuild:
	docker compose build --no-cache

.PHONY: clean
clean:
	docker compose down -v
