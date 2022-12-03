up:
	sudo chown -R $(USER):$(USER) ./var
	sudo chmod -R 0777 ./var
	rm -rf ./var/*
	mkdir -p ./var/squid/logs/ssl_db/cert
	sudo chmod -R 0777 ./var
	docker-compose up -d
