# Create a user scoped variable for the SA password before running
#  [Environment]::SetEnvironmentVariable("CD_SA_PASSWORD", (ConvertTo-SecureString 'WeakP@ssword' -AsPlainText -Force), "User")
#  [Environment]::SetEnvironmentVariable("DOCKER_REGISTRY", "", "Process")


projectName := sqlserver# This should be the folder name this Makefile is in to match what the build script will name it as. IDK how to get the current directory in pure make that works on windows
# https://stackoverflow.com/questions/2004760/get-makefile-directory
registry := localhost:5000/#This can be helpful if testing our infrastructure. If not leave blank to only create a local image
repository := 
sqltag := 2017-latest

SHELL := pwsh.exe
.SHELLFLAGS := -noprofile -command

# All target is the default/what is run if you just type 'make'. It should get a developer up and running as quick as possible. 
all: setup build

# Setup: should be run to prepare for the build. I have used this alot with the docker images, because you want to use unix style line endings, so I want to scan all my script files before the image is built. I prefer to keep the logic of what exactly to do in a single PS script though. 
setup:
	@./build/Setup.ps1

#  Build: should build the project. In the case of docker this should build/tag the images in a consistent method. It has a preq on the setup target. So if you run 'make build' the setup target/script will run as well automatically. 
build: setup
	./build/build.ps1 -registry '$(registry)' -repository '$(repository)' -SQLtagNames '$(sqltag)'

run: build
	@docker run -d -p 1433:1433 --name=sqlserver $(registry)$(repository)$(projectName)_$(sqltag):latest

test: run
	Invoke-Pester ./tests/

Install_tsqlt_to_%:
	./InstallTSQLT.ps1 -db '$*' sa_password 'weakP@ssword'

# clean: up after yourself. I have itty bitty storage on my development machine, so I need to make sure I reclaim as much space as possible! 
clean:
	-@docker stop $(projectName)
	-@docker rm -v $(projectName)
