#!/bin/bash

URL=http://localhost:9454
PAGES='Main_Page Barack_Obama'
WARMUP_REQUESTS=5
TEST_REQUESTS=10

set -e

kill_nginx() {
	ps aux|grep nginx
	echo "Stopping nginx..."
	#pkill -9 -x -u `whoami` nginx
	nginx -p $PWD -c ./nginx.conf -s stop || true
}

request() {
	PAGE=$1
	NUMBER=$2

	ab -n $NUMBER $URL/wiki/$PAGE?action=purge
}

kill_nginx

echo 'Starting a test instance of nginx...'
nginx -p $PWD -c ./nginx.conf

echo 'Warming up JIT...'
for PAGE in $PAGES; do
	request $PAGE $WARMUP_REQUESTS > /dev/null
done

for PAGE in $PAGES; do
	echo "Testing performance for $PAGE..."
	request $PAGE $TEST_REQUESTS
done

kill_nginx
