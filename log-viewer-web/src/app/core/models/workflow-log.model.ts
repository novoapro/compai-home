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

export interface Workflow {
  id: string;
  name: string;
  isEnabled: boolean;
  [key: string]: any;
}
