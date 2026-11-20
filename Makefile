include src/.env

all: up

up:
	@test -n "$(VOLUMES_ROOT)" || (echo "VOLUMES_ROOT não está definido em src/.env"; exit 1)
	@mkdir -p "$(VOLUMES_ROOT)/postgres" "$(VOLUMES_ROOT)/static" \
	          "$(VOLUMES_ROOT)/media" "$(VOLUMES_ROOT)/certificates"
	@docker compose --env-file src/.env -f src/docker-compose.yml up -d --build

down:
	@docker compose --env-file src/.env -f src/docker-compose.yml down --remove-orphans

build: 
	@docker compose --env-file src/.env -f src/docker-compose.yml build


stop:
	@docker compose --env-file src/.env -f src/docker-compose.yml stop

logs:
	@docker compose --env-file src/.env -f src/docker-compose.yml logs

re: fclean all

clean:
	@docker compose --env-file src/.env -f src/docker-compose.yml down -v --rmi all --remove-orphans

fclean: clean
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "You must run this target as root"; \
		exit 1; \
	fi
	@rm -rf "$(VOLUMES_ROOT)"

.PHONY: all up down stop logs re clean fclean