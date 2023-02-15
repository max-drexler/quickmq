.PHONY: stop_rabbitmq start_rabbitmq tox pytest quick_test test docker-pull container-check

RABBIT_MQ_CONTAINER_NAME:=rabbitmq
RABBIT_MQ_IMAGE:=rabbitmq:3-management

test: start_rabbitmq tox stop_rabbitmq

quick_test: start_rabbitmq pytest stop_rabbitmq

pytest: 
	@echo "Runing tests"
	pytest test/

tox:
	@echo "Running tox"
	tox

container-check:
	if [ -z $$(docker ps -q -f name=$(RABBIT_MQ_CONTAINER_NAME)) ]; then \
		echo "Container $(RABBIT_MQ_CONTAINER_NAME) does not exist"; \
	else \
		echo "Container $(RABBIT_MQ_CONTAINER_NAME) exists"; \
	fi

docker-pull:
	@echo "Checking if rabbitmq image exists"
	if ! docker image inspect $(RABBIT_MQ_IMAGE) > /dev/null 2>&1; then \
		docker pull $(RABBIT_MQ_IMAGE); \
	fi

start_rabbitmq: docker-pull
	@echo "Starting RabbitMQ server"
	docker kill $(RABBIT_MQ_CONTAINER_NAME) || true
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
	@echo "Stopping rabbitmq container..."
	docker kill $(RABBIT_MQ_CONTAINER_NAME) || true