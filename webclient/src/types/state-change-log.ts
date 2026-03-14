import type { AutomationExecutionLog } from './automation-log';

export type { AutomationExecutionLog };

export enum LogCategory {
  StateChange = 'state_change',
  WebhookError = 'webhook_error',
  WebhookCall = 'webhook_call',
  ServerError = 'server_error',
  McpCall = 'mcp_call',
  RestCall = 'rest_call',
  AutomationExecution = 'automation_execution',
  AutomationError = 'automation_error',
  SceneExecution = 'scene_execution',
  SceneError = 'scene_error',
  BackupRestore = 'backup_restore',
  AIInteraction = 'ai_interaction',
  AIInteractionError = 'ai_interaction_error',
}

export interface AIInteractionPayload {
  provider: string;
  model: string;
  operation: string;
  systemPrompt: string;
  userMessage: string;
  rawResponse?: string;
  parsedSuccessfully: boolean;
  errorMessage?: string;
  durationSeconds: number;
}

// --- Per-category log types ---

interface BaseLog {
  id: string;
  timestamp: string;
  category: LogCategory;
}

export interface DeviceStateLog extends BaseLog {
  category: LogCategory.StateChange;
  deviceId: string;
  deviceName: string;
  roomName?: string;
  serviceId?: string;
  serviceName?: string;
  characteristicType: string;
  oldValue?: unknown;
  newValue?: unknown;
  unit?: string;
}

export interface WebhookLog extends BaseLog {
  category: LogCategory.WebhookCall | LogCategory.WebhookError;
  deviceId: string;
  deviceName: string;
  roomName?: string;
  serviceId?: string;
  serviceName?: string;
  characteristicType: string;
  oldValue?: unknown;
  newValue?: unknown;
  unit?: string;
  summary: string;
  result: string;
  errorDetails?: string;
  detailedRequest?: string;
}

export interface APICallLog extends BaseLog {
  category: LogCategory.McpCall | LogCategory.RestCall;
  method: string;
  summary: string;
  result: string;
  detailedRequest?: string;
  detailedResponse?: string;
}

export interface ServerErrorLog extends BaseLog {
  category: LogCategory.ServerError;
  errorDetails: string;
}

export interface AutomationLog extends BaseLog {
  category: LogCategory.AutomationExecution | LogCategory.AutomationError;
  automationExecution: AutomationExecutionLog;
}

export interface SceneLog extends BaseLog {
  category: LogCategory.SceneExecution | LogCategory.SceneError;
  sceneId: string;
  sceneName: string;
  succeeded: boolean;
  summary?: string;
  errorDetails?: string;
}

export interface BackupRestoreLog extends BaseLog {
  category: LogCategory.BackupRestore;
  subtype: string;
  summary: string;
}

export interface AIInteractionLog extends BaseLog {
  category: LogCategory.AIInteraction | LogCategory.AIInteractionError;
  aiInteractionPayload: AIInteractionPayload;
}

export type StateChangeLog =
  | DeviceStateLog
  | WebhookLog
  | APICallLog
  | ServerErrorLog
  | AutomationLog
  | SceneLog
  | BackupRestoreLog
  | AIInteractionLog;

// --- Helper functions for polymorphic access ---

export function getLogDisplayName(log: StateChangeLog): string {
  switch (log.category) {
    case LogCategory.StateChange:
      return log.deviceName;
    case LogCategory.WebhookCall:
    case LogCategory.WebhookError:
      return log.deviceName;
    case LogCategory.McpCall:
      return 'MCP';
    case LogCategory.RestCall:
      return 'MCP Server';
    case LogCategory.ServerError:
      return 'MCP Server';
    case LogCategory.AutomationExecution:
    case LogCategory.AutomationError:
      return log.automationExecution.automationName;
    case LogCategory.SceneExecution:
    case LogCategory.SceneError:
      return log.sceneName;
    case LogCategory.BackupRestore:
      return 'Backup Restore';
    case LogCategory.AIInteraction:
    case LogCategory.AIInteractionError:
      return `AI (${log.aiInteractionPayload.model})`;
  }
}

export function getLogRoomName(log: StateChangeLog): string | undefined {
  if (log.category === LogCategory.StateChange ||
      log.category === LogCategory.WebhookCall ||
      log.category === LogCategory.WebhookError) {
    return log.roomName;
  }
  return undefined;
}

export function getLogServiceName(log: StateChangeLog): string | undefined {
  if (log.category === LogCategory.StateChange ||
      log.category === LogCategory.WebhookCall ||
      log.category === LogCategory.WebhookError) {
    return log.serviceName;
  }
  return undefined;
}

export function getLogErrorDetails(log: StateChangeLog): string | undefined {
  switch (log.category) {
    case LogCategory.WebhookError:
      return log.errorDetails;
    case LogCategory.ServerError:
      return log.errorDetails;
    case LogCategory.AutomationExecution:
    case LogCategory.AutomationError:
      return log.automationExecution.errorMessage;
    case LogCategory.SceneError:
      return log.errorDetails;
    case LogCategory.BackupRestore:
      return log.summary;
    case LogCategory.AIInteractionError:
      return log.aiInteractionPayload.errorMessage;
    default:
      return undefined;
  }
}

export function getLogSummary(log: StateChangeLog): string | undefined {
  switch (log.category) {
    case LogCategory.WebhookCall:
    case LogCategory.WebhookError:
      return log.summary;
    case LogCategory.McpCall:
    case LogCategory.RestCall:
      return log.summary;
    case LogCategory.AutomationExecution:
    case LogCategory.AutomationError:
      return log.automationExecution.triggerEvent?.triggerDescription;
    case LogCategory.SceneExecution:
    case LogCategory.SceneError:
      return log.summary;
    case LogCategory.AIInteraction:
    case LogCategory.AIInteractionError:
      return log.aiInteractionPayload.userMessage.slice(0, 200);
    default:
      return undefined;
  }
}

export function getLogResult(log: StateChangeLog): string | undefined {
  switch (log.category) {
    case LogCategory.WebhookCall:
    case LogCategory.WebhookError:
      return log.result;
    case LogCategory.McpCall:
    case LogCategory.RestCall:
      return log.result;
    default:
      return undefined;
  }
}

export function getLogDetailedRequest(log: StateChangeLog): string | undefined {
  switch (log.category) {
    case LogCategory.WebhookCall:
    case LogCategory.WebhookError:
      return log.detailedRequest;
    case LogCategory.McpCall:
    case LogCategory.RestCall:
      return log.detailedRequest;
    default:
      return undefined;
  }
}

export function getLogDetailedResponse(log: StateChangeLog): string | undefined {
  if (log.category === LogCategory.McpCall || log.category === LogCategory.RestCall) {
    return log.detailedResponse;
  }
  return undefined;
}

export function isLogExpandable(log: StateChangeLog): boolean {
  switch (log.category) {
    case LogCategory.AutomationExecution:
    case LogCategory.AutomationError:
      return true;
    case LogCategory.AIInteraction:
    case LogCategory.AIInteractionError:
      return true;
    case LogCategory.WebhookCall:
    case LogCategory.WebhookError:
      return !!(log.detailedRequest || log.summary || log.result);
    case LogCategory.McpCall:
    case LogCategory.RestCall:
      return !!(log.detailedRequest || log.detailedResponse || log.summary || log.result);
    default:
      return false;
  }
}

export function getLogSearchableText(log: StateChangeLog): string {
  const parts: string[] = [getLogDisplayName(log)];
  const room = getLogRoomName(log);
  if (room) parts.push(room);
  const service = getLogServiceName(log);
  if (service) parts.push(service);
  const error = getLogErrorDetails(log);
  if (error) parts.push(error);

  switch (log.category) {
    case LogCategory.StateChange:
      parts.push(log.characteristicType);
      break;
    case LogCategory.WebhookCall:
    case LogCategory.WebhookError:
      parts.push(log.characteristicType, log.summary, log.result);
      break;
    case LogCategory.McpCall:
    case LogCategory.RestCall:
      parts.push(log.method, log.summary, log.result);
      break;
    case LogCategory.AutomationExecution:
    case LogCategory.AutomationError: {
      const wf = log.automationExecution;
      parts.push(wf.automationName);
      if (wf.triggerEvent?.deviceName) parts.push(wf.triggerEvent.deviceName);
      if (wf.triggerEvent?.triggerDescription) parts.push(wf.triggerEvent.triggerDescription);
      if (wf.errorMessage) parts.push(wf.errorMessage);
      break;
    }
    case LogCategory.AIInteraction:
    case LogCategory.AIInteractionError: {
      const ai = log.aiInteractionPayload;
      parts.push(ai.operation, ai.provider, ai.model);
      break;
    }
    default:
      break;
  }
  return parts.join(' ').toLowerCase();
}

export interface CategoryMeta {
  label: string;
  icon: string;
  color: string;
}

export const CATEGORY_META: Record<LogCategory, CategoryMeta> = {
  [LogCategory.StateChange]: { label: 'Device Update', icon: 'bolt-circle-fill', color: 'var(--color-state-change)' },
  [LogCategory.WebhookCall]: { label: 'Webhook Call', icon: 'paperplane-circle-fill', color: 'var(--color-webhook)' },
  [LogCategory.WebhookError]: { label: 'Webhook Error', icon: 'exclamation-circle-fill', color: 'var(--color-error)' },
  [LogCategory.McpCall]: { label: 'MCP Call', icon: 'arrows-circle-fill', color: 'var(--color-mcp)' },
  [LogCategory.RestCall]: { label: 'REST Call', icon: 'link-circle-fill', color: 'var(--color-rest)' },
  [LogCategory.ServerError]: { label: 'Server Error', icon: 'exclamation-circle-fill', color: 'var(--color-error)' },
  [LogCategory.AutomationExecution]: { label: 'Automation', icon: 'bolt-circle-fill', color: 'var(--color-automation)' },
  [LogCategory.AutomationError]: { label: 'Automation Error', icon: 'exclamation-circle-fill', color: 'var(--color-error)' },
  [LogCategory.SceneExecution]: { label: 'Scene', icon: 'play-circle-fill', color: 'var(--color-scene)' },
  [LogCategory.SceneError]: { label: 'Scene Error', icon: 'exclamation-circle-fill', color: 'var(--color-error)' },
  [LogCategory.BackupRestore]: { label: 'Backup', icon: 'refresh-circle-fill', color: 'var(--color-backup)' },
  [LogCategory.AIInteraction]: { label: 'AI', icon: 'sparkles', color: 'var(--color-ai, #a855f7)' },
  [LogCategory.AIInteractionError]: { label: 'AI Error', icon: 'exclamation-circle-fill', color: 'var(--color-error)' },
};
