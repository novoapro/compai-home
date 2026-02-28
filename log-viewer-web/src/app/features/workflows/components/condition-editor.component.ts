import { Component, input, output, computed, inject } from '@angular/core';
import { WorkflowConditionDraft } from '../workflow-editor.types';
import { DevicePickerComponent, DevicePickerValue } from './device-picker.component';
import { DeviceRegistryService } from '../../../core/services/device-registry.service';
import { conditionAutoName, parseSmartValue, newConditionLeaf } from '../workflow-editor-utils';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatInputModule } from '@angular/material/input';

const CONDITION_LEAF_TYPES = [
  { value: 'deviceState', label: 'Device State' },
  { value: 'timeCondition', label: 'Time Window' },
  { value: 'sceneActive', label: 'Scene Active' },
  { value: 'blockResult', label: 'Block Result' },
];

const COMPARISON_OPS = [
  { value: 'equals', label: 'Equals' },
  { value: 'notEquals', label: 'Not Equals' },
  { value: 'greaterThan', label: 'Greater Than' },
  { value: 'lessThan', label: 'Less Than' },
  { value: 'greaterThanOrEqual', label: 'Greater Than or Equal' },
  { value: 'lessThanOrEqual', label: 'Less Than or Equal' },
];

const TIME_MODES = [
  { value: 'between', label: 'Between two times' },
  { value: 'before', label: 'Before a time' },
  { value: 'after', label: 'After a time' },
  { value: 'daytime', label: 'Daytime (sunrise-sunset)' },
  { value: 'nighttime', label: 'Nighttime (sunset-sunrise)' },
];

@Component({
  selector: 'app-condition-editor',
  standalone: true,
  imports: [DevicePickerComponent, MatFormFieldModule, MatSelectModule, MatInputModule],
  template: `
    <div class="condition-editor">
      <div class="condition-body">
        <!-- Type selector -->
        <mat-form-field appearance="fill" class="type-field">
          <mat-label>Condition Type</mat-label>
          <mat-select [value]="draft().type" (selectionChange)="onTypeChange($event.value)">
            @for (t of conditionLeafTypes(); track t.value) {
              <mat-option [value]="t.value">{{ t.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>

        <!-- Per-type fields -->
        @switch (draft().type) {
          @case ('deviceState') {
            <app-device-picker
              [initialDeviceId]="draft().deviceId"
              [initialServiceId]="draft().serviceId"
              [initialCharId]="draft().characteristicId"
              (changed)="onDevicePicked($event)"
            />
            <div class="field-row">
              <mat-form-field appearance="fill">
                <mat-label>Comparison</mat-label>
                <mat-select [value]="draft().comparison?.type || 'equals'"
                            (selectionChange)="onComparisonTypeChange($event.value)">
                  @for (op of comparisonOps; track op.value) {
                    <mat-option [value]="op.value">{{ op.label }}</mat-option>
                  }
                </mat-select>
              </mat-form-field>
              <mat-form-field appearance="fill">
                <mat-label>Value</mat-label>
                <input matInput
                       [value]="comparisonValueStr()"
                       (change)="onComparisonValueChange($event)"
                       placeholder="e.g. true, 50" />
              </mat-form-field>
            </div>
          }

          @case ('timeCondition') {
            <mat-form-field appearance="fill">
              <mat-label>Mode</mat-label>
              <mat-select [value]="draft().mode || 'between'"
                          (selectionChange)="patchMode($event.value)">
                @for (m of timeModes; track m.value) {
                  <mat-option [value]="m.value">{{ m.label }}</mat-option>
                }
              </mat-select>
            </mat-form-field>
            @if (draft().mode === 'between' || draft().mode === 'after') {
              <mat-form-field appearance="fill">
                <mat-label>Start Time</mat-label>
                <input matInput type="time"
                       [value]="timeStr(draft().startTime)"
                       (change)="onTimeChange($event, 'startTime')" />
              </mat-form-field>
            }
            @if (draft().mode === 'between' || draft().mode === 'before') {
              <mat-form-field appearance="fill">
                <mat-label>End Time</mat-label>
                <input matInput type="time"
                       [value]="timeStr(draft().endTime)"
                       (change)="onTimeChange($event, 'endTime')" />
              </mat-form-field>
            }
          }

          @case ('sceneActive') {
            <mat-form-field appearance="fill">
              <mat-label>Scene</mat-label>
              <mat-select [value]="draft().sceneId || ''"
                          (selectionChange)="patchSceneId($event.value)">
                <mat-option value="">-- Select scene --</mat-option>
                @for (scene of registry.scenes(); track scene.id) {
                  <mat-option [value]="scene.id">{{ scene.name }}</mat-option>
                }
              </mat-select>
            </mat-form-field>
            <mat-form-field appearance="fill">
              <mat-label>State</mat-label>
              <mat-select [value]="draft().isActive !== false ? 'true' : 'false'"
                          (selectionChange)="patchIsActive($event.value)">
                <mat-option value="true">Is Active</mat-option>
                <mat-option value="false">Is Not Active</mat-option>
              </mat-select>
            </mat-form-field>
          }

          @case ('blockResult') {
            <mat-form-field appearance="fill">
              <mat-label>Scope</mat-label>
              <mat-select [value]="draft().blockResultScope?.scope || 'any'"
                          (selectionChange)="patchBlockResultScope($event.value)">
                <mat-option value="any">Any block</mat-option>
                <mat-option value="specific">Specific block</mat-option>
              </mat-select>
            </mat-form-field>
            @if (draft().blockResultScope?.scope === 'specific') {
              <mat-form-field appearance="fill">
                <mat-label>Block ID</mat-label>
                <input matInput
                       [value]="draft().blockResultScope?.blockId || ''"
                       (change)="patchBlockResultBlockId($event)"
                       placeholder="Block ID or label" />
              </mat-form-field>
            }
            <mat-form-field appearance="fill">
              <mat-label>Expected Status</mat-label>
              <mat-select [value]="draft().expectedStatus || 'success'"
                          (selectionChange)="patchExpectedStatus($event.value)">
                <mat-option value="success">Success</mat-option>
                <mat-option value="failure">Failure</mat-option>
                <mat-option value="skipped">Skipped</mat-option>
              </mat-select>
            </mat-form-field>
          }
        }
      </div>
    </div>
  `,
  styles: [`
    .condition-editor {
      display: flex;
    }
    .condition-body {
      flex: 1;
      min-width: 0;
      display: flex;
      flex-direction: column;
      gap: 2px;
    }
    .type-field {
      --mdc-filled-text-field-container-color: color-mix(in srgb, var(--tint-main) 8%, transparent);
      --mdc-filled-text-field-focus-active-indicator-color: var(--tint-main);
      --mat-select-enabled-trigger-text-color: var(--tint-main);
      --mat-select-focused-arrow-color: var(--tint-main);
      --mdc-filled-text-field-label-text-color: var(--tint-main);
      --mdc-filled-text-field-focus-label-text-color: var(--tint-main);
    }
    .field-row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: var(--spacing-sm);
    }
    mat-form-field {
      width: 100%;
    }
  `]
})
export class ConditionEditorComponent {
  registry = inject(DeviceRegistryService);

  draft = input.required<WorkflowConditionDraft>();
  allowBlockResult = input(true);
  changed = output<WorkflowConditionDraft>();
  removed = output<void>();

  readonly conditionLeafTypes = computed(() =>
    this.allowBlockResult()
      ? CONDITION_LEAF_TYPES
      : CONDITION_LEAF_TYPES.filter(t => t.value !== 'blockResult')
  );
  readonly comparisonOps = COMPARISON_OPS;
  readonly timeModes = TIME_MODES;

  readonly autoDescription = computed(() => conditionAutoName(this.draft(), this.registry));
  readonly comparisonValueStr = computed(() => {
    const v = (this.draft().comparison as any)?.value;
    return v !== undefined ? String(v) : '';
  });

  patch(changes: Partial<WorkflowConditionDraft>): void {
    this.changed.emit({ ...this.draft(), ...changes });
  }

  onTypeChange(type: string): void {
    this.changed.emit(newConditionLeaf(type));
  }

  onDevicePicked(val: DevicePickerValue): void {
    this.patch({ deviceId: val.deviceId, serviceId: val.serviceId, characteristicId: val.characteristicId });
  }

  onComparisonTypeChange(type: string): void {
    const current = { ...(this.draft().comparison ?? { type: 'equals', value: true }) } as any;
    current.type = type;
    this.patch({ comparison: current });
  }

  onComparisonValueChange(event: Event): void {
    const raw = (event.target as HTMLInputElement).value;
    const current = { ...(this.draft().comparison ?? { type: 'equals' }) } as any;
    current.value = parseSmartValue(raw);
    this.patch({ comparison: current });
  }

  onTimeChange(event: Event, field: 'startTime' | 'endTime'): void {
    const val = (event.target as HTMLInputElement).value;
    const [hourStr, minuteStr] = val.split(':');
    this.patch({ [field]: { hour: +hourStr, minute: +minuteStr } });
  }

  patchMode(value: string): void {
    this.patch({ mode: value });
  }

  patchSceneId(value: string): void {
    this.patch({ sceneId: value });
  }

  patchIsActive(value: string): void {
    this.patch({ isActive: value === 'true' });
  }

  patchBlockResultScope(value: string): void {
    this.patch({
      blockResultScope: value === 'specific'
        ? { scope: 'specific', blockId: this.draft().blockResultScope?.blockId || '' }
        : { scope: 'any' }
    });
  }

  patchBlockResultBlockId(e: Event): void {
    this.patch({ blockResultScope: { scope: 'specific', blockId: (e.target as HTMLInputElement).value } });
  }

  patchExpectedStatus(value: string): void {
    this.patch({ expectedStatus: value });
  }

  timeStr(t: { hour: number; minute: number } | undefined): string {
    if (!t) return '08:00';
    return `${String(t.hour).padStart(2, '0')}:${String(t.minute).padStart(2, '0')}`;
  }
}
