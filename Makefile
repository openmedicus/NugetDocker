all: pull build push

pull:
	sudo docker pull openmedicus/centos-lamp:latest

build:
	sudo docker build -t simple-nuget-server .

push:
	sudo docker tag simple-nuget-server openmedicus/simple-nuget-server:latest
	sudo docker push openmedicus/simple-nuget-server

run:
	sudo docker run --name simple-nuget-server -p 80:80 simple-nuget-server &

attach:
	sudo docker exec -it simple-nuget-server /bin/bash

bash:
	sudo docker run -i -t simple-nuget-server /bin/bash
