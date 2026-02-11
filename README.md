# HomeKit MCP Server

A macOS menu bar app that exposes your Apple HomeKit devices through the [Model Context Protocol (MCP)](https://modelcontextprotocol.io). Connect AI assistants like Claude to your smart home — query device states, control accessories, and receive real-time webhook notifications when things change.

## Features

- **MCP Server** — JSON-RPC over SSE on `localhost:3000`, exposing a `homekit://devices` resource and a `control_device` tool
- **Real-time monitoring** — Observes HomeKit accessory state changes via `HMAccessoryDelegate`
- **Device control** — Turn lights on/off, adjust brightness, set thermostats, lock/unlock doors, and more through MCP tool calls
- **Webhook notifications** — HTTP POST callbacks on state changes with exponential backoff retry
- **State logging** — Circular buffer of recent state changes, persisted to disk
- **Menu bar app** — Runs unobtrusively in the macOS menu bar (no Dock icon)

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+
- HomeKit-compatible accessories configured in the Apple Home app
- An Apple Developer account (for HomeKit entitlement)

## Getting Started

### Build

```bash
xcodebuild -scheme HomeKitMCP -destination 'platform=macOS,variant=Mac Catalyst' build
```

Or open `HomeKitMCP.xcodeproj` in Xcode and build with **Cmd+B**.

### Run

1. Launch the app — it appears as an icon in the menu bar
2. Grant HomeKit access when prompted
3. The MCP server starts automatically on `localhost:3000`

### Connect an MCP Client

Point any MCP-compatible client at the SSE endpoint:

```
http://localhost:3000/sse
```

The server exposes:

| Type     | Name               | Description                          |
|----------|--------------------|--------------------------------------|
| Resource | `homekit://devices` | Lists all discovered HomeKit devices |
| Tool     | `control_device`    | Controls a device characteristic     |

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌───────────────┐
│  MCP Client │────▶│  MCPServer   │────▶│ HomeKitManager│
│  (Claude)   │◀────│  (Vapor SSE) │◀────│  (HMHome)     │
└─────────────┘     └──────────────┘     └───────┬───────┘
                                                 │
                    ┌──────────────┐              │
                    │WebhookService│◀─────────────┤
                    └──────────────┘              │
                    ┌──────────────┐              │
                    │LoggingService│◀─────────────┘
                    └──────────────┘
```

**Layers:**

1. **Views** (SwiftUI) — DeviceListView, LogViewerView, SettingsView
2. **ViewModels** — Bridge services to UI via `@Published` properties
3. **Services** — HomeKitManager, MCPServer, WebhookService, LoggingService, StorageService
4. **Models** — DeviceModel, ServiceModel, CharacteristicModel, StateChangeLog

## Tech Stack

- **Platform**: Mac Catalyst (iOS app running on macOS)
- **Language**: Swift 5.9
- **UI**: SwiftUI + Combine (MVVM)
- **HTTP Server**: [Vapor 4](https://vapor.codes)
- **Smart Home**: Apple HomeKit framework

## License

All rights reserved.
