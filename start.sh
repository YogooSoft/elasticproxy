#!/usr/bin/env bash

# Run the application
set -euo pipefail

cd "$(dirname "$0")"

mkdir -p logs

JAR_PATH="target/elasticproxy-server-1.5.3.jar"
if [ ! -f "$JAR_PATH" ]; then
  echo "Jar not found: $JAR_PATH"
  exit 1
fi

# 设置UTF-8环境变量
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8 -Dconsole.encoding=UTF-8 -Duser.language=zh -Duser.country=CN"

java -Dfile.encoding=UTF-8 -Dconsole.encoding=UTF-8 -Duser.language=zh -Duser.country=CN -jar "$JAR_PATH" 

# nohup java -Dfile.encoding=UTF-8 -Dconsole.encoding=UTF-8 -Duser.language=zh -Duser.country=CN -jar "$JAR_PATH" > logs/app.out 2>&1 &
# pid=$!
# echo "$pid" > app.pid
# echo "Started ElasticProxyServer. PID: $pid. Logs: logs/app.out"