import { Component, inject, output, input, signal, computed, effect } from '@angular/core';
import { DeviceRegistryService } from '../../../core/services/device-registry.service';
import { RESTDevice, RESTService } from '../../../core/models/homekit-device.model';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';

export interface DevicePickerValue {
  deviceId: string;
  serviceId: string;
  characteristicId: string;
}

interface PickerOption {
  id: string;
  label: string;
  secondary?: string;
}

@Component({
  selector: 'app-device-picker',
  standalone: true,
  imports: [MatFormFieldModule, MatInputModule, MatAutocompleteModule, MatIconModule, MatButtonModule],
  template: `
    <div class="device-picker">
      <!-- Device -->
      <mat-form-field appearance="fill" class="picker-field">
        <mat-label>Device</mat-label>
        <input matInput
               [matAutocomplete]="deviceAuto"
               [value]="deviceInputValue()"
               (input)="onDeviceQueryChange($event)"
               (focus)="onDeviceFocus()"
               (blur)="onDeviceBlur()"
               placeholder="Search devices..." />
        @if (selectedDeviceId()) {
          <button matSuffix mat-icon-button (click)="clearDevice($event)" type="button" class="clear-btn">
            <mat-icon>cancel</mat-icon>
          </button>
        }
        <mat-autocomplete #deviceAuto="matAutocomplete"
                          (optionSelected)="selectDevice($event.option.value)"
                          class="picker-panel">
          @for (opt of filteredDevices(); track opt.id) {
            <mat-option [value]="opt.id">
              <span class="opt-label">{{ opt.label }}</span>
              @if (opt.secondary) {
                <span class="opt-secondary">{{ opt.secondary }}</span>
              }
            </mat-option>
          }
          @if (filteredDevices().length === 0) {
            <mat-option disabled>No devices found</mat-option>
          }
        </mat-autocomplete>
      </mat-form-field>

      <!-- Service -->
      @if (selectedDevice()) {
        <mat-form-field appearance="fill" class="picker-field">
          <mat-label>Service</mat-label>
          <input matInput
                 [matAutocomplete]="serviceAuto"
                 [value]="serviceInputValue()"
                 (input)="onServiceQueryChange($event)"
                 (focus)="onServiceFocus()"
                 (blur)="onServiceBlur()"
                 placeholder="Search services..." />
          @if (selectedServiceId()) {
            <button matSuffix mat-icon-button (click)="clearService($event)" type="button" class="clear-btn">
              <mat-icon>cancel</mat-icon>
            </button>
          }
          <mat-autocomplete #serviceAuto="matAutocomplete"
                            (optionSelected)="selectService($event.option.value)"
                            class="picker-panel">
            @for (opt of filteredServices(); track opt.id) {
              <mat-option [value]="opt.id">
                <span class="opt-label">{{ opt.label }}</span>
                @if (opt.secondary) {
                  <span class="opt-secondary">{{ opt.secondary }}</span>
                }
              </mat-option>
            }
            @if (filteredServices().length === 0) {
              <mat-option disabled>No services found</mat-option>
            }
          </mat-autocomplete>
        </mat-form-field>
      }

      <!-- Characteristic -->
      @if (selectedService()) {
        <mat-form-field appearance="fill" class="picker-field">
          <mat-label>Characteristic</mat-label>
          <input matInput
                 [matAutocomplete]="charAuto"
                 [value]="charInputValue()"
                 (input)="onCharQueryChange($event)"
                 (focus)="onCharFocus()"
                 (blur)="onCharBlur()"
                 placeholder="Search characteristics..." />
          @if (selectedCharId()) {
            <button matSuffix mat-icon-button (click)="clearChar($event)" type="button" class="clear-btn">
              <mat-icon>cancel</mat-icon>
            </button>
          }
          <mat-autocomplete #charAuto="matAutocomplete"
                            (optionSelected)="selectChar($event.option.value)"
                            class="picker-panel">
            @for (opt of filteredChars(); track opt.id) {
              <mat-option [value]="opt.id">
                <span class="opt-label">{{ opt.label }}</span>
                @if (opt.secondary) {
                  <span class="opt-secondary">{{ opt.secondary }}</span>
                }
              </mat-option>
            }
            @if (filteredChars().length === 0) {
              <mat-option disabled>No characteristics found</mat-option>
            }
          </mat-autocomplete>
        </mat-form-field>
      }
    </div>
  `,
  styles: [`
    .device-picker {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }
    .picker-field {
      width: 100%;
    }
    .clear-btn {
      --mdc-icon-button-icon-size: 18px;
      --mdc-icon-button-state-layer-size: 28px;
      width: 28px;
      height: 28px;
      padding: 0;
    }
    .clear-btn mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
      color: var(--text-tertiary);
    }
    .opt-label {
      margin-right: 8px;
    }
    .opt-secondary {
      font-size: var(--font-size-xs);
      color: var(--text-tertiary);
    }
  `]
})
export class DevicePickerComponent {
  registry = inject(DeviceRegistryService);

  // Inputs for pre-filling (edit mode)
  initialDeviceId = input<string | undefined>();
  initialServiceId = input<string | undefined>();
  initialCharId = input<string | undefined>();

  changed = output<DevicePickerValue>();

  selectedDeviceId = signal('');
  selectedServiceId = signal('');
  selectedCharId = signal('');

  // Search queries
  deviceQuery = signal('');
  serviceQuery = signal('');
  charQuery = signal('');

  // Track whether user is actively searching
  deviceFocused = signal(false);
  serviceFocused = signal(false);
  charFocused = signal(false);

  readonly selectedDevice = computed((): RESTDevice | undefined =>
    this.registry.devices().find(d => d.id === this.selectedDeviceId())
  );

  readonly selectedService = computed((): RESTService | undefined =>
    this.selectedDevice()?.services.find(s => s.id === this.selectedServiceId())
  );

  // Display labels for selected items
  readonly selectedDeviceLabel = computed(() => {
    const dev = this.selectedDevice();
    if (!dev) return '';
    return dev.name + (dev.room ? ` (${dev.room})` : '');
  });

  readonly selectedServiceLabel = computed(() => {
    const svc = this.selectedService();
    return svc ? (svc.name || svc.type) : '';
  });

  readonly selectedCharLabel = computed(() => {
    const svc = this.selectedService();
    if (!svc) return '';
    const char = svc.characteristics.find(c => c.id === this.selectedCharId());
    return char ? (char.name || char.id) : '';
  });

  // Input values: show query when focused, label when not
  readonly deviceInputValue = computed(() =>
    this.deviceFocused() ? this.deviceQuery() : this.selectedDeviceLabel()
  );
  readonly serviceInputValue = computed(() =>
    this.serviceFocused() ? this.serviceQuery() : this.selectedServiceLabel()
  );
  readonly charInputValue = computed(() =>
    this.charFocused() ? this.charQuery() : this.selectedCharLabel()
  );

  // Filtered option lists
  readonly filteredDevices = computed((): PickerOption[] => {
    const q = this.deviceQuery().toLowerCase();
    return this.registry.devices()
      .filter(d => !q || d.name.toLowerCase().includes(q) || (d.room || '').toLowerCase().includes(q))
      .map(d => ({ id: d.id, label: d.name, secondary: d.room || undefined }));
  });

  readonly filteredServices = computed((): PickerOption[] => {
    const dev = this.selectedDevice();
    if (!dev) return [];
    const q = this.serviceQuery().toLowerCase();
    return dev.services
      .filter(s => !q || (s.name || s.type).toLowerCase().includes(q))
      .map(s => ({ id: s.id, label: s.name || s.type, secondary: s.name ? s.type : undefined }));
  });

  readonly filteredChars = computed((): PickerOption[] => {
    const svc = this.selectedService();
    if (!svc) return [];
    const q = this.charQuery().toLowerCase();
    return svc.characteristics
      .filter(c => !q || (c.name || c.id).toLowerCase().includes(q) || c.type.toLowerCase().includes(q))
      .map(c => ({ id: c.id, label: c.name || c.id, secondary: c.type !== c.name ? c.type : undefined }));
  });

  private syncInitials = effect(() => {
    const devId = this.initialDeviceId();
    const svcId = this.initialServiceId();
    const charId = this.initialCharId();
    if (devId !== undefined) this.selectedDeviceId.set(devId);
    if (svcId !== undefined) this.selectedServiceId.set(svcId);
    if (charId !== undefined) this.selectedCharId.set(charId);
  }, { allowSignalWrites: true });

  // --- Focus/Blur ---
  onDeviceFocus(): void { this.deviceFocused.set(true); this.deviceQuery.set(''); }
  onDeviceBlur(): void { this.deviceFocused.set(false); this.deviceQuery.set(''); }
  onServiceFocus(): void { this.serviceFocused.set(true); this.serviceQuery.set(''); }
  onServiceBlur(): void { this.serviceFocused.set(false); this.serviceQuery.set(''); }
  onCharFocus(): void { this.charFocused.set(true); this.charQuery.set(''); }
  onCharBlur(): void { this.charFocused.set(false); this.charQuery.set(''); }

  // --- Query handlers ---
  onDeviceQueryChange(event: Event): void {
    this.deviceQuery.set((event.target as HTMLInputElement).value);
  }
  onServiceQueryChange(event: Event): void {
    this.serviceQuery.set((event.target as HTMLInputElement).value);
  }
  onCharQueryChange(event: Event): void {
    this.charQuery.set((event.target as HTMLInputElement).value);
  }

  // --- Selection ---
  selectDevice(id: string): void {
    this.selectedDeviceId.set(id);
    this.selectedServiceId.set('');
    this.selectedCharId.set('');
    this.emit();
  }

  selectService(id: string): void {
    this.selectedServiceId.set(id);
    this.selectedCharId.set('');
    this.emit();
  }

  selectChar(id: string): void {
    this.selectedCharId.set(id);
    this.emit();
  }

  clearDevice(event: Event): void {
    event.stopPropagation();
    this.selectedDeviceId.set('');
    this.selectedServiceId.set('');
    this.selectedCharId.set('');
    this.emit();
  }

  clearService(event: Event): void {
    event.stopPropagation();
    this.selectedServiceId.set('');
    this.selectedCharId.set('');
    this.emit();
  }

  clearChar(event: Event): void {
    event.stopPropagation();
    this.selectedCharId.set('');
    this.emit();
  }

  private emit(): void {
    this.changed.emit({
      deviceId: this.selectedDeviceId(),
      serviceId: this.selectedServiceId(),
      characteristicId: this.selectedCharId(),
    });
  }
}
