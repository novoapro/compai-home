import { Component, input, output, computed, inject, signal } from '@angular/core';
import { WorkflowConditionDraft, newUUID } from '../workflow-editor.types';
import { DeviceRegistryService } from '../../../core/services/device-registry.service';
import { IconComponent } from '../../../shared/components/icon.component';
import { conditionAutoName, newConditionLeaf } from '../workflow-editor-utils';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatButtonModule } from '@angular/material/button';
import { MatMenuModule } from '@angular/material/menu';
import { MatIconModule } from '@angular/material/icon';

const CONDITION_ICONS: Record<string, string> = {
  deviceState: 'house',
  timeCondition: 'clock',
  sceneActive: 'sparkles',
  blockResult: 'checkmark-circle',
  and: 'arrow-triangle-branch',
  or: 'arrow-triangle-branch',
  not: 'exclamation-triangle',
};

// Material icon mapping for menu items
const LEAF_MATERIAL_ICONS: Record<string, string> = {
  deviceState: 'home',
  timeCondition: 'schedule',
  sceneActive: 'auto_awesome',
  blockResult: 'check_circle',
};

const LEAF_TYPE_OPTIONS = [
  { value: 'deviceState', label: 'Device State', icon: 'house', matIcon: 'home' },
  { value: 'timeCondition', label: 'Time Window', icon: 'clock', matIcon: 'schedule' },
  { value: 'sceneActive', label: 'Scene Active', icon: 'sparkles', matIcon: 'auto_awesome' },
  { value: 'blockResult', label: 'Block Result', icon: 'checkmark-circle', matIcon: 'check_circle' },
];

@Component({
  selector: 'app-condition-group-editor',
  standalone: true,
  imports: [IconComponent, MatButtonToggleModule, MatButtonModule, MatMenuModule, MatIconModule],
  template: `
    <div class="group-editor">
      <!-- Operator toggle -->
      <div class="operator-section">
        <span class="operator-label">Match</span>
        <mat-button-toggle-group [value]="operator()" (change)="setOperator($event.value)"
                                  class="operator-toggle">
          <mat-button-toggle value="and">All (AND)</mat-button-toggle>
          <mat-button-toggle value="or">Any (OR)</mat-button-toggle>
        </mat-button-toggle-group>
        <button mat-stroked-button class="not-btn" [class.active]="isNegated()"
                (click)="toggleNot()" type="button">
          NOT
        </button>
      </div>

      <p class="group-hint">
        @if (isNegated()) {
          All children must <strong>NOT</strong>
          {{ operator() === 'and' ? 'all be true' : 'any be true' }}
        } @else {
          {{ operator() === 'and' ? 'All conditions must be true' : 'At least one condition must be true' }}
        }
      </p>

      <!-- Children list -->
      <div class="children-list">
        @for (child of children(); track child._draftId; let i = $index) {
          <div class="child-node" (click)="onChildClick(i, child)">
            <app-icon [name]="iconFor(child)" [size]="15" class="child-icon" />
            <div class="child-info">
              <span class="child-name">{{ childName(child) }}</span>
              @if (isGroup(child)) {
                <span class="child-meta">{{ groupMeta(child) }}</span>
              }
            </div>
            <span class="child-badge" [class.logic]="isGroup(child)">
              {{ badgeFor(child) }}
            </span>
            <div class="child-actions" (click)="$event.stopPropagation()">
              <button mat-icon-button (click)="removeChild(i)" title="Remove" class="child-remove-btn">
                <mat-icon>cancel</mat-icon>
              </button>
            </div>
            <app-icon name="chevron-down" [size]="12" class="child-chevron" />
          </div>
        }

        @if (children().length === 0) {
          <div class="empty-hint">No conditions yet. Add one below.</div>
        }
      </div>

      <!-- Add buttons -->
      <div class="add-buttons">
        <button mat-stroked-button [matMenuTriggerFor]="addMenu" class="add-condition-btn">
          <mat-icon>add_circle_outline</mat-icon>
          Add Condition
        </button>
        <mat-menu #addMenu="matMenu">
          @for (opt of leafTypeOptions(); track opt.value) {
            <button mat-menu-item (click)="addLeaf(opt.value)">
              <mat-icon>{{ opt.matIcon }}</mat-icon>
              {{ opt.label }}
            </button>
          }
        </mat-menu>
        <button mat-stroked-button (click)="addGroup()" class="add-group-btn">
          <mat-icon>create_new_folder</mat-icon>
          Add Group
        </button>
      </div>
    </div>
  `,
  styles: [`
    .group-editor {
      display: flex;
      flex-direction: column;
      gap: var(--spacing-lg);
    }

    /* Operator section */
    .operator-section {
      display: flex;
      align-items: center;
      gap: var(--spacing-sm);
    }
    .operator-label {
      font-size: 10px;
      font-weight: var(--font-weight-semibold);
      color: var(--text-tertiary);
      letter-spacing: 0.04em;
      text-transform: uppercase;
      flex-shrink: 0;
    }
    .operator-toggle {
      flex: 1;
    }
    .not-btn {
      flex-shrink: 0;
      font-size: 10px !important;
      font-weight: var(--font-weight-bold) !important;
      letter-spacing: 0.04em;
      min-width: auto !important;
      padding: 0 12px !important;
    }
    .not-btn.active {
      background: color-mix(in srgb, var(--status-error) 10%, transparent) !important;
      color: var(--status-error) !important;
      border-color: color-mix(in srgb, var(--status-error) 30%, transparent) !important;
    }

    .group-hint {
      font-size: var(--font-size-xs);
      color: var(--text-tertiary);
      margin: -8px 0 0;
      line-height: 1.4;
      font-weight: var(--font-weight-regular);
    }
    .group-hint strong {
      color: var(--status-error);
      font-weight: var(--font-weight-medium);
    }

    /* Children list */
    .children-list {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }

    .child-node {
      display: flex;
      align-items: center;
      gap: var(--spacing-sm);
      padding: 11px 14px;
      border-radius: var(--radius-sm);
      cursor: pointer;
      transition: all var(--transition-fast);
      background: var(--bg-detail);
    }
    .child-node:hover {
      background: color-mix(in srgb, var(--bg-detail) 70%, var(--bg-pill));
    }
    .child-node:active {
      transform: scale(0.99);
    }

    .child-icon {
      color: var(--text-tertiary);
      flex-shrink: 0;
      opacity: 0.5;
    }

    .child-info {
      flex: 1;
      min-width: 0;
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .child-name {
      font-size: var(--font-size-sm);
      font-weight: var(--font-weight-regular);
      color: var(--text-primary);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .child-meta {
      font-size: 10px;
      color: var(--text-tertiary);
      font-weight: var(--font-weight-regular);
    }

    .child-badge {
      font-size: 9px;
      font-weight: var(--font-weight-medium);
      text-transform: uppercase;
      letter-spacing: 0.04em;
      padding: 2px 7px;
      border-radius: var(--radius-full);
      flex-shrink: 0;
      background: color-mix(in srgb, var(--tint-secondary) 6%, transparent);
      color: var(--tint-secondary);
    }
    .child-badge.logic {
      background: color-mix(in srgb, var(--color-workflow) 6%, transparent);
      color: var(--color-workflow);
    }

    .child-actions {
      display: flex;
      align-items: center;
      flex-shrink: 0;
      opacity: 0;
      transition: opacity var(--transition-fast);
    }
    .child-node:hover .child-actions { opacity: 1; }

    .child-remove-btn {
      --mdc-icon-button-icon-size: 16px;
      --mdc-icon-button-state-layer-size: 28px;
      --mdc-icon-button-icon-color: var(--status-error);
      width: 28px;
      height: 28px;
      padding: 0;
      opacity: 0.6;
    }
    .child-remove-btn:hover { opacity: 1; }

    .child-chevron {
      color: var(--text-tertiary);
      flex-shrink: 0;
      transform: rotate(-90deg);
      opacity: 0.25;
    }

    .empty-hint {
      font-size: var(--font-size-sm);
      color: var(--text-tertiary);
      text-align: center;
      padding: var(--spacing-xl) var(--spacing-sm);
      font-weight: var(--font-weight-regular);
    }

    /* Add buttons */
    .add-buttons {
      display: flex;
      gap: var(--spacing-sm);
    }
    .add-condition-btn {
      --mdc-outlined-button-label-text-color: var(--tint-main);
      --mdc-outlined-button-outline-color: color-mix(in srgb, var(--tint-main) 30%, transparent);
    }
    .add-group-btn {
      --mdc-outlined-button-label-text-color: var(--color-workflow);
      --mdc-outlined-button-outline-color: color-mix(in srgb, var(--color-workflow) 30%, transparent);
    }

    /* Mobile */
    @media (max-width: 768px) {
      .child-actions { opacity: 1; }
    }
  `]
})
export class ConditionGroupEditorComponent {
  private registry = inject(DeviceRegistryService);

  draft = input.required<WorkflowConditionDraft>();
  allowBlockResult = input(true);
  changed = output<WorkflowConditionDraft>();
  removed = output<void>();
  editNestedCondition = output<{ field: string, index: number, label: string }>();

  readonly leafTypeOptions = computed(() =>
    this.allowBlockResult()
      ? LEAF_TYPE_OPTIONS
      : LEAF_TYPE_OPTIONS.filter(o => o.value !== 'blockResult')
  );

  readonly isNegated = computed(() => this.draft().type === 'not');

  readonly innerGroup = computed((): WorkflowConditionDraft => {
    const d = this.draft();
    if (d.type === 'not' && d.condition &&
        (d.condition.type === 'and' || d.condition.type === 'or')) {
      return d.condition;
    }
    return d;
  });

  readonly operator = computed(() => this.innerGroup().type as 'and' | 'or');

  readonly children = computed(() => this.innerGroup().conditions || []);

  // --- Helpers ---

  isGroup(c: WorkflowConditionDraft): boolean {
    return c.type === 'and' || c.type === 'or' || c.type === 'not';
  }

  iconFor(c: WorkflowConditionDraft): string {
    return CONDITION_ICONS[c.type] || 'questionmark-circle';
  }

  childName(c: WorkflowConditionDraft): string {
    if (c.type === 'and' || c.type === 'or') {
      return `${c.type.toUpperCase()} Group`;
    }
    if (c.type === 'not') {
      const inner = c.condition;
      if (inner && (inner.type === 'and' || inner.type === 'or')) {
        return `NOT ${inner.type.toUpperCase()} Group`;
      }
      return `NOT ${inner ? conditionAutoName(inner, this.registry) : '...'}`;
    }
    return conditionAutoName(c, this.registry);
  }

  groupMeta(c: WorkflowConditionDraft): string {
    let count = 0;
    if (c.type === 'and' || c.type === 'or') {
      count = c.conditions?.length || 0;
    } else if (c.type === 'not' && c.condition) {
      if (c.condition.type === 'and' || c.condition.type === 'or') {
        count = c.condition.conditions?.length || 0;
      } else {
        return '1 condition';
      }
    }
    return `${count} condition${count !== 1 ? 's' : ''}`;
  }

  badgeFor(c: WorkflowConditionDraft): string {
    if (c.type === 'and' || c.type === 'or') return c.type.toUpperCase();
    if (c.type === 'not') return 'NOT';
    return c.type;
  }

  // --- Mutations ---

  private patchInner(changes: Partial<WorkflowConditionDraft>): void {
    const inner: WorkflowConditionDraft = { ...this.innerGroup(), ...changes };
    if (this.isNegated()) {
      this.changed.emit({ ...this.draft(), condition: inner });
    } else {
      this.changed.emit(inner);
    }
  }

  setOperator(op: 'and' | 'or'): void {
    if (op === this.operator()) return;
    const inner = this.innerGroup();
    const updated: WorkflowConditionDraft = {
      ...inner,
      type: op,
    };
    if (this.isNegated()) {
      this.changed.emit({ ...this.draft(), condition: updated });
    } else {
      this.changed.emit(updated);
    }
  }

  toggleNot(): void {
    if (this.isNegated()) {
      this.changed.emit({ ...this.innerGroup() });
    } else {
      this.changed.emit({
        _draftId: this.draft()._draftId,
        type: 'not',
        condition: { ...this.draft() },
      });
    }
  }

  onChildClick(index: number, child: WorkflowConditionDraft): void {
    const label = this.childName(child);
    this.editNestedCondition.emit({ field: 'conditions', index, label });
  }

  removeChild(index: number): void {
    const conditions = (this.innerGroup().conditions || []).filter((_, i) => i !== index);
    this.patchInner({ conditions });
  }

  addLeaf(type: string): void {
    const leaf = newConditionLeaf(type);
    const conditions = [...(this.innerGroup().conditions || []), leaf];
    this.patchInner({ conditions });
    const index = conditions.length - 1;
    const label = this.leafTypeOptions().find(o => o.value === type)?.label || type;
    requestAnimationFrame(() => {
      this.editNestedCondition.emit({ field: 'conditions', index, label });
    });
  }

  addGroup(): void {
    const oppositeOp = this.operator() === 'and' ? 'or' : 'and';
    const group: WorkflowConditionDraft = {
      _draftId: newUUID(),
      type: oppositeOp,
      conditions: [],
    };
    const conditions = [...(this.innerGroup().conditions || []), group];
    this.patchInner({ conditions });
    const index = conditions.length - 1;
    const label = `${oppositeOp.toUpperCase()} Group`;
    requestAnimationFrame(() => {
      this.editNestedCondition.emit({ field: 'conditions', index, label });
    });
  }
}
