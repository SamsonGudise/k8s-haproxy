default: build
build:
	docker build -t my-haproxy .
test: build
	docker run -it --rm --name haproxy-syntax-check my-haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
release: 
	docker build -t samsonbabu/haproxy:0.2 .
	docker push samsonbabu/haproxy:0.2
