export type ExecutionStatus = 'running' | 'success' | 'failure' | 'skipped' | 'conditionNotMet' | 'cancelled';

export interface TriggerEvent {
  deviceId?: string;
  deviceName?: string;
  serviceName?: string;
  characteristicName?: string;
  roomName?: string;
  oldValue?: any;
  newValue?: any;
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
  blockKind: string;   // "action" | "flowControl"
  blockType: string;   // "controlDevice", "delay", "conditional", "repeat", "repeatWhile", "group", "stop", "webhook", "log", "runScene", "waitForState", "executeWorkflow"
  blockName?: string;
  status: ExecutionStatus;
  startedAt: string;   // ISO8601
  completedAt?: string; // ISO8601
  detail?: string;
  errorMessage?: string;
  nestedResults?: BlockResult[];
}

export interface WorkflowExecutionLog {
  id: string;
  workflowId: string;
  workflowName: string;
  triggeredAt: string;   // ISO8601
  completedAt?: string;  // ISO8601
  triggerEvent?: TriggerEvent;
  conditionResults?: ConditionResult[];
  blockResults: BlockResult[];
  status: ExecutionStatus;
  errorMessage?: string;
}

export interface WorkflowMetadata {
  createdBy?: string;
  tags?: string[];
  lastTriggeredAt?: string;
  totalExecutions: number;
  consecutiveFailures: number;
}

export interface WorkflowTrigger {
  type: 'deviceStateChange' | 'schedule' | 'webhook' | 'compound' | 'workflow' | 'sunEvent';
  [key: string]: any;
}

export interface Workflow {
  id: string;
  name: string;
  description?: string;
  isEnabled: boolean;
  triggers: WorkflowTrigger[];
  blocks: any[];
  metadata: WorkflowMetadata;
  createdAt: string;
  updatedAt: string;
}

export type TriggerTypeKey = WorkflowTrigger['type'];

export const TRIGGER_TYPE_LABELS: Record<TriggerTypeKey, string> = {
  deviceStateChange: 'Device',
  schedule: 'Schedule',
  webhook: 'Webhook',
  compound: 'Compound',
  workflow: 'Workflow',
  sunEvent: 'Sun Event',
};

export const TRIGGER_TYPE_ICONS: Record<TriggerTypeKey, string> = {
  deviceStateChange: 'bolt-circle-fill',
  schedule: 'clock',
  webhook: 'link-circle-fill',
  compound: 'arrows-circle-fill',
  workflow: 'play-circle-fill',
  sunEvent: 'sun',
};
