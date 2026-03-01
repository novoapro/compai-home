# HK Dashboard — HomeKit MCP Web Dashboard

A React web application for monitoring and managing your [HomeKit MCP Server](../README.md). View real-time activity logs, create and edit automation workflows, and monitor device states — all from your browser.

## Features

### Activity Log
- Real-time log viewer with live WebSocket updates
- Filter by category (state changes, API calls, webhooks, workflow executions, scenes, errors)
- Filter by device, room, and date range
- Full-text search with debounced input
- Date-grouped entries with infinite scroll pagination
- Clear all logs with confirmation

### Workflow Management
- Browse all workflows with quick enable/disable toggles
- Search workflows by name
- Bulk selection mode (long-press) for batch enable, disable, or delete
- AI-powered workflow generation from natural language prompts
- Duplicate existing workflows

### Visual Workflow Editor
- Full CRUD editor for workflow definitions
- Trigger configuration: device state change, schedule (once/daily/weekly/interval), sun events, webhooks, callable workflows
- Guard condition editor with nested AND/OR/NOT logic trees
- Block editor supporting all action and flow-control block types
- Drag-and-drop block reordering via `@dnd-kit`
- Nested block navigation with breadcrumb trail
- Real-time validation with error display
- Unsaved-changes protection (browser + in-app)

### Workflow Execution History
- Per-workflow execution log list with real-time updates
- Detailed execution view: trigger event, condition results tree, block results tree
- Status indicators (running, success, failure, skipped, cancelled)
- Duration and timing information

### Settings
- Configure server address, port, HTTPS, and Bearer token
- Toggle WebSocket for real-time updates
- Adjustable polling interval
- Connection test button

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | React 19 |
| Language | TypeScript 5.7 (strict mode) |
| Build tool | Vite 6 |
| Styling | Tailwind CSS v4 |
| Routing | React Router v7 |
| Drag & drop | @dnd-kit/core + @dnd-kit/sortable |
| UI components | @headlessui/react v2 |
| Date utilities | date-fns v4 |
| State management | React Context (no external library) |
| Icons | Material Symbols Rounded (Google Fonts) |
| Fonts | Inter (UI) + JetBrains Mono (code) |

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- A running HomeKit MCP Server instance (default: `localhost:3000`)

### Development

```bash
cd log-viewer-web
npm install
npm run dev
```

The dev server starts at `http://localhost:5173` by default.

### Build for Production

```bash
npm run build
```

Output is written to `dist/`. Serve with any static file server.

### Docker

A Dockerfile and docker-compose configuration are included for containerized deployment:

```bash
docker compose up -d
```

This builds the app and serves it via nginx on port `4200` with SPA fallback routing and aggressive caching for hashed assets.

## Configuration

On first launch, open **Settings** (gear icon in the sidebar) to configure:

1. **Server Address** — hostname or IP of your HomeKit MCP Server (default: `localhost`)
2. **Port** — server port (default: `3000`)
3. **HTTPS** — enable if your server uses TLS
4. **Bearer Token** — API token from the MCP server's settings (required for all API calls)
5. **WebSocket** — enable for real-time log and workflow updates

Click **Test Connection** to verify connectivity. Settings are persisted to `localStorage`.

## Connecting to the Server

The web app communicates with the HomeKit MCP Server through two channels:

### REST API
All data fetching and mutations go through the server's REST endpoints (`/devices`, `/logs`, `/workflows`, `/scenes`, etc.). Requests include an `Authorization: Bearer <token>` header.

### WebSocket
When enabled, the app maintains a persistent WebSocket connection to `/ws?token=<token>` for real-time push updates:

| Event | Description |
|-------|-------------|
| `log` | New activity log entry |
| `workflow_log` | New workflow execution started |
| `workflow_log_updated` | Workflow execution completed/updated |
| `workflows_updated` | Workflow definitions changed |
| `devices_updated` | Device list changed |
| `logs_cleared` | All logs cleared on server |

The WebSocket connection automatically reconnects with exponential backoff (1s to 30s, up to 10 attempts).

## Project Structure

```
log-viewer-web/
├── public/              # Static assets (favicon, PWA manifest)
├── src/
│   ├── components/      # Reusable UI components
│   │   ├── blocks/      # Workflow block editor components
│   │   ├── conditions/  # Condition editor components
│   │   └── triggers/    # Trigger editor components
│   ├── contexts/        # React context providers
│   │   ├── ConfigContext.tsx      # Server connection settings
│   │   ├── WebSocketContext.tsx   # WebSocket connection manager
│   │   └── DeviceRegistryContext.tsx  # Device/scene cache
│   ├── lib/
│   │   └── api.ts       # Typed REST API client
│   ├── pages/           # Route-level page components
│   ├── types/           # TypeScript type definitions
│   ├── App.tsx          # Root component with routing
│   └── main.tsx         # Entry point
├── Dockerfile           # Multi-stage build (Node → nginx)
├── docker-compose.yml   # Container orchestration
├── nginx.conf           # Production nginx configuration
└── vite.config.ts       # Vite build configuration
```

## PWA Support

The app includes a web manifest (`manifest.webmanifest`) and is configured as a Progressive Web App:
- App name: "HK Dashboard"
- Theme color: `#FF9500`
- Standalone display mode
- Apple mobile web app capable

## License

All rights reserved.
