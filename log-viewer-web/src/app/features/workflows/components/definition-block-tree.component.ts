import { Component, input, computed, inject, signal } from '@angular/core';
import { WorkflowBlockDef } from '../../../core/models/workflow-definition.model';
import {
  blockTypeIcon, formatBlockType, isBlockingType,
  formatDuration, formatComparisonOperator,
} from '../../../core/utils/workflow-definition-utils';
import { IconComponent } from '../../../shared/components/icon.component';
import { DeviceRegistryService } from '../../../core/services/device-registry.service';

const DEPTH_COLORS = [
  'var(--depth-0)',
  'var(--depth-1)',
  'var(--depth-2)',
  'var(--depth-3)',
  'var(--depth-4)',
];

@Component({
  selector: 'app-definition-block-tree',
  standalone: true,
  imports: [IconComponent, DefinitionBlockTreeComponent],
  template: `
    <div class="block-node">
      <div class="block-row" [class.collapsible]="hasChildren()" (click)="toggle()">
        @for (i of depthRange(); track i) {
          <div class="connector-line" [style.background-color]="depthColor(i)"></div>
        }

        @if (hasChildren()) {
          <span class="chevron" [class.collapsed]="collapsed()">
            <app-icon name="chevron-down" [size]="12" />
          </span>
        }

        <span class="type-icon" [style.color]="typeColor()">
          <app-icon [name]="icon()" [size]="16" />
        </span>

        <div class="block-info">
          <div class="block-header">
            <span class="block-name">{{ displayName() }}</span>
            @if (isBlocking()) {
              <span class="blocking-badge">
                <app-icon name="hourglass" [size]="10" />
                Blocking
              </span>
            }
          </div>
          @if (detailText()) {
            <div class="block-detail">{{ detailText() }}</div>
          }
          @if (collapsed() && hasChildren()) {
            <span class="collapsed-hint">{{ totalChildCount() }} nested</span>
          }
        </div>
      </div>

      @if (!collapsed()) {
        <!-- Then / Else for conditional -->
        @if (block().type === 'conditional') {
          @if (thenBlocks().length > 0) {
            <div class="sub-label" [style.padding-left.px]="(depth() + 1) * 14 + 6">Then</div>
            @for (b of thenBlocks(); track $index) {
              <app-definition-block-tree [block]="b" [depth]="depth() + 1" />
            }
          }
          @if (elseBlocks().length > 0) {
            <div class="sub-label" [style.padding-left.px]="(depth() + 1) * 14 + 6">Else</div>
            @for (b of elseBlocks(); track $index) {
              <app-definition-block-tree [block]="b" [depth]="depth() + 1" />
            }
          }
        }

        <!-- Nested blocks for repeat, repeatWhile, group -->
        @if (nestedBlocks().length > 0 && block().type !== 'conditional') {
          @for (b of nestedBlocks(); track $index) {
            <app-definition-block-tree [block]="b" [depth]="depth() + 1" />
          }
        }
      }
    </div>
  `,
  styles: [`
    .block-node {
      font-size: var(--font-size-sm);
    }
    .block-row {
      display: flex;
      align-items: flex-start;
      gap: 6px;
      padding: 6px 0;
    }
    .connector-line {
      width: 2px;
      min-height: 24px;
      align-self: stretch;
      opacity: 0.3;
      border-radius: 1px;
      flex-shrink: 0;
      margin-left: 6px;
    }
    .type-icon {
      display: flex;
      align-items: center;
      flex-shrink: 0;
      margin-top: 1px;
    }
    .block-info {
      flex: 1;
      min-width: 0;
    }
    .block-header {
      display: flex;
      align-items: center;
      gap: var(--spacing-sm);
    }
    .block-name {
      font-weight: var(--font-weight-semibold);
      color: var(--text-primary);
    }
    .blocking-badge {
      display: inline-flex;
      align-items: center;
      gap: 3px;
      font-size: 10px;
      font-weight: var(--font-weight-bold);
      padding: 1px 6px;
      border-radius: 4px;
      background: color-mix(in srgb, var(--status-warning) 15%, transparent);
      color: var(--status-warning);
      flex-shrink: 0;
    }
    .block-detail {
      color: var(--text-secondary);
      margin-top: 2px;
      line-height: 1.4;
    }
    .sub-label {
      font-size: var(--font-size-xs);
      font-weight: var(--font-weight-bold);
      color: var(--text-tertiary);
      text-transform: uppercase;
      letter-spacing: 0.08em;
      padding: 4px 0 0;
    }
    .block-row.collapsible { cursor: pointer; border-radius: var(--radius-xs); }
    .block-row.collapsible:hover { background: color-mix(in srgb, var(--text-tertiary) 6%, transparent); }
    .chevron {
      display: flex;
      align-items: center;
      flex-shrink: 0;
      color: var(--text-tertiary);
      transition: transform 0.15s ease;
      margin-top: 1px;
    }
    .chevron.collapsed { transform: rotate(-90deg); }
    .collapsed-hint {
      font-size: var(--font-size-xs);
      color: var(--text-tertiary);
      font-style: italic;
    }
  `]
})
export class DefinitionBlockTreeComponent {
  private registry = inject(DeviceRegistryService);

  block = input.required<WorkflowBlockDef>();
  depth = input(0);
  collapsed = signal(false);

  readonly depthRange = computed(() => Array.from({ length: this.depth() }, (_, i) => i));

  readonly hasChildren = computed(() => {
    const b = this.block();
    if (b.type === 'conditional') return (b.thenBlocks?.length ?? 0) > 0 || (b.elseBlocks?.length ?? 0) > 0;
    return (b.blocks?.length ?? 0) > 0;
  });

  readonly totalChildCount = computed(() => {
    const b = this.block();
    if (b.type === 'conditional') return (b.thenBlocks?.length ?? 0) + (b.elseBlocks?.length ?? 0);
    return b.blocks?.length ?? 0;
  });

  toggle(): void {
    if (this.hasChildren()) this.collapsed.update(v => !v);
  }

  readonly icon = computed(() => blockTypeIcon(this.block().type, this.block().block));

  readonly typeColor = computed(() => {
    const b = this.block();
    if (isBlockingType(b.type)) return 'var(--status-warning)';
    if (b.block === 'flowControl') return this.depthColor(this.depth());
    return 'var(--tint-main)';
  });

  readonly isBlocking = computed(() => isBlockingType(this.block().type));

  readonly displayName = computed(() => {
    const b = this.block();
    if (b.name) return b.name;
    if (b.type === 'controlDevice' && b.deviceId) {
      return this.registry.lookupDevice(b.deviceId)?.name || b.deviceId;
    }
    if (b.type === 'runScene' && b.sceneId) {
      return this.registry.lookupScene(b.sceneId)?.name || b.sceneId;
    }
    if (b.type === 'group' && b.label) return b.label;
    return formatBlockType(b.type);
  });

  readonly detailText = computed(() => {
    const b = this.block();
    switch (b.type) {
      case 'controlDevice': {
        const parts: string[] = [];
        if (b.deviceId) {
          const device = this.registry.lookupDevice(b.deviceId);
          if (device?.room) parts.push(device.room);
        }
        if (b.characteristicId) {
          const char = b.deviceId ? this.registry.lookupCharacteristic(b.deviceId, b.characteristicId) : undefined;
          const charLabel = char?.name || b.characteristicId;
          const val = b.value !== undefined ? ` → ${formatVal(b.value)}` : '';
          parts.push(`${charLabel}${val}`);
        }
        return parts.join(' · ') || undefined;
      }
      case 'webhook': {
        return `${(b.method || 'POST').toUpperCase()} ${b.url || ''}`;
      }
      case 'log': return b.message || undefined;
      case 'runScene': return undefined; // name shown via displayName()
      case 'delay': return b.seconds !== undefined ? formatDuration(b.seconds) : undefined;
      case 'waitForState': {
        const parts: string[] = [];
        if (b.deviceId) {
          const device = this.registry.lookupDevice(b.deviceId);
          parts.push(device?.name || b.deviceId);
        }
        if (b.characteristicId && b.condition) {
          const char = b.deviceId ? this.registry.lookupCharacteristic(b.deviceId, b.characteristicId) : undefined;
          const charLabel = char?.name || b.characteristicId;
          parts.push(`${charLabel} ${formatComparisonOperator(b.condition)}`);
        }
        if (b.timeoutSeconds) parts.push(`Timeout: ${formatDuration(b.timeoutSeconds)}`);
        return parts.join(' · ') || undefined;
      }
      case 'conditional': return undefined;
      case 'repeat': {
        const parts: string[] = [`${b.count || 0} times`];
        if (b.delayBetweenSeconds) parts.push(`${formatDuration(b.delayBetweenSeconds)} between`);
        return parts.join(', ');
      }
      case 'repeatWhile': {
        const parts: string[] = [];
        if (b.maxIterations) parts.push(`Max ${b.maxIterations} iterations`);
        if (b.delayBetweenSeconds) parts.push(`${formatDuration(b.delayBetweenSeconds)} between`);
        return parts.join(', ') || undefined;
      }
      case 'group': return undefined;
      case 'return':
      case 'stop': {
        const parts: string[] = [];
        if (b.outcome) parts.push(b.outcome);
        if (b.message) parts.push(b.message);
        return parts.join(': ') || undefined;
      }
      case 'executeWorkflow': {
        const mode = b.executionMode || 'inline';
        const modeLabel = mode === 'inline' ? 'Inline (Wait)' : mode === 'parallel' ? 'Parallel' : 'Delegate';
        return `Mode: ${modeLabel}`;
      }
      default: return undefined;
    }
  });

  readonly thenBlocks = computed(() => this.block().thenBlocks || []);
  readonly elseBlocks = computed(() => this.block().elseBlocks || []);

  readonly nestedBlocks = computed(() => {
    return this.block().blocks || [];
  });

  depthColor(i: number): string {
    return DEPTH_COLORS[i % DEPTH_COLORS.length];
  }
}

function formatVal(val: any): string {
  if (val === undefined || val === null) return '?';
  if (typeof val === 'boolean') return val ? 'On' : 'Off';
  if (typeof val === 'object' && val.value !== undefined) return formatVal(val.value);
  return String(val);
}
