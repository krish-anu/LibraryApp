IMAGE ?= libraryapp-server
CONTAINER ?= libraryapp-server
ENV_FILE ?= .env
HOST_PORT ?= 8000
CONTAINER_PORT ?= 8000

.PHONY: build run run-detached stop logs remove-all-containers dev migrate

build:
	docker build -t $(IMAGE) .

run: build
	docker run --rm --name $(CONTAINER) --env-file $(ENV_FILE) -p $(HOST_PORT):$(CONTAINER_PORT) $(IMAGE)

run-detached: build
	docker run -d --name $(CONTAINER) --env-file $(ENV_FILE) -p $(HOST_PORT):$(CONTAINER_PORT) $(IMAGE)

stop:
	docker stop $(CONTAINER)

logs:
	docker logs -f $(CONTAINER)

remove-all-containers:
	@ids=$$(docker ps -aq); \
	if [ -n "$$ids" ]; then \
		docker rm -f $$ids; \
	else \
		echo "No Docker containers found."; \
	fi

dev:
	uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

migrate:
	python scripts/migrate_startup_schema.py