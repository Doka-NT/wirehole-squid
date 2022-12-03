up:
	sudo chown -R $(USER):$(USER) ./var
	sudo chmod -R 0777 ./var
	rm -rf ./var/*
	mkdir -p ./var/squid/logs/ssl_db/cert
	sudo chmod -R 0777 ./var
	docker-compose run squid bash -c 'rm -rf /usr/local/squid/var/logs/ssl_db && /usr/local/squid/libexec/security_file_certgen -c -s /usr/local/squid/var/logs/ssl_db -M16MB'
	docker-compose up -d

down:
	docker-compose down
