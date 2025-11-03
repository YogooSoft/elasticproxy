# ElasticProxyServer Docker 使用指南

本文档介绍如何使用提供的脚本来管理 ElasticProxyServer 的 Docker 容器。

## 文件说明

- `start_docker.sh` - 启动脚本，支持标准模式和多租户模式
- `stop_docker.sh` - 停止脚本，用于停止和清理容器
- `docker-compose.yml` - 原始 Docker Compose 配置文件
- `config/application.yml` - 标准模式配置文件
- `config/application-multi-tenant.yml` - 多租户模式配置文件

## 快速开始

### 1. 标准模式启动

```bash
# 前台运行（查看实时日志）
./start_docker.sh standard

# 后台运行
./start_docker.sh standard -d
```

### 2. 多租户模式启动

```bash
# 前台运行
./start_docker.sh multi-tenant

# 后台运行
./start_docker.sh multi-tenant -d
```

### 3. 停止服务

```bash
# 仅停止容器
./stop_docker.sh

# 停止容器并清理资源
./stop_docker.sh --cleanup
```

## 模式区别

### 标准模式 (standard)
- 使用 `config/application.yml` 配置文件
- 多租户功能关闭 (`multi-tenant.enabled: false`)
- 单一认证和配置
- 适合简单的代理场景

### 多租户模式 (multi-tenant)
- 使用 `config/application-multi-tenant.yml` 配置文件
- 多租户功能开启 (`multi-tenant.enabled: true`)
- 支持多个租户，每个租户有独立的配置
- 支持 Basic 认证隔离
- 适合多用户、多权限的复杂场景

## 高级功能

### 测试配置（不启动容器）

```bash
# 生成配置文件但不启动容器
./start_docker.sh standard --dry-run
./start_docker.sh multi-tenant --dry-run

# 查看生成的配置
cat docker-compose.temp.yml
```

### 查看服务状态

```bash
# 查看容器状态
docker ps | grep elasticproxy

# 查看服务日志
docker logs elasticproxy-server-standard
# 或
docker logs elasticproxy-server-multi-tenant
```

### 健康检查

服务启动后，可以通过以下地址检查健康状态：
- 服务地址: http://localhost:8000
- 健康检查: http://localhost:8000/actuator/health

## 配置自定义

### 环境变量

可以通过环境变量自定义 JVM 参数：

```bash
# 设置 JVM 参数
export JVM_OPTS="-Xms1024m -Xmx2048m -XX:+UseG1GC"
./start_docker.sh multi-tenant -d
```

### 日志管理

容器日志会保存在 `./logs` 目录中，可以通过以下方式查看：

```bash
# 查看所有日志文件
ls -la logs/

# 实时查看日志
tail -f logs/application.log
```

### 配置文件修改

如需修改配置：

1. 编辑对应的配置文件：
   - 标准模式：`config/application.yml`
   - 多租户模式：`config/application-multi-tenant.yml`

2. 重启容器：
   ```bash
   ./stop_docker.sh
   ./start_docker.sh <mode> -d
   ```

## 故障排除

### 1. 端口冲突

如果 8000 端口被占用：

```bash
# 查看端口占用
lsof -i :8000

# 停止占用端口的进程
kill -9 <PID>
```

### 2. 容器启动失败

检查配置文件和依赖：

```bash
# 验证配置文件语法
./start_docker.sh <mode> --dry-run

# 查看详细错误日志
docker logs elasticproxy-server-<mode>
```

### 3. 清理所有资源

完全清理环境：

```bash
./stop_docker.sh --cleanup
```

## 多租户配置说明

在多租户模式下，系统支持多个独立的租户配置。每个租户可以有：

- 独立的 Basic 认证凭据
- 不同的 Elasticsearch 集群连接
- 独立的访问权限和限制
- 自定义的监控配置

### 示例租户配置

配置文件中包含以下预定义租户：

1. **default** - 默认租户（兼容模式）
   - 用户名/密码: `default/default-secret`
   - 使用全局配置

2. **tenant-logs** - 日志分析租户
   - 用户名/密码: `logs-user/logs-secret-2024`
   - 专用于日志数据分析

3. **tenant-metrics** - 指标监控租户
   - 用户名/密码: `metrics-user/metrics-secret-2024`
   - 专用于指标数据监控

4. **tenant-readonly** - 只读访问租户
   - 用户名/密码: `readonly-user/readonly-secret-2024`
   - 仅允许搜索操作

### 访问示例

```bash
# 使用不同租户访问
curl -u "logs-user:logs-secret-2024" http://localhost:8000/_search
curl -u "metrics-user:metrics-secret-2024" http://localhost:8000/metrics-*/_search
curl -u "readonly-user:readonly-secret-2024" http://localhost:8000/public-*/_search
```

## 注意事项

1. 确保 Docker 和 Docker Compose 已正确安装
2. 配置文件中的 Elasticsearch 连接信息需要根据实际环境修改
3. 多租户模式下的认证凭据应该定期更新
4. 建议在生产环境中使用 HTTPS 和更强的认证机制
5. 定期备份配置文件和重要日志

## 支持

如遇问题，请检查：
1. 脚本帮助信息：`./start_docker.sh --help`
2. Docker 日志：`docker logs <容器名>`
3. 应用程序日志：`logs/` 目录下的文件
