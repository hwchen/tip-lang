watch-file-debug path:
     watchexec -r -w src -w {{path}} 'gyro build run -- {{path}}'

watch-file path:
     watchexec -r -w src -w {{path}} 'gyro build -Drelease-fast=true run -- {{path}}'
