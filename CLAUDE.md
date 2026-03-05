# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HomeKit MCP Server — a macOS Mac Catalyst application that exposes HomeKit devices through the Model Context Protocol (MCP). It provides real-time state monitoring, device control via MCP tools, and webhook notifications for state changes. Runs as a background menu bar app.

## Technology Stack

- **Platform**: Mac Catalyst (iOS app running on macOS)
- **Language**: Swift 5.9+, minimum macOS 13.0 (Ventura)
- **UI**: SwiftUI with MVVM + Combine
- **HTTP/MCP Server**: Vapor 4.x (SSE transport)
- **HomeKit**: Apple HomeKit framework (HMHomeManager, HMAccessoryDelegate)
- **Distribution**: Non-sandboxed, direct download (notarized for public release)

## Applications

Keep in mind that there are two applications withing this project. A swift application called HomeKitMCP and a web application called log-viewer-web. The web application is used to view the logs of the swift application. The web application is not part of the swift application. The web application is a separate application that is run independently of the swift application. The web application is run using the following command:

```bash
cd log-viewer-web
npm run dev
```

If I am referring to the web application, I will use the term "web app". If I am referring to the swift application, I will use the term "app", or "server app", or "server", or "mcp app".

## Architecture

The app has four layers:

1. **Views** (SwiftUI): MenuBarView (NSStatusItem via Catalyst), DeviceListView, LogViewerView, SettingsView
2. **ViewModels**: HomeKitViewModel, LogViewModel, SettingsViewModel — bridge services to UI via @Published properties
3. **Services**:
   - `HomeKitManager` — HMHomeManager/HMAccessoryDelegate, device discovery, state monitoring, control
   - `MCPServer` — Vapor HTTP server on localhost:3000, implements MCP JSON-RPC over SSE, exposes `homekit://devices` resource and `control_device` tool
   - `WebhookService` — actor, sends HTTP POST on state changes with exponential backoff retry (max 3)
   - `LoggingService` — actor, circular buffer of 200 state change entries, persisted to JSON in Application Support
   - `StorageService` — @AppStorage wrapper for webhook URL, MCP port, server toggle
4. **Models**: DeviceModel, ServiceModel, CharacteristicModel (with AnyCodable), StateChangeLog, StateChange

### Key Data Flows

- **State change**: HomeKit delegate → HomeKitManager → (LoggingService + WebhookService + ViewModel update)
- **MCP request**: HTTP/SSE client → Vapor MCPServer → HomeKitManager → response
- **UI interaction**: Menu bar → SwiftUI window → ViewModel → Service

## Build & Run

This is an Xcode project (Mac Catalyst). Build and run with:

```bash
xcodebuild -scheme HomeKitMCP -destination 'platform=macOS,variant=Mac Catalyst' build
```

### Dependencies

Managed via Swift Package Manager. Primary dependency:

```
vapor/vapor 4.89.0+
```

### Required Capabilities

- HomeKit entitlement must be enabled in Xcode Signing & Capabilities
- `NSHomeKitUsageDescription` in Info.plist
- `LSUIElement = true` in Info.plist (hides Dock icon)


**Very Important:**
Everytime you complete a task that changes in any way the model that we expose through the MCP server, you need to update the documentation at `API.md` file to reflect the changes.

Everytime we add something new to the workflow definition, you need to update a few things: 
- How we display and edit workflows including the new fields, blocks, and options in the MCP server app and in the web app
- update how we log them. 
- update how we expose the new update to the workflow schema externally via MCP or REST server.
- Update the documentation at `API.md` file to reflect the changes.
