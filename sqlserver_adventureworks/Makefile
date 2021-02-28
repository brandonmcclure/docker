projectName := sqlserver_adventureworks # This should be the folder name this Makefile is in to match what the build script will name it as. IDK how to get the current directory in pure make that works on windows
# https://stackoverflow.com/questions/2004760/get-makefile-directory
registry := 
repository := bmcclure89/
sqltag := 2017-latest

SHELL := pwsh.exe
.SHELLFLAGS := -noprofile -command

.PHONY: build

all: build

setup:
	@./build/Setup.ps1

build: setup
	./build/build.ps1 -registry '$(registry)' -repository '$(repository)' -SQLtagNames '$(sqltag)'

run: build
	@docker run -d -p 1433:1433 --name=sqlserver_adventureWorks $(registry)$(repository)$(projectName)_$(sqltag):latest

test: run
	Invoke-Pester ./tests/

Install_tsqlt_to_%:
	./InstallTSQLT.ps1 -db '$*' sa_password 'weakP@ssword'

# clean: up after yourself. I have itty bitty storage on my development machine, so I need to make sure I reclaim as much space as possible! 
clean:
	-@docker stop $(projectName)
	-@docker rm -v $(projectName)
