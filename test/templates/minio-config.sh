#!/bin/ash
set -eu
mc alias set local http://127.0.0.1:9000 admin test1234
mc admin user svcacct add local admin --access-key mykey --secret-key mysecret
mc mb local/mybucket
