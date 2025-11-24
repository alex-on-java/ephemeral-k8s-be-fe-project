#!/opt/homebrew/bin/bash

set -Eeuo pipefail
trap 'rc=$?; cmd=$BASH_COMMAND; pcs=("${PIPESTATUS[@]}"); echo "ERROR $rc at ${BASH_SOURCE[1]}:${BASH_LINENO[0]}: $cmd  PIPESTATUS=${pcs[*]}" >&2' ERR

#######################################
# Plants Backend Startup Script
#
# Starts PostgreSQL in Docker and Spring Boot backend
# Usage: ./start-up-backend-with-postgres-in-docker.sh [OPTIONS]
#
# Options:
#   --reset    Remove existing PostgreSQL container and start fresh
#   --seed     Automatically seed database after startup
#######################################

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly CONTAINER_NAME="plants-postgres"
readonly POSTGRES_IMAGE="postgres:16"
readonly POSTGRES_PORT="5432"
readonly POSTGRES_DB="plants_db"
readonly POSTGRES_USER="plants_user"
readonly POSTGRES_PASSWORD="plants_pass"
readonly VOLUME_NAME="plants_data"

readonly BACKEND_PORT="8080"
readonly BACKEND_LOG="backend-startup.log"
readonly MAX_WAIT_SECONDS=60

# Parse arguments
RESET_MODE=false
AUTO_SEED=false

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
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 [--reset] [--seed]"
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
# Check if Docker daemon is running
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
# Handle existing PostgreSQL container
#######################################
handle_postgres_container() {
  log_info "Checking for existing PostgreSQL container..."

  if docker ps -a --filter "name=${CONTAINER_NAME}" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    if [[ "$RESET_MODE" == true ]]; then
      log_warning "Removing existing container (--reset mode)..."
      docker rm -f "${CONTAINER_NAME}" > /dev/null 2>&1
      log_success "Container removed"
      return 1 # Need to create new
    else
      # Check if running
      if docker ps --filter "name=${CONTAINER_NAME}" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_success "Container already running"
        return 0 # Already running
      else
        log_info "Starting existing container..."
        docker start "${CONTAINER_NAME}" > /dev/null
        log_success "Container started"
        return 0 # Started
      fi
    fi
  fi

  return 1 # Need to create new
}

#######################################
# Start PostgreSQL container
#######################################
start_postgres() {
  log_info "Creating PostgreSQL container..."

  docker run -d \
    --name "${CONTAINER_NAME}" \
    -e POSTGRES_DB="${POSTGRES_DB}" \
    -e POSTGRES_USER="${POSTGRES_USER}" \
    -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    -p "${POSTGRES_PORT}:5432" \
    -v "${VOLUME_NAME}:/var/lib/postgresql/data" \
    "${POSTGRES_IMAGE}" > /dev/null

  log_success "PostgreSQL container created"
}

#######################################
# Wait for PostgreSQL to be ready
#######################################
wait_for_postgres() {
  log_info "Waiting for PostgreSQL to be ready..."

  local elapsed=0
  while [[ $elapsed -lt $MAX_WAIT_SECONDS ]]; do
    if docker exec "${CONTAINER_NAME}" pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" > /dev/null 2>&1; then
      log_success "PostgreSQL is ready (${elapsed}s)"
      return 0
    fi
    sleep 1
    ((++elapsed))
  done

  log_error "PostgreSQL failed to become ready after ${MAX_WAIT_SECONDS}s"
  docker logs "${CONTAINER_NAME}" | tail -20
  exit 1
}

#######################################
# Stop any running backend processes
#######################################
stop_existing_backend() {
  log_info "Checking for existing backend processes..."

  # Check if port 8080 is in use
  if lsof -ti:"${BACKEND_PORT}" > /dev/null 2>&1; then
    log_warning "Port ${BACKEND_PORT} is in use, stopping processes..."
    lsof -ti:"${BACKEND_PORT}" | xargs kill -9 2>/dev/null || true
    sleep 2
    log_success "Existing processes stopped"
  else
    log_success "No existing backend processes"
  fi
}

#######################################
# Start Spring Boot backend
#######################################
start_backend() {
  log_info "Starting Spring Boot backend..."

  # Remove old log file
  [[ -f "${BACKEND_LOG}" ]] && trash "${BACKEND_LOG}" 2>/dev/null || rm -f "${BACKEND_LOG}"

  # Start backend in background
  ./gradlew bootRun --args='--spring.profiles.active=local' > "${BACKEND_LOG}" 2>&1 &
  local backend_pid=$!

  log_info "Backend starting (PID: ${backend_pid}), waiting for startup..."

  # Tail log and wait for startup message
  local elapsed=0
  while [[ $elapsed -lt $MAX_WAIT_SECONDS ]]; do
    if [[ -f "${BACKEND_LOG}" ]]; then
      if grep -q "Started PlantsBackendApplication" "${BACKEND_LOG}"; then
        local startup_time
        startup_time=$(grep "Started PlantsBackendApplication" "${BACKEND_LOG}" | sed -n 's/.*in \([0-9.]*\) seconds.*/\1/p')
        log_success "Backend started in ${startup_time}s (PID: ${backend_pid})"
        return 0
      fi

      # Check for errors
      if grep -qi "error\|exception\|failed" "${BACKEND_LOG}"; then
        log_error "Backend startup failed! Check ${BACKEND_LOG} for details"
        tail -30 "${BACKEND_LOG}"
        exit 1
      fi
    fi

    sleep 1
    ((++elapsed))
  done

  log_error "Backend failed to start after ${MAX_WAIT_SECONDS}s"
  log_error "Check ${BACKEND_LOG} for details"
  tail -30 "${BACKEND_LOG}"
  exit 1
}

#######################################
# Verify backend health
#######################################
check_backend_health() {
  log_info "Verifying backend health..."

  local health_url="http://localhost:${BACKEND_PORT}/actuator/health"
  local response

  if response=$(curl -s "${health_url}" 2>/dev/null); then
    if echo "${response}" | grep -q '"status":"UP"'; then
      log_success "Health check passed"
      return 0
    fi
  fi

  log_error "Health check failed"
  log_error "Response: ${response:-<no response>}"
  exit 1
}

#######################################
# Seed database (optional)
#######################################
seed_database() {
  log_info "Seeding database..."

  local seed_url="http://localhost:${BACKEND_PORT}/api/admin/seed"
  local response
  local http_code

  response=$(curl -s -w "\n%{http_code}" -X POST "${seed_url}" -H "Content-Type: application/json")
  http_code=$(echo "${response}" | tail -n1)
  local body
  body=$(echo "${response}" | sed '$d')

  if [[ "${http_code}" == "200" ]]; then
    log_success "Database seeded successfully"
    echo "${body}" | grep -o '"message":"[^"]*"' | sed 's/"message":"\(.*\)"/  → \1/'
  else
    log_error "Database seeding failed (HTTP ${http_code})"
    echo "${body}"
    exit 1
  fi
}

#######################################
# Display startup summary
#######################################
show_summary() {
  local container_id
  container_id=$(docker ps --filter "name=${CONTAINER_NAME}" --format '{{.ID}}')

  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  Plants Backend - Startup Complete${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${BLUE}PostgreSQL:${NC}"
  echo -e "    Container: ${CONTAINER_NAME} (${container_id:0:12})"
  echo -e "    Database:  ${POSTGRES_DB}"
  echo -e "    Port:      ${POSTGRES_PORT}"
  echo ""
  echo -e "  ${BLUE}Backend:${NC}"
  echo -e "    URL:       http://localhost:${BACKEND_PORT}"
  echo -e "    Health:    http://localhost:${BACKEND_PORT}/actuator/health"
  echo -e "    Logs:      ${BACKEND_LOG}"
  echo ""
  echo -e "  ${BLUE}Useful Commands:${NC}"
  echo -e "    View logs:        tail -f ${BACKEND_LOG}"
  echo -e "    Seed database:    curl -X POST http://localhost:${BACKEND_PORT}/api/admin/seed"
  echo -e "    Reset database:   curl -X POST http://localhost:${BACKEND_PORT}/api/admin/reset"
  echo -e "    Stop backend:     lsof -ti:${BACKEND_PORT} | xargs kill"
  echo -e "    Stop PostgreSQL:  docker stop ${CONTAINER_NAME}"
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

#######################################
# Main execution
#######################################
main() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  Starting Plants Backend Environment${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  # Step 1: Check Docker
  check_docker

  # Step 2: Handle PostgreSQL container
  if ! handle_postgres_container; then
    start_postgres
  fi

  # Step 3: Wait for PostgreSQL
  wait_for_postgres

  # Step 4: Stop existing backend
  stop_existing_backend

  # Step 5: Start backend
  start_backend

  # Step 6: Health check
  check_backend_health

  # Step 7: Auto-seed if requested
  if [[ "$AUTO_SEED" == true ]]; then
    seed_database
  fi

  # Step 8: Show summary
  show_summary
}

# Run main function
main
