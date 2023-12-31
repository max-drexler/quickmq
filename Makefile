.PHONY: help stop_rabbitmq start_rabbitmq tox pytest quick_test test docker-pull upload

RABBIT_MQ_CONTAINER_NAME:=rabbitmq
RABBIT_MQ_IMAGE:=rabbitmq:3-management

help:
	@echo "QuickMQ Makefile Options:"
	@echo -e "\
	test           -> Runs full test suite \n\
	quick_test     -> Runs tests on current python interpreter\n\
	tox            -> Runs full test suite w/o starting server\n\
	pytest         -> Runs tests on current python interpreter w/o starting server\n\
	docker-pull    -> Downloads RabbitMQ docker image\n\
	start_rabbitmq -> Starts the RabbitMQ server locally\n\
	stop_rabbitmq  -> Stops the local RabbitMQ Server if it is running\n\
	upload         -> Builds and uploads current code to PyPi\n\
	test-upload    -> Builds and uploads current code to test-PyPi\n\
	"

test: stop_rabbitmq start_rabbitmq tox stop_rabbitmq

quick_test: stop_rabbitmq start_rabbitmq pytest stop_rabbitmq

pytest: 
	@echo "Runing tests"
	pytest test/

tox:
	@echo "Running tox"
	tox

docker-pull:
	@echo "Checking if rabbitmq image exists"
	@if ! docker image inspect $(RABBIT_MQ_IMAGE) > /dev/null 2>&1; then \
		echo "Pulling rabbitmq docker image";\
		docker pull $(RABBIT_MQ_IMAGE); \
	fi

start_rabbitmq: docker-pull
	@echo "Starting RabbitMQ server"
	docker run --rm -d \
		--name $(RABBIT_MQ_CONTAINER_NAME) \
		-p 5671:5671 \
		-p 5672:5672 \
		-p 15671:15671 \
		-p 15672:15672 \
		$(RABBIT_MQ_IMAGE)		
	@echo "Waiting for docker to finish setup"
	sleep 2

stop_rabbitmq:
	@if [ -z $$(docker ps -q -f name=$(RABBIT_MQ_CONTAINER_NAME)) ]; then\
		echo "Container $(RABBIT_MQ_CONTAINER_NAME) does not exist";\
	else\
		echo "Container $(RABBIT_MQ_CONTAINER_NAME) exists, stopping";\
		docker kill $(RABBIT_MQ_CONTAINER_NAME);\
	fi

upload:
	python3 -m build
	python3 -m twine upload --skip-existing -u mdrexler dist/*

test-upload:
	python3 -m build
	python3 -m twine upload --skip-existing -u mdrexler --repository testpypi dist/*