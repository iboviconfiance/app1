# KLAS+ - Commandes Docker simplifiées

.PHONY: up down build logs restart clean

up:
	docker compose up --build

up-d:
	docker compose up --build -d

down:
	docker compose down

build:
	docker compose build --no-cache

logs:
	docker compose logs -f

restart:
	docker compose restart

clean:
	docker compose down -v --remove-orphans

ps:
	docker compose ps
