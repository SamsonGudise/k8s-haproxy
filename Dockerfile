FROM haproxy:2.0
RUN  groupadd -r haproxy && useradd --no-log-init -r -g haproxy haproxy
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg