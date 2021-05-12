ifeq ($(OS),Windows_NT)
    SHELL := pwsh.exe
else
   SHELL := pwsh
endif
.SHELLFLAGS := -NoProfile -Command 

CORE_SERVICES := ${NOOP} dns certgetter ca ingress ingress_prom_exporter vault
BACKUP := ${NOOP} registry_backup
REGISTRY := ${NOOP} registry registryui registry_mirror
MONITORING := ${NOOP} grafana prometheus nagios nagios_mysql prometheusblackbox homer influxdb alertmanager pushgateway
ELASTIC := ${NOOP} es01 es02 es03 kib01 logstash
PROXY := ${NOOP} squidproxy squidmetrics
MISC := ${NOOP} youtube_dl scratch diagrams.net vscode calibre
NEXTCLOUD := ${NOOP} app db
ALL_SERVICES := ${NOOP}${CORE_SERVICES}${MONITORING}${PROXY}${BACKUP}${MISC}${ELASTIC}${NEXTCLOUD}


COMPOSE_MONITORING_FILES := ${NOOP} docker-compose.monitoring.yml
COMPOSE_PROXY_FILES := ${NOOP} docker-compose.proxy.yml
COMPOSE_REGISTRY_FILES := ${NOOP} docker-compose.registry.yml
COMPOSE_MISC_FILES := ${NOOP} docker-compose.misc.yml
CORE_SERVICES_FILES := ${NOOP} docker-compose.yml
COMPOSE_ELASTIC_FILES := ${NOOP} docker-compose.elastic.yml
COMPOSE_NEXTCLOUD_FILES := ${NOOP} docker-compose.nextcloud.yml
COMPOSE_ALL_FILES := ${NOOP}${CORE_SERVICES_FILES}${COMPOSE_REGISTRY_FILES}${COMPOSE_MONITORING_FILES}${COMPOSE_PROXY_FILES}${COMPOSE_MISC_FILES}${COMPOSE_NEXTCLOUD_FILES}${COMPOSE_ELASTIC_FILES}
# -------------------------
classpathify = $(subst $(eval) ,:,$($1))

SWARM_FILE_JOINED_SYNTAX = $(subst $(eval) , -c .\,$1)
SWARM_SERVICES_JOINED_SYNTAX = $(subst $(eval) , $1,$2)
COMPOSE_FILE_JOINED_SYNTAX = $(subst $(eval) , -f ,${COMPOSE_ALL_FILES})
# --------------------------


all: down core registry monitoring elastic
setup:
	@./Configure.ps1

build:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_REGISTRY_FILES}}${COMPOSE_FILE_JOINED_SYNTAX} up -d --build ${ALL_SERVICES}

monitoring:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_MONITORING_FILES}} up -d --build ${MONITORING}

proxy:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_PROXY_FILES}}${COMPOSE_PROXY_FILES} up -d --build ${PROXY}

nextcloud:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_NEXTCLOUD_FILES}}${COMPOSE_NEXTCLOUD_FILES} up -d --build ${NEXTCLOUD}

registry: core
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_REGISTRY_FILES}} up -d --build ${REGISTRY}

core:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${CORE_SERVICES_FILES}} up -d --build ${CORE_SERVICES}
elastic:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_ELASTIC_FILES}} up -d --build ${ELASTIC}
misc:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_MISC_FILES}} up -d --build ${MISC_SERVICES}

down:		
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_ALL_FILES}} down

stop:		
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_ALL_FILES}} stop ${ALL_SERVICES}
	
restart:	
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_ALL_FILES}} restart ${ALL_SERVICES}

rm:				
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_ALL_FILES}} rm -f ${ALL_SERVICES}

logs:	
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_ALL_FILES}} logs --follow --tail=1000 ${ALL_SERVICES}

images:		
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_ALL_FILES}} images ${ALL_SERVICES}

clean: ## Remove all Containers and Delete Volume Data
	-docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_ALL_FILES}} down -v --remove-orphans
	-docker service rm ${call SWARM_SERVICES_JOINED_SYNTAX,core_,${CORE_SERVICES}}

deploy_core:
	docker stack deploy ${call SWARM_FILE_JOINED_SYNTAX,${CORE_SERVICES_FILES}} core
#echo ${COMPOSE_MONITORING_FILES}
#echo ${COMPOSE_ALL_FILES}
##echo $(subst $(eval) , -f ,$(ALL_SERVICES))

services:
	docker service logs
.PHONY: test
test:
	@$return = Start-MyProcess "docker-compose" "--project-name test ${COMPOSE_ALL_FILES} up -d"; if ([string]::IsNullOrEmpty($return.stderr) -or $return.stdoutt -like '*Authorization*'){Write-Error "There was an error" -ErrorAction Stop}
	@Invoke-Pester "./tests"-Verbose
	@docker-compose --project-name test $(COMPOSE_ALL_FILES) down -v 1>$null
	@docker-compose --project-name test $(COMPOSE_ALL_FILES) rm -f 1>$null