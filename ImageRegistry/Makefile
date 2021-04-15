ifeq ($(OS),Windows_NT)
    SHELL := pwsh.exe
else
   SHELL := pwsh
endif
.SHELLFLAGS := -NoProfile -Command 

CORE_SERVICES := dns certgetter ca ingress
BACKUP := registry_backup
REGISTRY := registry registryui registry_mirror
MONITORING := grafana prometheus nagios nagios_mysql prometheus_blackbox_exporter
ELASTIC := es01 es02 es03 kib01 logstash docker_logbeat
PROXY := squidproxy squidmetrics
MISC := youtube_dl scratch diagrams.net vscode calibre
NEXTCLOUD := app db
ALL_SERVICES := ${CORE_SERVICES} ${MONITORING} ${PROXY} ${BACKUP} ${MISC} ${ELASTIC} ${NEXTCLOUD}

COMPOSE_ALL_FILES := -f docker-compose.yml ${COMPOSE_REGISTRY_FILES} ${COMPOSE_MONITORING_FILES} ${COMPOSE_PROXY_FILES} ${COMPOSE_MISC_FILES} ${COMPOSE_NEXTCLOUD_FILES} ${COMPOSE_ELASTIC_FILES}
COMPOSE_MONITORING_FILES := -f docker-compose.monitoring.yml
COMPOSE_PROXY_FILES := -f docker-compose.proxy.yml
COMPOSE_REGISTRY_FILES := -f docker-compose.registry.yml
COMPOSE_MISC_FILES := -f docker-compose.misc.yml
CORE_SERVICES_FILES := -f docker-compose.yml
COMPOSE_ELASTIC_FILES := -f docker-compose.elastic.yml
COMPOSE_NEXTCLOUD_FILES := -f docker-compose.nextcloud.yml
# --------------------------


all: down core registry monitoring elastic
setup:
	@./Configure.ps1

build:
	@docker-compose ${COMPOSE_ALL_FILES} up -d --build ${ALL_SERVICES}

monitoring:
	@docker-compose ${COMPOSE_MONITORING_FILES} up -d --build ${MONITORING}

proxy:
	@docker-compose ${COMPOSE_PROXY_FILES} up -d --build ${PROXY}

nextcloud:
	@docker-compose ${COMPOSE_NEXTCLOUD_FILES} up -d --build ${NEXTCLOUD}

gitlab:
	@docker-compose ${COMPOSE_NEXTCLOUD_FILES} up -d --build ${NEXTCLOUD}

registry: core
	@docker-compose ${COMPOSE_REGISTRY_FILES} up -d --build ${REGISTRY}

core:
	@docker-compose ${CORE_SERVICES_FILES} up -d --build ${CORE_SERVICES}
elastic:
	@docker-compose ${ELASTIC_SERVICES_FILES} up -d --build ${ELASTIC}
misc:
	@docker-compose ${COMPOSE_MISC_FILES} up -d --build ${MISC_SERVICES}

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
	-docker-compose ${COMPOSE_ALL_FILES} down -v

.PHONY: test
test:
	@$return = Start-MyProcess "docker-compose" "--project-name test ${COMPOSE_ALL_FILES} up -d"; if ([string]::IsNullOrEmpty($return.stderr) -or $return.stdoutt -like '*Authorization*'){Write-Error "There was an error" -ErrorAction Stop}
	@Invoke-Pester "./tests"-Verbose
	@docker-compose --project-name test $(COMPOSE_ALL_FILES) down -v 1>$null
	@docker-compose --project-name test $(COMPOSE_ALL_FILES) rm -f 1>$null