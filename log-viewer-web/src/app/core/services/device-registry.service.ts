import { Injectable, inject, signal } from '@angular/core';
import { forkJoin } from 'rxjs';
import { ApiService } from './api.service';
import { WebSocketService } from './websocket.service';
import { RESTDevice, RESTScene, RESTService, RESTCharacteristic } from '../models/homekit-device.model';

@Injectable({ providedIn: 'root' })
export class DeviceRegistryService {
  private api = inject(ApiService);
  private ws = inject(WebSocketService);

  private readonly _devices = signal<RESTDevice[]>([]);
  private readonly _scenes = signal<RESTScene[]>([]);
  readonly isLoading = signal(false);

  readonly devices = this._devices.asReadonly();
  readonly scenes = this._scenes.asReadonly();

  private deviceMap = new Map<string, RESTDevice>();
  private sceneMap = new Map<string, RESTScene>();

  constructor() {
    this.loadRegistry();
    this.ws.devicesUpdated$.subscribe(() => this.loadRegistry());
    this.ws.reconnected$.subscribe(() => this.loadRegistry());
  }

  private loadRegistry(): void {
    this.isLoading.set(true);
    forkJoin([this.api.getDevices(), this.api.getScenes()]).subscribe({
      next: ([devices, scenes]) => {
        this._devices.set(devices);
        this._scenes.set(scenes);
        this.deviceMap = new Map(devices.map(d => [d.id, d]));
        this.sceneMap = new Map(scenes.map(s => [s.id, s]));
        this.isLoading.set(false);
      },
      error: () => {
        this.isLoading.set(false);
      }
    });
  }

  lookupDevice(deviceId: string): RESTDevice | undefined {
    return this.deviceMap.get(deviceId);
  }

  lookupService(deviceId: string, serviceId: string): RESTService | undefined {
    return this.deviceMap.get(deviceId)?.services.find(s => s.id === serviceId);
  }

  lookupCharacteristic(deviceId: string, charId: string): RESTCharacteristic | undefined {
    const device = this.deviceMap.get(deviceId);
    if (!device) return undefined;
    for (const svc of device.services) {
      const char = svc.characteristics.find(c => c.id === charId);
      if (char) return char;
    }
    return undefined;
  }

  lookupScene(sceneId: string): RESTScene | undefined {
    return this.sceneMap.get(sceneId);
  }

  /** Returns a human-readable label for a device+characteristic reference. */
  describeDeviceCharacteristic(deviceId: string, serviceId?: string, charType?: string): string {
    const device = this.lookupDevice(deviceId);
    if (!device) return deviceId;
    const parts: string[] = [device.name];
    if (device.room) parts.push(`(${device.room})`);
    if (charType) parts.push(`→ ${charType}`);
    return parts.join(' ');
  }
}
