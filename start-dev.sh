#!/opt/homebrew/bin/bash

set -Eeuo pipefail
trap 'rc=$?; cmd=$BASH_COMMAND; pcs=("${PIPESTATUS[@]}"); echo "ERROR $rc at ${BASH_SOURCE[1]}:${BASH_LINENO[0]}: $cmd  PIPESTATUS=${pcs[*]}" >&2' ERR

#######################################
# Plants Project - Unified Development Startup
#
# Starts backend, frontend, and admin panel
# Usage: ./start-dev.sh [OPTIONS]
#
# Options:
#   --reset           Remove existing PostgreSQL container and start fresh
#   --seed            Automatically seed database after startup
#   --backend-only    Start only backend
#   --frontend-only   Start only frontend + backend
#   --admin-only      Start only admin + backend
#######################################

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly BACKEND_PORT="8080"
readonly FRONTEND_PORT="4040"
readonly ADMIN_PORT="4041"
readonly MAX_WAIT_SECONDS=60

# Parse arguments
RESET_MODE=false
AUTO_SEED=false
BACKEND_ONLY=false
FRONTEND_ONLY=false
ADMIN_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --reset)
      RESET_MODE=true
      shift
      ;;
    --seed)
      AUTO_SEED=true
      shift
      ;;
    --backend-only)
      BACKEND_ONLY=true
      shift
      ;;
    --frontend-only)
      FRONTEND_ONLY=true
      shift
      ;;
    --admin-only)
      ADMIN_ONLY=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 [--reset] [--seed] [--backend-only] [--frontend-only] [--admin-only]"
      exit 1
      ;;
  esac
done

#######################################
# Print colored message
#######################################
log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1" >&2
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

#######################################
# Check if Docker is running
#######################################
check_docker() {
  log_info "Checking Docker daemon..."

  if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running!"
    log_error "Please start Docker Desktop and try again."
    exit 1
  fi

  log_success "Docker is running"
}

#######################################
# Start backend using existing script
#######################################
start_backend() {
  log_info "Starting backend with PostgreSQL..."

  local backend_args=""
  [[ "$RESET_MODE" == true ]] && backend_args="--reset"
  [[ "$AUTO_SEED" == true ]] && backend_args="$backend_args --seed"

  # Change to backend directory and run script
  cd backend
  ./start-up-backend-with-postgres-in-docker.sh $backend_args
  cd ..

  log_success "Backend started successfully"
}

#######################################
# Wait for backend health check
#######################################
wait_for_backend_health() {
  log_info "Waiting for backend health check..."

  local health_url="http://localhost:${BACKEND_PORT}/actuator/health"
  local elapsed=0

  while [[ $elapsed -lt $MAX_WAIT_SECONDS ]]; do
    if response=$(curl -s "${health_url}" 2>/dev/null); then
      if echo "${response}" | grep -q '"status":"UP"'; then
        log_success "Backend is healthy (${elapsed}s)"
        return 0
      fi
    fi
    sleep 1
    ((++elapsed))
  done

  log_error "Backend health check failed after ${MAX_WAIT_SECONDS}s"
  exit 1
}

#######################################
# Start frontend in background
#######################################
start_frontend() {
  log_info "Starting frontend (port ${FRONTEND_PORT})..."

  cd frontend
  bun run dev > ../frontend-dev.log 2>&1 &
  local frontend_pid=$!
  cd ..

  # Wait for frontend to be ready
  local elapsed=0
  while [[ $elapsed -lt $MAX_WAIT_SECONDS ]]; do
    if curl -s "http://localhost:${FRONTEND_PORT}" > /dev/null 2>&1; then
      log_success "Frontend started (PID: ${frontend_pid})"
      return 0
    fi
    sleep 1
    ((++elapsed))
  done

  log_error "Frontend failed to start after ${MAX_WAIT_SECONDS}s"
  exit 1
}

#######################################
# Start admin in background
#######################################
start_admin() {
  log_info "Starting admin panel (port ${ADMIN_PORT})..."

  cd admin
  bun run dev > ../admin-dev.log 2>&1 &
  local admin_pid=$!
  cd ..

  # Wait for admin to be ready
  local elapsed=0
  while [[ $elapsed -lt $MAX_WAIT_SECONDS ]]; do
    if curl -s "http://localhost:${ADMIN_PORT}" > /dev/null 2>&1; then
      log_success "Admin panel started (PID: ${admin_pid})"
      return 0
    fi
    sleep 1
    ((++elapsed))
  done

  log_error "Admin panel failed to start after ${MAX_WAIT_SECONDS}s"
  exit 1
}

#######################################
# Display startup summary
#######################################
show_summary() {
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  Plants Project - Development Environment${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${GREEN}✓${NC} Backend:   http://localhost:${BACKEND_PORT}"

  if [[ "$BACKEND_ONLY" == false ]]; then
    if [[ "$ADMIN_ONLY" == false ]]; then
      echo -e "  ${GREEN}✓${NC} Frontend:  http://localhost:${FRONTEND_PORT}"
    fi
    if [[ "$FRONTEND_ONLY" == false ]]; then
      echo -e "  ${GREEN}✓${NC} Admin:     http://localhost:${ADMIN_PORT}"
    fi
  fi

  echo ""
  echo -e "  ${BLUE}Press Ctrl+C to stop all services${NC}"
  echo ""
}

#######################################
# Cleanup function to kill all child processes
#######################################
cleanup() {
  echo ""
  log_info "Stopping all services..."

  # Kill all child processes
  local pids
  pids=$(jobs -p 2>/dev/null)
  if [[ -n "$pids" ]]; then
    kill $pids 2>/dev/null || true
    wait $pids 2>/dev/null || true
  fi

  log_success "All services stopped"
  exit 0
}

# Set up trap for cleanup
trap cleanup INT TERM

#######################################
# Main execution
#######################################
main() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  Starting Plants Project${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  # Step 1: Check Docker
  check_docker

  # Step 2: Start backend
  start_backend

  # Step 3: Wait for backend health
  wait_for_backend_health

  # Step 4: Start frontend and/or admin
  if [[ "$BACKEND_ONLY" == false ]]; then
    if [[ "$ADMIN_ONLY" == false ]]; then
      start_frontend
    fi
    if [[ "$FRONTEND_ONLY" == false ]]; then
      start_admin
    fi
  fi

  # Step 5: Show summary
  show_summary

  # Step 6: Wait for Ctrl+C
  while true; do
    sleep 1
  done
}

# Run main function
main
