ifeq ($(OS),Windows_NT)
    SHELL := pwsh.exe
else
   SHELL := pwsh
endif
.SHELLFLAGS := -NoProfile -Command 

# -- Define your services that live in your compose files --#
CORE_SERVICES := ${NOOP} dns certgetter ca ingress ingress_prom_exporter vault
BACKUP := ${NOOP} registry_backup
REGISTRY := ${NOOP} registry registryui registry_mirror registry_backup
MONITORING := ${NOOP} grafana prometheus nagios nagios_mysql prometheusblackbox homer alertmanager pushgateway squidmetrics
ELASTIC := ${NOOP} es01 es02 es03 kib01 logstash
PROXY := ${NOOP} squidproxy squidmetrics
MISC := ${NOOP} youtube_dl scratch diagrams.net vscode calibre
VIRUS := ${NOOP} redis mongodb consul virusscan_ui api dummy-scanner clamav-scanner windows-defender-scanner
NEXTCLOUD := ${NOOP} app db
ANALYTICS := ${NOOP} metabase
MINIO := ${NOOP} minio1
ALL_SERVICES := ${NOOP}${CORE_SERVICES}${MONITORING}${PROXY}${BACKUP}${MISC}${ELASTIC}${NEXTCLOUD}${ANALYTICS}${MINIO}
# -------------------------

# -- Define the yml files -- #
COMPOSE_MONITORING_FILES := ${NOOP} docker-compose.monitoring.yml
COMPOSE_PROXY_FILES := ${NOOP} docker-compose.proxy.yml
COMPOSE_REGISTRY_FILES := ${NOOP} docker-compose.registry.yml
COMPOSE_MISC_FILES := ${NOOP} docker-compose.misc.yml
CORE_SERVICES_FILES := ${NOOP} docker-compose.yml
COMPOSE_ELASTIC_FILES := ${NOOP} docker-compose.elastic.yml
COMPOSE_NEXTCLOUD_FILES := ${NOOP} docker-compose.nextcloud.yml
COMPOSE_VIRUS_FILES := ${NOOP} docker-compose.virusscan.yml
COMPOSE_ANALYTICS_FILES := ${NOOP} docker-compose.analytics.yml
COMPOSE_MINIO_FILES := ${NOOP} docker-compose.minio.yml
COMPOSE_ALL_FILES := ${NOOP}${CORE_SERVICES_FILES}${COMPOSE_REGISTRY_FILES}${COMPOSE_MONITORING_FILES}${COMPOSE_PROXY_FILES}${COMPOSE_MISC_FILES}${COMPOSE_NEXTCLOUD_FILES}${COMPOSE_ELASTIC_FILES}${COMPOSE_VIRUS_FILES}${COMPOSE_ANALYTICS_FILES}${COMPOSE_MINIO_FILES}
# -------------------------

# -- Functions to help the makefile work for docker compose and docker deploy -- #
classpathify = $(subst $(eval) ,:,$($1))

SWARM_FILE_JOINED_SYNTAX = $(subst $(eval) , -c .\,$1)
SWARM_SERVICES_JOINED_SYNTAX = $(subst $(eval) , $1,$2)
COMPOSE_FILE_JOINED_SYNTAX = $(subst $(eval) , -f ,$1)
# --------------------------


all: down core registry monitoring elastic

build_src:
	$(MAKE) -C src/certgetter/.
	$(MAKE) -C src/prometheus/.
	$(MAKE) -C src/prometheusblackbox/.

setup:
	@./Configure.ps1

build:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_REGISTRY_FILES}}${COMPOSE_FILE_JOINED_SYNTAX} up -d --build ${ALL_SERVICES}

monitoring:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_MONITORING_FILES}} up -d --build ${MONITORING}

proxy:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_PROXY_FILES}} up -d --build ${PROXY}

nextcloud:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_NEXTCLOUD_FILES}} up -d --build ${NEXTCLOUD}

virus:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_VIRUS_FILES}} up -d --build ${VIRUS}

minio:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_MINIO_FILES}} up -d --build ${MINIO}

analytics:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_ANALYTICS_FILES}} up -d --build ${ANALYTICS}

registry: core
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_REGISTRY_FILES}} up -d --build ${REGISTRY}

core:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${CORE_SERVICES_FILES}} up -d --build ${CORE_SERVICES}

elastic:
	@docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_ELASTIC_FILES}} up -d --build ${ELASTIC}

misc:
	docker-compose ${call COMPOSE_FILE_JOINED_SYNTAX,${COMPOSE_MISC_FILES}} up -d --build ${MISC_SERVICES}

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
	-docker service rm ${call SWARM_SERVICES_JOINED_SYNTAX,all_,${CORE_SERVICES}}
	-docker service rm ${call SWARM_SERVICES_JOINED_SYNTAX,all_,${MONITORING}}
	-docker service rm ${call SWARM_SERVICES_JOINED_SYNTAX,all_,${MISC}}
	-docker service rm ${call SWARM_SERVICES_JOINED_SYNTAX,all_,${REGISTRY}}
	-docker network prune -f

deploy_core:
	docker stack deploy ${call SWARM_FILE_JOINED_SYNTAX,${CORE_SERVICES_FILES}} all

deploy_monitoring:
	docker stack deploy ${call SWARM_FILE_JOINED_SYNTAX,${COMPOSE_MONITORING_FILES}} all

deploy_misc:
	docker stack deploy ${call SWARM_FILE_JOINED_SYNTAX,${COMPOSE_MISC_FILES}} all

deploy_registry:
	docker stack deploy ${call SWARM_FILE_JOINED_SYNTAX,${COMPOSE_REGISTRY_FILES}} all

services:
	docker service logs
.PHONY: test
test:
	@$return = Start-MyProcess "docker-compose" "--project-name test ${COMPOSE_ALL_FILES} up -d"; if ([string]::IsNullOrEmpty($return.stderr) -or $return.stdoutt -like '*Authorization*'){Write-Error "There was an error" -ErrorAction Stop}
	@Invoke-Pester "./tests"-Verbose
	@docker-compose --project-name test $(COMPOSE_ALL_FILES) down -v 1>$null
	@docker-compose --project-name test $(COMPOSE_ALL_FILES) rm -f 1>$null