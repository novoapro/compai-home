# App Sandbox Migration Guide

This document describes the changes required to enable App Sandbox for Mac App Store submission.

## Overview

The app currently runs non-sandboxed (direct download, notarized). Enabling the App Sandbox entitlement changes how the app accesses files, network, and Keychain.

## Required Entitlements

Add to `CompAI-Home.entitlements`:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```

The following entitlements are already present and work within the sandbox:
- `com.apple.security.network.client` — outgoing connections (webhooks, AI API calls)
- `com.apple.security.network.server` — localhost MCP/REST server (Vapor)
- `com.apple.developer.homekit` — HomeKit access

## File Storage

### Automatic path scoping
When sandboxed, `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)` returns:
```
~/Library/Containers/com.mnplab.compai-home/Data/Library/Application Support/
```
instead of:
```
~/Library/Application Support/
```

The `CompAI-Home/` subdirectory inside Application Support is still valid, but the base path changes.

### Migration required
On first sandboxed launch, data from the non-sandboxed path needs to be migrated:
1. Check if `~/Library/Application Support/CompAI-Home/` exists (old path)
2. Copy contents to the sandboxed container path
3. The old path becomes inaccessible after sandboxing

**Implementation note:** The migration must happen early in app launch, before any services try to read data. Consider adding a one-time migration flag to UserDefaults.

### Files affected
- `automations.json` — automation definitions
- `device-registry.json` — device registry
- `logs.json` — state change logs
- Any future data files in the app support directory

## Keychain

### Scope change
Sandboxed apps have Keychain items scoped to their bundle ID. Existing Keychain items saved under the non-sandboxed app won't be accessible.

### Migration required
On first sandboxed launch:
1. Before enabling sandbox, store a migration bundle (or prompt user to export a backup)
2. After sandbox, user imports the backup to restore API keys, tokens, and secrets
3. Alternatively, implement a pre-sandbox migration step that copies Keychain items to a temporary file

### Keys affected (via `KeychainService`)
- `aiApiKey` — AI provider API key
- `mcpApiTokens` — MCP API authentication tokens
- `webhookSecret` — webhook signing secret
- `webhookURL` — webhook destination URL
- `appleSignInUserId`, `appleSignInEmail`, `appleSignInName` — Apple Sign In credentials

## UserDefaults

### Scope change
Sandboxed apps use a separate UserDefaults domain. All settings stored via `StorageService` (`@AppStorage`) will reset to defaults.

### Migration approach
- Export a backup before enabling sandbox
- Import the backup after first sandboxed launch
- The backup system already captures all settings, so this is the simplest migration path

## Network (Vapor Server)

### Localhost server
The MCP/REST server binds to `127.0.0.1` (or `0.0.0.0` if configured). The `com.apple.security.network.server` entitlement allows this within the sandbox.

### Potential App Review concern
Apple may question the `network.server` entitlement. Justification: the app is an MCP server that AI assistants connect to locally.

### Fallback: Unix domain socket
If Apple rejects `network.server`, consider:
- Using a Unix domain socket in the sandboxed container directory
- Clients would connect via socket path instead of TCP port
- Requires changes to Vapor configuration and all client connection code

## CloudKit

No changes needed. CloudKit access is managed through entitlements and works identically in sandbox.

## PrivacyInfo.xcprivacy

Required for App Store submission. Create `CompAI-Home/Resources/PrivacyInfo.xcprivacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

Reason code `CA92.1`: App uses UserDefaults to store app configuration/preferences.

## Migration Checklist

1. [ ] Create `PrivacyInfo.xcprivacy` manifest
2. [ ] Add `com.apple.security.app-sandbox` to entitlements
3. [ ] Implement file migration from non-sandboxed Application Support path
4. [ ] Test Keychain access — confirm items need re-entry or backup/restore
5. [ ] Test Vapor server works with `network.server` entitlement in sandbox
6. [ ] Test HomeKit access works in sandbox
7. [ ] Test CloudKit backup/restore works in sandbox
8. [ ] Test local file export/import works in sandbox (file picker should handle security scoping)
9. [ ] Submit for App Review with justification for `network.server` entitlement
10. [ ] If `network.server` rejected, implement Unix domain socket fallback
