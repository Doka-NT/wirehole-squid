up:
	docker-compose up -d
	sudo iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 3128
	sudo iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-port 4128
down:
	sudo iptables -t nat -D OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 3128
	sudo iptables -t nat -D OUTPUT -p tcp --dport 443 -j REDIRECT --to-port 4128
	docker-compose down
