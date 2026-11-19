include src/.env

all: up

up:
	@test -n "$(VOLUMES_ROOT)" || (echo "VOLUMES_ROOT não está definido em src/.env"; exit 1)
	@mkdir -p "$(VOLUMES_ROOT)/postgres"
	@docker compose --env-file src/.env -f src/docker-compose.yml up -d --build

down:
	@docker compose --env-file src/.env -f src/docker-compose.yml down --remove-orphans

stop:
	@docker compose --env-file src/.env -f src/docker-compose.yml stop

logs:
	@docker compose --env-file src/.env -f src/docker-compose.yml logs

re: down up

clean:
	@docker compose --env-file src/.env -f src/docker-compose.yml down -v --rmi all --remove-orphans

fclean: clean
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "You must run this target as root"; \
		exit 1; \
	fi
	@rm -rf "$(VOLUMES_ROOT)"

.PHONY: all up down stop logs re clean fclean