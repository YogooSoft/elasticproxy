@echo off
chcp 65001 >nul

echo ==========================================
echo 启动 ElasticProxyServer 多租户模式
echo ==========================================
echo.

java -jar target/elasticproxy-server-1.5.3.jar --spring.config.location=config/application-multi-tenant.yml --spring.profiles.active=multi-tenant
