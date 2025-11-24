# Plants Project

Full-stack demo showcasing Java/Spring Boot backend, React frontends, and Terraform GCP infrastructure.

## Project Structure

```
├── backend/     # Java/Spring Boot API (port 8080)
├── frontend/    # React public site (port 4040)
├── admin/       # React admin panel (port 4041)
└── infra/       # Terraform GCP infrastructure
```

See component READMEs: [backend](backend/), [frontend](frontend/), [admin](admin/), [infra](infra/)

## Prerequisites

- [Docker](https://www.docker.com/) - for PostgreSQL
- [Bun](https://bun.sh/) - JS runtime
- Java 21+ - for backend

## Local Development

```bash
./start-dev.sh          # Start all services
./start-dev.sh --seed   # Start with seed data
./start-dev.sh --reset  # Fresh PostgreSQL
```

| Service  | URL                     |
|----------|-------------------------|
| Backend  | http://localhost:8080   |
| Frontend | http://localhost:4040   |
| Admin    | http://localhost:4041   |

## Deployment

See [infra/README.md](infra/README.md) for GCP deployment instructions.
