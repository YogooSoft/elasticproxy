#!/bin/bash

# ElasticProxyServer Docker 启动脚本
# 支持标准模式和多租户模式的启动
# 
# 使用方法:
#   ./start_docker.sh <mode> [options]
#
# 参数说明:
#   mode: 启动模式
#     - standard: 标准模式 (使用 application.yml)
#     - multi-tenant: 多租户模式 (使用 application-multi-tenant.yml)
#
# 选项:
#   -d: 后台运行 (detached mode)
#   -h: 显示帮助信息
#   --dry-run: 仅生成配置文件，不启动容器（测试模式）
#
# 示例:
#   ./start_docker.sh standard       # 标准模式前台运行
#   ./start_docker.sh standard -d    # 标准模式后台运行
#   ./start_docker.sh multi-tenant   # 多租户模式前台运行
#   ./start_docker.sh multi-tenant -d # 多租户模式后台运行

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
ElasticProxyServer Docker 启动脚本

使用方法: $0 <mode> [options]

参数说明:
  mode: 启动模式
    standard      - 标准模式 (使用 application.yml，多租户功能关闭)
    multi-tenant  - 多租户模式 (使用 application-multi-tenant.yml，多租户功能开启)

选项:
  -d            - 后台运行 (detached mode)
  -h, --help    - 显示此帮助信息
  --dry-run     - 仅生成配置文件，不启动容器（测试模式）

示例:
  $0 standard                # 标准模式前台运行
  $0 standard -d             # 标准模式后台运行
  $0 multi-tenant            # 多租户模式前台运行
  $0 multi-tenant -d         # 多租户模式后台运行

配置文件说明:
  - 标准模式: config/application.yml
  - 多租户模式: config/application-multi-tenant.yml

EOF
}

# 检查Docker和docker-compose是否安装
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装或不在 PATH 中"
        exit 1
    fi
    
    # 检查 docker compose 或 docker-compose
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        log_error "Docker Compose 未安装或不在 PATH 中"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 检查配置文件是否存在
check_config_files() {
    local config_dir="$(dirname "$0")/config"
    
    if [ ! -d "$config_dir" ]; then
        log_error "配置目录不存在: $config_dir"
        exit 1
    fi
    
    if [ ! -f "$config_dir/application.yml" ]; then
        log_error "标准模式配置文件不存在: $config_dir/application.yml"
        exit 1
    fi
    
    if [ ! -f "$config_dir/application-multi-tenant.yml" ]; then
        log_error "多租户模式配置文件不存在: $config_dir/application-multi-tenant.yml"
        exit 1
    fi
    
    log_success "配置文件检查通过"
}

# 停止现有容器
stop_existing_containers() {
    log_info "检查并停止现有容器..."
    
    if $DOCKER_COMPOSE_CMD ps -q | grep -q .; then
        log_warning "发现运行中的容器，正在停止..."
        $DOCKER_COMPOSE_CMD down
        log_success "现有容器已停止"
    else
        log_info "没有运行中的容器"
    fi
}

# 生成临时 docker-compose 文件
generate_docker_compose() {
    local mode=$1
    local config_file=""
    
    case $mode in
        "standard")
            config_file="./config/application.yml"
            log_info "使用标准模式配置: $config_file"
            ;;
        "multi-tenant")
            config_file="./config/application-multi-tenant.yml"
            log_info "使用多租户模式配置: $config_file"
            ;;
        *)
            log_error "未知模式: $mode"
            exit 1
            ;;
    esac
    
    # 生成临时 docker-compose 文件
    cat > docker-compose.temp.yml << EOF
# Docker Compose configuration for ElasticProxyServer
# 临时生成的配置文件 - 请勿手动编辑
# 模式: ${mode}

services:
  # ElasticProxyServer 服务
  elasticproxy:
    image: linjifan/elasticproxy:1.5.3
    container_name: elasticproxy-server-${mode}
    environment:
      # JVM 配置
      - JVM_OPTS=\${JVM_OPTS:--Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseContainerSupport}
      # Spring 配置
      - SPRING_PROFILES_ACTIVE=\${SPRING_PROFILES_ACTIVE:-docker}
      # 模式标识
      - ELASTIC_PROXY_MODE=${mode}
    ports:
      - "8000:8000"
    volumes:
      # 挂载对应的配置文件
      - ${config_file}:/app/config/application.yml:ro
      # 挂载日志目录
      - ./logs:/app/logs
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/actuator/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 90s
    restart: unless-stopped
EOF
    
    log_success "已生成临时 docker-compose 配置"
}

# 启动容器
start_containers() {
    local detached_mode=$1
    local mode=$2
    
    local compose_args=""
    if [ "$detached_mode" = true ]; then
        compose_args="-d"
        log_info "启动容器 (后台模式)..."
    else
        log_info "启动容器 (前台模式)..."
    fi
    
    # 使用临时配置文件启动
    $DOCKER_COMPOSE_CMD -f docker-compose.temp.yml up $compose_args
    
    if [ $? -eq 0 ]; then
        log_success "ElasticProxyServer ($mode 模式) 启动成功!"
        
        if [ "$detached_mode" = true ]; then
            echo
            log_info "服务信息:"
            log_info "  - 访问地址: http://localhost:8000"
            log_info "  - 健康检查: http://localhost:8000/actuator/health"
            log_info "  - 容器名称: elasticproxy-server-$mode"
            echo
            log_info "常用命令:"
            log_info "  - 查看日志: $DOCKER_COMPOSE_CMD -f docker-compose.temp.yml logs -f"
            log_info "  - 停止服务: $DOCKER_COMPOSE_CMD -f docker-compose.temp.yml down"
            log_info "  - 查看状态: $DOCKER_COMPOSE_CMD -f docker-compose.temp.yml ps"
        fi
    else
        log_error "容器启动失败"
        cleanup_temp_files
        exit 1
    fi
}

# 清理临时文件
cleanup_temp_files() {
    if [ -f "docker-compose.temp.yml" ]; then
        rm -f docker-compose.temp.yml
        log_info "已清理临时文件"
    fi
}

# 信号处理 - 清理临时文件
trap cleanup_temp_files EXIT INT TERM

# 主函数
main() {
    local mode=""
    local detached_mode=false
    local dry_run_mode=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            standard|multi-tenant)
                mode=$1
                shift
                ;;
            -d|--detach)
                detached_mode=true
                shift
                ;;
            --dry-run)
                dry_run_mode=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                echo
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查必需参数
    if [ -z "$mode" ]; then
        log_error "请指定启动模式 (standard 或 multi-tenant)"
        echo
        show_help
        exit 1
    fi
    
    # 显示启动信息
    echo
    log_info "===================================================="
    log_info "ElasticProxyServer Docker 启动脚本"
    log_info "===================================================="
    log_info "启动模式: $mode"
    log_info "运行方式: $([ "$detached_mode" = true ] && echo "后台运行" || echo "前台运行")"
    log_info "===================================================="
    echo
    
    # 执行启动流程
    if [ "$dry_run_mode" = true ]; then
        log_info "运行模式: 测试模式 (仅生成配置文件)"
    else
        check_dependencies
    fi
    
    check_config_files
    
    if [ "$dry_run_mode" = false ]; then
        stop_existing_containers
    fi
    
    generate_docker_compose "$mode"
    
    if [ "$dry_run_mode" = true ]; then
        log_success "配置文件生成完成: docker-compose.temp.yml"
        log_info "你可以查看生成的配置文件内容："
        log_info "  cat docker-compose.temp.yml"
        log_info "要启动容器，请运行："
        if [ "$detached_mode" = true ]; then
            log_info "  docker compose -f docker-compose.temp.yml up -d"
        else
            log_info "  docker compose -f docker-compose.temp.yml up"
        fi
        # 在dry-run模式下不清理文件，让用户可以查看
        trap - EXIT INT TERM
    else
        start_containers "$detached_mode" "$mode"
        
        # 如果是前台模式，保留临时文件直到容器停止
        if [ "$detached_mode" = false ]; then
            log_warning "按 Ctrl+C 停止服务..."
            # 等待用户中断，然后清理
            wait
        fi
    fi
}

# 执行主函数
main "$@"
