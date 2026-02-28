// Device Registry models — matches GET /devices and GET /scenes REST responses.
// These use stable IDs that persist across HomeKit backup/restore.

export interface RESTValidValue {
  value: any;
  description?: string;
}

export interface RESTCharacteristic {
  id: string;
  name: string;
  type: string; // e.g. "On", "Brightness", "ColorTemperature"
  value?: any;
  format: string; // "bool", "int", "float", "string", "uint8", etc.
  units?: string;
  permissions: string[];
  minValue?: number;
  maxValue?: number;
  stepValue?: number;
  validValues?: RESTValidValue[];
}

export interface RESTService {
  id: string;
  name: string;
  type: string; // e.g. "Lightbulb", "Switch", "Thermostat"
  characteristics: RESTCharacteristic[];
}

export interface RESTDevice {
  id: string;
  name: string;
  room?: string;
  isReachable: boolean;
  services: RESTService[];
}

export interface RESTScene {
  id: string;
  name: string;
  type: string;
  isExecuting: boolean;
  actionCount: number;
}
