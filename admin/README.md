# Green Haven Admin Panel

Admin panel for managing plant groups, plants, and images for the Green Haven plant care application.

## Tech Stack

- React 18
- TypeScript
- Vite
- Bun (package manager & runtime)
- React Router
- Tailwind CSS
- shadcn/ui components
- React Query (TanStack Query)

## Development

```bash
# Install dependencies
bun install

# Run development server (http://localhost:4041)
bun run dev

# Build for production
bun run build

# Preview production build
bun run preview

# Lint code
bun run lint
```

## Quick Start with All Services

To run backend + frontend + admin together:

```bash
cd /path/to/plants-project
./start-dev.sh
```

This starts all three services and displays their URLs.

Options:
- `--seed` - Seed the database with initial data
- `--reset` - Reset PostgreSQL container and start fresh
- `--backend-only` - Start only backend
- `--frontend-only` - Start only frontend + backend
- `--admin-only` - Start only admin + backend

## Structure

- `/src/pages` - Page components (PlantGroups, Plants, Images)
- `/src/components` - Reusable React components
- `/src/components/ui` - shadcn/ui components
- `/src/lib` - Utility functions
- `/src/hooks` - Custom React hooks
- `/src/types` - TypeScript type definitions

## API Integration

The admin panel communicates with the backend API via Vite proxy during development. In production, it uses the configured `VITE_API_BASE_URL` environment variable.
