include src/.env

all: up

up:
	@test -n "$(VOLUMES_ROOT)" || (echo "VOLUMES_ROOT não está definido em src/.env"; exit 1)
	@mkdir -p "$(VOLUMES_ROOT)/postgres" "$(VOLUMES_ROOT)/static" \
	          "$(VOLUMES_ROOT)/media" "$(VOLUMES_ROOT)/certificates" "$(VOLUMES_BACKUPS)"
	@$(COMPOSE) up -d --build

down:
	@$(COMPOSE) down --remove-orphans

build: 
	@$(COMPOSE) build


stop:
	@$(COMPOSE) stop

logs:
	@$(COMPOSE) logs

re: fclean all

ps:
	@$(COMPOSE) ps

backup:
	@$(COMPOSE) exec backup script.sh now

backups:
	@$(COMPOSE) exec backup script.sh list

restore:
	@test -n "$(FILE)" || (echo "Uso: make restore FILE=db_AAAAMMDD_HHMMSS.dump   (ou FILE=latest)"; exit 1)
	@$(COMPOSE) stop backend
	@$(COMPOSE) exec backup script.sh restore $(FILE)
	@$(COMPOSE) start backend

clean:
	@$(COMPOSE) down -v --rmi all --remove-orphans

fclean: clean
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "You must run this target as root"; \
		exit 1; \
	fi
	@rm -rf "$(VOLUMES_ROOT)"
	
.PHONY: all up down stop logs re health backup backups restore clean fclean 