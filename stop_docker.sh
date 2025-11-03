#!/bin/bash

# ElasticProxyServer Docker 停止脚本
# 用于停止由 start_docker.sh 启动的容器
#
# 使用方法:
#   ./stop_docker.sh [options]
#
# 选项:
#   -h, --help: 显示帮助信息
#   --cleanup: 停止并清理所有相关资源（包括临时文件、日志等）

set -e

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
ElasticProxyServer Docker 停止脚本

使用方法: $0 [options]

选项:
  --cleanup     - 停止并清理所有相关资源（包括临时文件、日志等）
  -h, --help    - 显示此帮助信息

示例:
  $0                   # 仅停止容器
  $0 --cleanup         # 停止容器并清理所有资源

EOF
}

# 检查Docker Compose命令
check_docker_compose() {
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        log_error "Docker Compose 未安装或不在 PATH 中"
        exit 1
    fi
}

# 停止容器
stop_containers() {
    log_info "正在停止 ElasticProxyServer 容器..."
    
    # 检查是否有运行中的容器
    local containers_found=false
    
    # 检查原始 docker-compose.yml
    if [ -f "docker-compose.yml" ] && $DOCKER_COMPOSE_CMD -f docker-compose.yml ps -q | grep -q .; then
        log_info "停止 docker-compose.yml 中的容器..."
        $DOCKER_COMPOSE_CMD -f docker-compose.yml down
        containers_found=true
    fi
    
    # 检查临时配置文件
    if [ -f "docker-compose.temp.yml" ] && $DOCKER_COMPOSE_CMD -f docker-compose.temp.yml ps -q | grep -q .; then
        log_info "停止 docker-compose.temp.yml 中的容器..."
        $DOCKER_COMPOSE_CMD -f docker-compose.temp.yml down
        containers_found=true
    fi
    
    # 通过容器名称直接停止（作为备用方案）
    local container_patterns=("elasticproxy-server" "elasticproxy-server-standard" "elasticproxy-server-multi-tenant")
    for pattern in "${container_patterns[@]}"; do
        if docker ps -q --filter "name=$pattern" | grep -q .; then
            log_info "停止容器: $pattern"
            docker stop "$pattern" || true
            docker rm "$pattern" || true
            containers_found=true
        fi
    done
    
    if [ "$containers_found" = true ]; then
        log_success "容器已停止"
    else
        log_info "没有发现运行中的 ElasticProxyServer 容器"
    fi
}

# 清理资源
cleanup_resources() {
    log_info "清理临时文件和资源..."
    
    # 清理临时配置文件
    if [ -f "docker-compose.temp.yml" ]; then
        rm -f docker-compose.temp.yml
        log_info "已删除临时配置文件: docker-compose.temp.yml"
    fi
    
    # 清理日志目录（询问用户确认）
    if [ -d "logs" ]; then
        read -p "是否要删除日志目录 ./logs? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf logs
            log_info "已删除日志目录"
        else
            log_info "保留日志目录"
        fi
    fi
    
    # 清理 Docker 镜像（询问用户确认）
    if docker images -q linjifan/elasticproxy | grep -q .; then
        read -p "是否要删除 ElasticProxy Docker 镜像? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker rmi linjifan/elasticproxy:1.5.3 || true
            log_info "已删除 Docker 镜像"
        else
            log_info "保留 Docker 镜像"
        fi
    fi
    
    log_success "资源清理完成"
}

# 主函数
main() {
    local cleanup_mode=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cleanup)
                cleanup_mode=true
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
    
    # 显示停止信息
    echo
    log_info "===================================================="
    log_info "ElasticProxyServer Docker 停止脚本"
    log_info "===================================================="
    log_info "清理模式: $([ "$cleanup_mode" = true ] && echo "启用" || echo "禁用")"
    log_info "===================================================="
    echo
    
    # 执行停止流程
    check_docker_compose
    stop_containers
    
    if [ "$cleanup_mode" = true ]; then
        cleanup_resources
    fi
    
    echo
    log_success "ElasticProxyServer 停止完成!"
    
    if [ "$cleanup_mode" = false ]; then
        log_info "提示: 使用 --cleanup 参数可以清理所有相关资源"
    fi
}

# 执行主函数
main "$@"
