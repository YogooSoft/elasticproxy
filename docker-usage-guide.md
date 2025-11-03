# ElasticProxyServer Docker Usage Guide

This document describes how to use the provided scripts to manage ElasticProxyServer Docker containers.

## File Description

- `start_docker.sh` - Start script that supports both standard and multi-tenant modes
- `stop_docker.sh` - Stop script for stopping and cleaning up containers
- `docker-compose.yml` - Original Docker Compose configuration file
- `config/application.yml` - Standard mode configuration file
- `config/application-multi-tenant.yml` - Multi-tenant mode configuration file

## Quick Start

### 1. Standard Mode Startup

```bash
# Run in foreground (view real-time logs)
./start_docker.sh standard

# Run in background
./start_docker.sh standard -d
```

### 2. Multi-tenant Mode Startup

```bash
# Run in foreground
./start_docker.sh multi-tenant

# Run in background
./start_docker.sh multi-tenant -d
```

### 3. Stop Service

```bash
# Stop containers only
./stop_docker.sh

# Stop containers and cleanup resources
./stop_docker.sh --cleanup
```

## Mode Differences

### Standard Mode
- Uses `config/application.yml` configuration file
- Multi-tenant functionality disabled (`multi-tenant.enabled: false`)
- Single authentication and configuration
- Suitable for simple proxy scenarios

### Multi-tenant Mode
- Uses `config/application-multi-tenant.yml` configuration file
- Multi-tenant functionality enabled (`multi-tenant.enabled: true`)
- Supports multiple tenants with independent configurations
- Supports Basic authentication isolation
- Suitable for complex multi-user, multi-permission scenarios

## Advanced Features

### Test Configuration (without starting containers)

```bash
# Generate configuration files without starting containers
./start_docker.sh standard --dry-run
./start_docker.sh multi-tenant --dry-run

# View generated configuration
cat docker-compose.temp.yml
```

### View Service Status

```bash
# Check container status
docker ps | grep elasticproxy

# View service logs
docker logs elasticproxy-server-standard
# or
docker logs elasticproxy-server-multi-tenant
```

### Health Check

After service startup, you can check health status through the following addresses:
- Service URL: http://localhost:8000
- Health check: http://localhost:8000/actuator/health

## Configuration Customization

### Environment Variables

You can customize JVM parameters through environment variables:

```bash
# Set JVM parameters
export JVM_OPTS="-Xms1024m -Xmx2048m -XX:+UseG1GC"
./start_docker.sh multi-tenant -d
```

### Log Management

Container logs are saved in the `./logs` directory and can be viewed through:

```bash
# View all log files
ls -la logs/

# View real-time logs
tail -f logs/application.log
```

### Configuration File Modification

To modify configurations:

1. Edit the corresponding configuration file:
   - Standard mode: `config/application.yml`
   - Multi-tenant mode: `config/application-multi-tenant.yml`

2. Restart the container:
   ```bash
   ./stop_docker.sh
   ./start_docker.sh <mode> -d
   ```

## Troubleshooting

### 1. Port Conflict

If port 8000 is already in use:

```bash
# Check port usage
lsof -i :8000

# Kill the process using the port
kill -9 <PID>
```

### 2. Container Startup Failure

Check configuration files and dependencies:

```bash
# Validate configuration file syntax
./start_docker.sh <mode> --dry-run

# View detailed error logs
docker logs elasticproxy-server-<mode>
```

### 3. Clean All Resources

Complete environment cleanup:

```bash
./stop_docker.sh --cleanup
```

## Multi-tenant Configuration Description

In multi-tenant mode, the system supports multiple independent tenant configurations. Each tenant can have:

- Independent Basic authentication credentials
- Different Elasticsearch cluster connections
- Independent access permissions and restrictions
- Custom monitoring configurations

### Example Tenant Configuration

The configuration file includes the following predefined tenants:

1. **default** - Default tenant (compatibility mode)
   - Username/Password: `default/default-secret`
   - Uses global configuration

2. **tenant-logs** - Log analysis tenant
   - Username/Password: `logs-user/logs-secret-2024`
   - Dedicated for log data analysis

3. **tenant-metrics** - Metrics monitoring tenant
   - Username/Password: `metrics-user/metrics-secret-2024`
   - Dedicated for metrics data monitoring

4. **tenant-readonly** - Read-only access tenant
   - Username/Password: `readonly-user/readonly-secret-2024`
   - Only allows search operations

### Access Examples

```bash
# Access using different tenants
curl -u "logs-user:logs-secret-2024" http://localhost:8000/_search
curl -u "metrics-user:metrics-secret-2024" http://localhost:8000/metrics-*/_search
curl -u "readonly-user:readonly-secret-2024" http://localhost:8000/public-*/_search
```

## Important Notes

1. Ensure Docker and Docker Compose are properly installed
2. Elasticsearch connection information in configuration files needs to be modified according to the actual environment
3. Authentication credentials in multi-tenant mode should be updated regularly
4. It is recommended to use HTTPS and stronger authentication mechanisms in production environments
5. Regularly backup configuration files and important logs

## Support

If you encounter problems, please check:
1. Script help information: `./start_docker.sh --help`
2. Docker logs: `docker logs <container-name>`
3. Application logs: Files in the `logs/` directory
