#!/usr/bin/env bash
set -e

ROLE="$1"

PROXY_IP="192.168.56.104"
BACKEND_IP="192.168.56.105"
REDIS_IP="192.168.56.103"
DB_IP="192.168.56.102"

SSH_PORT="22"
PROXY_PORT="5000"
BACKEND_PORT="8080"
REDIS_PORT="6379"
DB_PORT="5432"

reset_rules() {
  iptables -F
  iptables -X
  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT DROP

  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT

  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  iptables -A INPUT -p tcp --dport ${SSH_PORT} -m conntrack --ctstate NEW -j ACCEPT

  iptables -A INPUT -p icmp -j ACCEPT
  iptables -A OUTPUT -p icmp -j ACCEPT
}

case "$ROLE" in
  proxy)
    reset_rules
    iptables -A INPUT  -p tcp --dport ${PROXY_PORT} -m conntrack --ctstate NEW -j ACCEPT
    iptables -A OUTPUT -p tcp -d ${REDIS_IP}   --dport ${REDIS_PORT}   -m conntrack --ctstate NEW -j ACCEPT
    iptables -A OUTPUT -p tcp -d ${BACKEND_IP} --dport ${BACKEND_PORT} -m conntrack --ctstate NEW -j ACCEPT
    ;;
  backend)
    reset_rules
    iptables -A INPUT  -p tcp -s ${PROXY_IP} --dport ${BACKEND_PORT} -m conntrack --ctstate NEW -j ACCEPT
    iptables -A OUTPUT -p tcp -d ${DB_IP} --dport ${DB_PORT} -m conntrack --ctstate NEW -j ACCEPT
    ;;
  redis)
    reset_rules
    iptables -A INPUT -p tcp -s ${PROXY_IP} --dport ${REDIS_PORT} -m conntrack --ctstate NEW -j ACCEPT
    ;;
  db)
    reset_rules
    iptables -A INPUT -p tcp -s ${BACKEND_IP} --dport ${DB_PORT} -m conntrack --ctstate NEW -j ACCEPT
    ;;
  *)
    echo "Usage: $0 {proxy|backend|redis|db}"
    exit 1
    ;;
esac

iptables -S
