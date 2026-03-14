export type ExecutionStatus = 'running' | 'success' | 'failure' | 'skipped' | 'conditionNotMet' | 'cancelled';

export interface TriggerEvent {
  deviceId?: string;
  deviceName?: string;
  serviceName?: string;
  characteristicName?: string;
  roomName?: string;
  oldValue?: unknown;
  newValue?: unknown;
  triggerDescription?: string;
}

export interface ConditionResult {
  conditionDescription: string;
  passed: boolean;
  subResults?: ConditionResult[];
  logicOperator?: string;
}

export interface BlockResult {
  id: string;
  blockIndex: number;
  blockKind: string;
  blockType: string;
  blockName?: string;
  status: ExecutionStatus;
  startedAt: string;
  completedAt?: string;
  detail?: string;
  errorMessage?: string;
  nestedResults?: BlockResult[];
}

export interface AutomationExecutionLog {
  id: string;
  automationId: string;
  automationName: string;
  triggeredAt: string;
  completedAt?: string;
  triggerEvent?: TriggerEvent;
  conditionResults?: ConditionResult[];
  blockResults: BlockResult[];
  status: ExecutionStatus;
  errorMessage?: string;
}

export interface AutomationMetadata {
  createdBy?: string;
  tags?: string[];
  lastTriggeredAt?: string;
  totalExecutions: number;
  consecutiveFailures: number;
}

export interface AutomationTrigger {
  type: 'deviceStateChange' | 'schedule' | 'webhook' | 'automation' | 'sunEvent';
  [key: string]: unknown;
}

export interface Automation {
  id: string;
  name: string;
  description?: string;
  isEnabled: boolean;
  triggers: AutomationTrigger[];
  blocks: unknown[];
  metadata: AutomationMetadata;
  createdAt: string;
  updatedAt: string;
}

export type TriggerTypeKey = AutomationTrigger['type'];

export const TRIGGER_TYPE_LABELS: Record<TriggerTypeKey, string> = {
  deviceStateChange: 'Device',
  schedule: 'Schedule',
  webhook: 'Webhook',
  automation: 'Automation',
  sunEvent: 'Sun Event',
};

export const TRIGGER_TYPE_ICONS: Record<TriggerTypeKey, string> = {
  deviceStateChange: 'bolt-circle-fill',
  schedule: 'clock',
  webhook: 'link-circle-fill',
  automation: 'play-circle-fill',
  sunEvent: 'sun',
};
