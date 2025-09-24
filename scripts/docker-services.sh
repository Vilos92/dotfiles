#!/bin/bash

# GregZone Docker Services Management Script
# This script helps manage and access all Docker services in the GregZone

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to show service status
show_status() {
    print_header "Docker Services Status"
    docker-compose -f greg-zone/docker-compose.yml ps
}

# Function to start all services
start_services() {
    print_header "Starting GregZone Services"
    print_status "Starting all Docker services..."
    docker-compose -f greg-zone/docker-compose.yml up -d
    print_status "Services started! Use 'docker-compose -f greg-zone/docker-compose.yml logs -f' to follow logs"
    
    echo
    print_header "🚀 Quick Access Links"
    echo
    echo -e "${GREEN}🏠 Homepage & Monitoring:${NC}"
    echo -e "   • Main Dashboard: http://greg-zone"
    echo -e "   • Monitoring:     http://greg-zone:9006"
    echo
    echo -e "${BLUE}🔒 Tailscale Access:${NC}"
    echo -e "   • copyparty:     http://greg-zone:9001"
    echo -e "   • FreshRSS:      http://greg-zone:9002"
    echo -e "   • Kiwix:         http://greg-zone:9003"
    echo -e "   • Transmission:  http://greg-zone:9004"
    echo
    echo -e "${PURPLE}🌍 Public Access:${NC}"
    echo -e "   • copyparty:     https://copyparty.greglinscheid.com"
    echo -e "   • FreshRSS:      https://freshrss.greglinscheid.com"
    echo -e "   • Kiwix:         https://kiwix.greglinscheid.com"
    echo
    echo -e "${CYAN}💻 Local Access:${NC}"
    echo -e "   • Prometheus:    http://greg-zone:9090"
    echo -e "   • Grafana:       http://greg-zone:3000"
    echo -e "   • cAdvisor:      http://greg-zone:8080"
    echo
    echo -e "${YELLOW}Grafana login: admin / admin${NC}"
}

# Function to stop all services
stop_services() {
    print_header "Stopping GregZone Services"
    print_status "Stopping all Docker services..."
    docker-compose -f greg-zone/docker-compose.yml down
    print_status "Services stopped!"
}

# Function to restart all services
restart_services() {
    print_header "Restarting GregZone Services"
    print_status "Restarting all Docker services..."
    docker-compose -f greg-zone/docker-compose.yml restart
    print_status "Services restarted!"
}

# Function to pull latest images
pull_services() {
    print_header "Pulling Latest Images"
    print_status "Pulling latest images for all services..."
    docker-compose -f greg-zone/docker-compose.yml pull
    print_status "Images pulled!"
}

# Function to update services (pull + restart)
update_services() {
    print_header "Updating GregZone Services"
    print_status "Pulling latest images..."
    docker-compose -f greg-zone/docker-compose.yml pull
    print_status "Restarting services with new images..."
    docker-compose -f greg-zone/docker-compose.yml up -d
    print_status "Services updated!"
}

# Function to build services (for local builds)
build_services() {
    print_header "Building GregZone Services"
    print_status "Building all Docker services..."
    docker-compose -f greg-zone/docker-compose.yml build
    print_status "Services built!"
}

# Function to show service logs with follow
follow_logs() {
    local service=${1:-""}
    if [ -n "$service" ]; then
        print_header "Following logs for $service"
        docker-compose -f greg-zone/docker-compose.yml logs -f "$service"
    else
        print_header "Following All Services Logs"
        docker-compose -f greg-zone/docker-compose.yml logs -f
    fi
}

# Function to show logs without follow
show_logs() {
    local service=${1:-""}
    if [ -n "$service" ]; then
        print_header "Logs for $service"
        docker-compose -f greg-zone/docker-compose.yml logs --tail=100 "$service"
    else
        print_header "All Services Logs"
        docker-compose -f greg-zone/docker-compose.yml logs --tail=100
    fi
}

# Function to show service access information
show_access_info() {
    print_header "GregZone Service Access Information"
    echo
    echo -e "${GREEN}🏠 Homepage & Monitoring:${NC}"
    echo -e "   • Main Dashboard: http://greg-zone (All services)"
    echo -e "   • Monitoring:     http://greg-zone:9006 (Grafana dashboards)"
    echo
    echo -e "${BLUE}🔒 Tailscale Access (Private Network):${NC}"
    echo -e "   • copyparty:     http://greg-zone:9001 (File sharing)"
    echo -e "   • FreshRSS:      http://greg-zone:9002 (RSS reader)"
    echo -e "   • Kiwix:         http://greg-zone:9003 (Offline wikis)"
    echo -e "   • Transmission:  http://greg-zone:9004 (Torrent client)"
    echo -e "   • Prometheus:    http://greg-zone:9005 (Metrics collection)"
    echo -e "   • cAdvisor:      http://greg-zone:9007 (Container metrics)"
    echo
    echo -e "${PURPLE}🌍 Public Access (via Cloudflare):${NC}"
    echo -e "   • copyparty:     https://copyparty.greglinscheid.com (File sharing)"
    echo -e "   • FreshRSS:      https://freshrss.greglinscheid.com (RSS reader)"
    echo -e "   • Kiwix:         https://kiwix.greglinscheid.com (Offline wikis)"
    echo
    echo -e "${CYAN}💻 Local Access (Direct Ports):${NC}"
    echo -e "   • Node Exporter: http://greg-zone:9100 (System metrics)"
    echo -e "   • Prometheus:    http://greg-zone:9090 (Direct access)"
    echo -e "   • Grafana:       http://greg-zone:3000 (Direct access)"
    echo -e "   • cAdvisor:      http://greg-zone:8080 (Direct access)"
    echo
    echo -e "${YELLOW}Note: Tailscale services require VPN connection${NC}"
    echo -e "${YELLOW}Grafana default login: admin / admin (change this!)${NC}"
}

# Function to show monitoring setup
show_monitoring_info() {
    print_header "Monitoring Stack Information"
    echo
    echo -e "${CYAN}📈 What you can monitor:${NC}"
    echo -e "   • System metrics (CPU, RAM, disk, network)"
    echo -e "   • Docker container performance"
    echo -e "   • Service-specific metrics:"
    echo -e "     - copyparty file transfers"
    echo -e "     - FreshRSS feed updates"
    echo -e "     - Kiwix wiki access"
    echo -e "     - Transmission download/upload speeds"
    echo -e "     - Nginx request rates and response times"
    echo
    echo -e "${CYAN}🎯 Getting Started:${NC}"
    echo -e "   1. Access Grafana: http://greg-zone:9006"
    echo -e "   2. Login with admin/admin"
    echo -e "   3. Import pre-built dashboards for Docker and system monitoring"
    echo -e "   4. Create custom dashboards for your specific services"
    echo
    echo -e "${CYAN}📊 Available Dashboards:${NC}"
    echo -e "   • Docker Container Overview"
    echo -e "   • System Performance"
    echo -e "   • Network Traffic"
    echo -e "   • Disk Usage"
    echo -e "   • Service Health Checks"
}

# Function to show help
show_help() {
    echo -e "${PURPLE}GregZone Docker Services Management${NC}"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  up                     Start all services (docker-compose up -d)"
    echo "  down                   Stop all services (docker-compose down)"
    echo "  restart                Restart all services (docker-compose restart)"
    echo "  ps                     Show service status (docker-compose ps)"
    echo "  logs [service]         Show recent logs (docker-compose logs --tail=100)"
    echo "  logs -f [service]      Follow logs (docker-compose logs -f)"
    echo "  pull                   Pull latest images (docker-compose pull)"
    echo "  build                  Build services (docker-compose build)"
    echo "  update                 Pull latest images and restart (pull + up)"
    echo "  access                 Show service access information"
    echo "  monitoring             Show monitoring setup information"
    echo "  help                   Show this help message"
    echo
    echo "Examples:"
    echo "  $0 up                 # Start all services"
    echo "  $0 logs copyparty     # Show recent copyparty logs"
    echo "  $0 logs -f copyparty  # Follow copyparty logs"
    echo "  $0 update             # Pull latest images and restart"
    echo "  $0 access             # Show all service URLs"
    echo "  $0 monitoring         # Show monitoring information"
}

# Main script logic
case "${1:-help}" in
    up)
        start_services
        ;;
    down)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    ps)
        show_status
        ;;
    logs)
        if [ "$2" = "-f" ]; then
            follow_logs "$3"
        else
            show_logs "$2"
        fi
        ;;
    pull)
        pull_services
        ;;
    build)
        build_services
        ;;
    update)
        update_services
        ;;
    access)
        show_access_info
        ;;
    monitoring)
        show_monitoring_info
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac
