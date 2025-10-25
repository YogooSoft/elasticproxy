#!/usr/bin/env bash

# 启动 ElasticProxyServer 多租户模式
set -euo pipefail

cd "$(dirname "$0")"

echo "=========================================="
echo "启动 ElasticProxyServer 多租户模式"
echo "=========================================="
echo

JAR_PATH="target/elasticproxy-server-1.5.3.jar"
if [ ! -f "$JAR_PATH" ]; then
  echo "错误: JAR文件未找到: $JAR_PATH"
  exit 1
fi

# 检查多租户配置文件是否存在
CONFIG_FILE="config/application-multi-tenant.yml"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "警告: 多租户配置文件未找到: $CONFIG_FILE"
  echo "将使用默认配置启动"
fi

# 设置UTF-8环境变量
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8 -Dconsole.encoding=UTF-8 -Duser.language=zh -Duser.country=CN"

# 启动应用
echo "使用多租户配置启动..."
java -Dfile.encoding=UTF-8 -Dconsole.encoding=UTF-8 -Duser.language=zh -Duser.country=CN \
  -jar "$JAR_PATH" \
  --spring.config.location="$CONFIG_FILE" \
  --spring.profiles.active=multi-tenant
