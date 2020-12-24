ifeq ($(OS),Windows_NT)
    SHELL := pwsh.exe
else
   SHELL := pwsh
endif
.SHELLFLAGS := -NoProfile -Command 

CORE_SERVICES := dns certgetter ca_reverseproxy ca
BACKUP := registry_backup
REGISTRY := registry registryui registryui_reverseproxy registry_mirror
MONITORING := grafana prometheus dhcp_exporter
PROXY := squidproxy squidmetrics
ALL_SERVICES := ${CORE_SERVICES} ${MONITORING} ${PROXY} ${BACKUP}

COMPOSE_ALL_FILES := -f docker-compose.yml -f docker-compose.registry.yml -f docker-compose.monitoring.yml -f docker-compose.proxy.yml
COMPOSE_MONITORING_FILES := -f docker-compose.monitoring.yml
COMPOSE_PROXY_FILES := -f docker-compose.proxy.yml
COMPOSE_REGISTRY_FILES := -f docker-compose.registry.yml
CORE_SERVICES_FILES := -f docker-compose.yml
# --------------------------

# load .env so that Docker Swarm Commands has .env values too. (https://github.com/moby/moby/issues/29133)
include .env
export

all: down core registry monitoring
setup:
	@./Configure.ps1

build: setup
	@docker-compose ${COMPOSE_ALL_FILES} up -d --build ${ALL_SERVICES}

monitoring:
	@docker-compose ${COMPOSE_MONITORING_FILES} up -d --build ${MONITORING}

proxy:
	@docker-compose ${COMPOSE_PROXY_FILES} up -d --build ${PROXY}

registry: core
	@docker-compose ${COMPOSE_REGISTRY_FILES} up -d --build ${REGISTRY}

core:
	@docker-compose ${CORE_SERVICES_FILES} up -d --build ${CORE_SERVICES}

down:		
	@docker-compose ${COMPOSE_ALL_FILES} down

stop:		
	@docker-compose ${COMPOSE_ALL_FILES} stop ${ALL_SERVICES}
	
restart:	
	@docker-compose ${COMPOSE_ALL_FILES} restart ${ALL_SERVICES}

rm:				
	@docker-compose $(COMPOSE_ALL_FILES) rm -f ${ALL_SERVICES}

logs:	
	@docker-compose $(COMPOSE_ALL_FILES) logs --follow --tail=1000 ${ALL_SERVICES}

images:		
	@docker-compose $(COMPOSE_ALL_FILES) images ${ALL_SERVICES}

clean: ## Remove all Containers and Delete Volume Data
	@docker-compose ${COMPOSE_ALL_FILES} down -v

.PHONY: test
test:
	@$return = Start-MyProcess "docker-compose" "--project-name test ${COMPOSE_ALL_FILES} up -d"; if ([string]::IsNullOrEmpty($return.stderr) -or $return.stdoutt -like '*Authorization*'){Write-Error "There was an error" -ErrorAction Stop}
	@Invoke-Pester "./tests"-Verbose
	@docker-compose --project-name test $(COMPOSE_ALL_FILES) down -v 1>$null
	@docker-compose --project-name test $(COMPOSE_ALL_FILES) rm -f 1>$null