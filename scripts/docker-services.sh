#!/bin/sh

# Docker Services Management Script
# Manages all Docker services using docker-compose

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root where docker-compose.yml is located
cd "$PROJECT_ROOT"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found in $PROJECT_ROOT"
        exit 1
    fi
    
    # Check if .env file exists
    if [ ! -f ".env" ]; then
        print_error ".env file not found. Please create it with your environment variables."
        print_error "Copy .env.example and set COPYPARTY_CLOUDFLARED_TOKEN"
        exit 1
    fi
    
    # Source .env file to check for required variables
    set -a
    source .env
    set +a
    
    if [ -z "$COPYPARTY_CLOUDFLARED_TOKEN" ] || [ "$COPYPARTY_CLOUDFLARED_TOKEN" = "your_token_here" ]; then
        print_error "COPYPARTY_CLOUDFLARED_TOKEN is not set in .env file"
        print_error "Please set it to your actual Cloudflare tunnel token"
        exit 1
    fi
    
    # Check external dependencies
    if [ ! -d "/Volumes/Elements" ]; then
        print_error "/Volumes/Elements directory does not exist"
        print_error "Please make sure your external drive is mounted"
        exit 1
    fi
    
    if [ ! -d "/Users/greg.linscheid/Desktop/Mac Vault" ]; then
        print_error "/Users/greg.linscheid/Desktop/Mac Vault directory does not exist"
        exit 1
    fi
    
    ZIM_DIR="/Volumes/Elements/Local Vault/media/zim"
    if [ ! -d "$ZIM_DIR" ]; then
        print_warning "ZIM directory does not exist at '$ZIM_DIR'"
        print_warning "Kiwix service may not work properly"
    elif [ ! "$(find "$ZIM_DIR" -name "*.zim" -type f | head -n 1)" ]; then
        print_warning "No .zim files found in '$ZIM_DIR'"
        print_warning "Kiwix service will start but won't serve any content"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 {start|stop|restart|status|logs|pull}"
    echo ""
    echo "Commands:"
    echo "  start    - Start all services"
    echo "  stop     - Stop all services"
    echo "  restart  - Restart all services"
    echo "  status   - Show status of all services"
    echo "  logs     - Show logs for all services (use Ctrl+C to exit)"
    echo "  pull     - Pull latest images for all services"
    echo ""
    echo "Individual services:"
    echo "  start <service>   - Start specific service (copyparty-tunnel, freshrss, kiwix-server)"
    echo "  stop <service>    - Stop specific service"
    echo "  logs <service>    - Show logs for specific service"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 stop copyparty-tunnel"
    echo "  $0 logs freshrss"
}

# Function to start services
start_services() {
    local service="$1"
    
    check_prerequisites
    
    if [ -n "$service" ]; then
        print_status "Starting $service..."
        docker-compose up -d "$service"
    else
        print_status "Starting all services..."
        docker-compose up -d
    fi
    
    print_success "Services started!"
    show_service_urls
}

# Function to stop services
stop_services() {
    local service="$1"
    
    if [ -n "$service" ]; then
        print_status "Stopping $service..."
        docker-compose stop "$service"
    else
        print_status "Stopping all services..."
        docker-compose stop
    fi
    
    print_success "Services stopped!"
}

# Function to restart services
restart_services() {
    local service="$1"
    
    check_prerequisites
    
    if [ -n "$service" ]; then
        print_status "Restarting $service..."
        docker-compose restart "$service"
    else
        print_status "Restarting all services..."
        docker-compose restart
    fi
    
    print_success "Services restarted!"
    show_service_urls
}

# Function to show service status
show_status() {
    print_status "Service status:"
    docker-compose ps
}

# Function to show logs
show_logs() {
    local service="$1"
    
    if [ -n "$service" ]; then
        print_status "Showing logs for $service (press Ctrl+C to exit)..."
        docker-compose logs -f "$service"
    else
        print_status "Showing logs for all services (press Ctrl+C to exit)..."
        docker-compose logs -f
    fi
}

# Function to pull latest images
pull_images() {
    print_status "Pulling latest images..."
    docker-compose pull
    print_success "Images updated!"
}

# Function to show service URLs
show_service_urls() {
    echo ""
    print_success "Services are available at:"
    echo "  • Copyparty: http://localhost:8080 (via port 3923)"
    echo "  • Copyparty (public): https://copyparty.greglinscheid.com"
    echo "  • FreshRSS: http://localhost:49153"
    echo "  • FreshRSS (public): https://freshrss.greglinscheid.com"
    echo "  • Kiwix: http://localhost:8473"
    echo "  • Kiwix (public): https://kiwix.greglinscheid.com"
    echo ""
}

# Main script logic
case "$1" in
    start)
        start_services "$2"
        ;;
    stop)
        stop_services "$2"
        ;;
    restart)
        restart_services "$2"
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    pull)
        pull_images
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
