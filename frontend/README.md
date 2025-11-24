# Green Haven - Plant Care Guide

A comprehensive plant care companion application providing detailed guides for succulents, tropical plants, ferns, and more.

## Tech Stack

- **React** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool and dev server
- **TanStack Query** - Data fetching and caching
- **Tailwind CSS** - Styling
- **shadcn/ui** - UI component library

## Prerequisites

- [Bun](https://bun.sh/) runtime installed

## Installation

```sh
# Install dependencies
bun install
```

## Development

```sh
# Start development server (http://localhost:4040)
bun run dev
```

## Build

```sh
# Build for production
bun run build

# Preview production build
bun run preview
```

## API Configuration

The frontend proxies API requests to `http://localhost:8080` by default. Update `vite.config.ts` if your backend runs on a different port.
