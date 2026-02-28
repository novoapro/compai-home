import { Component, inject, signal, OnInit, computed } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Location } from '@angular/common';
import { ApiService } from '../../core/services/api.service';
import { IconComponent } from '../../shared/components/icon.component';
import { TriggerEditorComponent } from './components/trigger-editor.component';
import { ConditionEditorComponent } from './components/condition-editor.component';
import { ConditionGroupEditorComponent } from './components/condition-group-editor.component';
import { BlockEditorComponent, newBlockDraft } from './components/block-editor.component';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatChipsModule } from '@angular/material/chips';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatExpansionModule } from '@angular/material/expansion';
import { COMMA, ENTER } from '@angular/cdk/keycodes';
import { MatChipInputEvent } from '@angular/material/chips';
import { TextFieldModule } from '@angular/cdk/text-field';
import { DeviceRegistryService } from '../../core/services/device-registry.service';
import { WorkflowDraft, WorkflowTriggerDraft, WorkflowConditionDraft, WorkflowBlockDraft, emptyDraft, newUUID } from './workflow-editor.types';
import { validateDraft } from './workflow-editor-validation';
import { draftToPayload, definitionToDraft, triggerAutoName, conditionAutoName, blockAutoName, newConditionLeaf } from './workflow-editor-utils';

// --- Panel types ---

type PanelItemKind = 'trigger' | 'condition' | 'conditionGroup' | 'block';

interface NestedPath {
  field: 'thenBlocks' | 'elseBlocks' | 'blocks' | 'conditions' | 'condition';
  index: number;
  nested?: NestedPath;
}

interface ItemPath {
  section: 'triggers' | 'conditions' | 'blocks';
  index: number;
  nested?: NestedPath;
}

interface PanelFrame {
  kind: PanelItemKind;
  path: ItemPath;
  label: string;
}

// --- Constants ---

const ACTION_TYPES = [
  { value: 'controlDevice', label: 'Control Device' },
  { value: 'runScene', label: 'Run Scene' },
  { value: 'webhook', label: 'Webhook' },
  { value: 'log', label: 'Log' },
];
const FLOW_TYPES = [
  { value: 'delay', label: 'Delay' },
  { value: 'waitForState', label: 'Wait for State' },
  { value: 'conditional', label: 'If / Else' },
  { value: 'repeat', label: 'Repeat' },
  { value: 'repeatWhile', label: 'Repeat While' },
  { value: 'group', label: 'Group' },
  { value: 'stop', label: 'Stop' },
  { value: 'executeWorkflow', label: 'Call Workflow' },
];

const TRIGGER_ICONS: Record<string, string> = {
  deviceStateChange: 'house',
  schedule: 'clock',
  sunEvent: 'sun-max-fill',
  webhook: 'link',
  workflow: 'arrow-triangle-branch',
  compound: 'arrow-triangle-branch',
};

const TRIGGER_BADGES: Record<string, string> = {
  deviceStateChange: 'Device',
  schedule: 'Schedule',
  sunEvent: 'Sun',
  webhook: 'Webhook',
  workflow: 'Callable',
  compound: 'Compound',
};

const CONDITION_ICONS: Record<string, string> = {
  deviceState: 'house',
  timeCondition: 'clock',
  sceneActive: 'sparkles',
  blockResult: 'checkmark-circle',
  and: 'arrow-triangle-branch',
  or: 'arrow-triangle-branch',
  not: 'exclamation-triangle',
};

const BLOCK_ICONS: Record<string, string> = {
  controlDevice: 'house',
  runScene: 'sparkles',
  webhook: 'link',
  log: 'doc-text',
  delay: 'clock',
  waitForState: 'clock',
  conditional: 'arrow-triangle-branch',
  repeat: 'arrow-2-squarepath',
  repeatWhile: 'arrow-2-squarepath',
  group: 'folder',
  stop: 'xmark-circle',
  executeWorkflow: 'arrow-right-circle',
};

function newTriggerDraft(): WorkflowTriggerDraft {
  return { _draftId: newUUID(), type: 'deviceStateChange', condition: { type: 'changed' } };
}

function newRootConditionGroup(): WorkflowConditionDraft {
  return { _draftId: newUUID(), type: 'and', conditions: [] };
}

@Component({
  selector: 'app-workflow-editor',
  standalone: true,
  imports: [IconComponent, TriggerEditorComponent, ConditionEditorComponent, ConditionGroupEditorComponent, BlockEditorComponent,
            MatFormFieldModule, MatInputModule, MatSlideToggleModule, MatChipsModule, MatButtonModule, MatIconModule, MatExpansionModule, TextFieldModule],
  templateUrl: './workflow-editor.component.html',
  styleUrl: './workflow-editor.component.css',
})
export class WorkflowEditorComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private location = inject(Location);
  private api = inject(ApiService);
  registry = inject(DeviceRegistryService);

  isEditMode = signal(false);
  workflowId = signal<string | null>(null);
  isLoading = signal(false);
  isSaving = signal(false);
  loadError = signal<string | null>(null);
  saveError = signal<string | null>(null);

  draft = signal<WorkflowDraft>(emptyDraft());
  tagInput = signal('');
  showSettings = signal(false);

  readonly validationErrors = computed(() => validateDraft(this.draft()));
  readonly isValid = computed(() => this.validationErrors().length === 0);

  readonly separatorKeyCodes = [ENTER, COMMA] as const;
  readonly actionTypes = ACTION_TYPES;
  readonly flowTypes = FLOW_TYPES;

  // --- Panel state ---
  panelStack = signal<PanelFrame[]>([]);
  readonly isPanelOpen = computed(() => this.panelStack().length > 0);
  readonly currentFrame = computed(() => {
    const stack = this.panelStack();
    return stack.length > 0 ? stack[stack.length - 1] : null;
  });
  readonly breadcrumbs = computed(() => this.panelStack().map(f => f.label));

  readonly currentEditItem = computed(() => {
    const frame = this.currentFrame();
    if (!frame) return null;
    return this.resolveItemAtPath(frame.path);
  });

  /** Guard conditions run before blocks, so blockResult is not applicable. */
  readonly isGuardConditionContext = computed(() => {
    const stack = this.panelStack();
    return stack.length > 0 && stack[0].path.section === 'conditions';
  });

  // --- Icon/badge lookups for summary nodes ---
  triggerIcon(t: WorkflowTriggerDraft): string { return TRIGGER_ICONS[t.type] || 'bolt'; }
  triggerBadge(t: WorkflowTriggerDraft): string { return TRIGGER_BADGES[t.type] || t.type; }
  triggerName(t: WorkflowTriggerDraft): string { return t.name || triggerAutoName(t, this.registry); }
  conditionIcon(c: WorkflowConditionDraft): string { return CONDITION_ICONS[c.type] || 'questionmark-circle'; }
  conditionName(c: WorkflowConditionDraft): string { return conditionAutoName(c, this.registry); }
  blockIcon(b: WorkflowBlockDraft): string { return BLOCK_ICONS[b.type] || 'square'; }
  blockName(b: WorkflowBlockDraft): string { return b.name || blockAutoName(b, this.registry); }

  blockChildCount(b: WorkflowBlockDraft): string | null {
    if (b.type === 'conditional') {
      const thenCount = b.thenBlocks?.length || 0;
      const elseCount = b.elseBlocks?.length || 0;
      if (thenCount + elseCount === 0) return null;
      const parts: string[] = [];
      if (thenCount > 0) parts.push(`${thenCount} then`);
      if (elseCount > 0) parts.push(`${elseCount} else`);
      return parts.join(', ');
    }
    if (['repeat', 'repeatWhile', 'group'].includes(b.type)) {
      const count = b.blocks?.length || 0;
      return count > 0 ? `${count} block${count > 1 ? 's' : ''}` : null;
    }
    return null;
  }

  // --- Panel navigation ---
  openPanel(kind: PanelItemKind, section: 'triggers' | 'conditions' | 'blocks', index: number, label: string): void {
    this.panelStack.set([{ kind, path: { section, index }, label }]);
  }

  pushPanel(kind: PanelItemKind, path: ItemPath, label: string): void {
    this.panelStack.update(stack => [...stack, { kind, path, label }]);
  }

  popPanel(): void {
    this.panelStack.update(stack => stack.length > 1 ? stack.slice(0, -1) : []);
  }

  popToLevel(level: number): void {
    this.panelStack.update(stack => stack.slice(0, level + 1));
  }

  closePanel(): void {
    this.panelStack.set([]);
  }

  // --- Path resolution ---
  private resolveItemAtPath(path: ItemPath): any {
    const d = this.draft();
    let list: any[];
    switch (path.section) {
      case 'triggers': list = d.triggers; break;
      case 'conditions': list = d.conditions; break;
      case 'blocks': list = d.blocks; break;
    }
    let item = list[path.index];
    let nested = path.nested;
    while (nested && item) {
      if (nested.field === 'condition') {
        item = item.condition;
      } else {
        item = (item[nested.field] || [])[nested.index];
      }
      nested = nested.nested;
    }
    return item;
  }

  private updateItemAtPath(path: ItemPath, updatedItem: any): void {
    this.draft.update(d => {
      const newDraft = { ...d };
      const section = path.section;
      const newList = [...(d as any)[section]];
      if (!path.nested) {
        newList[path.index] = updatedItem;
      } else {
        newList[path.index] = this.deepUpdateNested({ ...newList[path.index] }, path.nested, updatedItem);
      }
      (newDraft as any)[section] = newList;
      return newDraft;
    });
  }

  private deepUpdateNested(parent: any, nested: NestedPath, updatedItem: any): any {
    const clone = { ...parent };
    if (!nested.nested) {
      if (nested.field === 'condition') {
        clone.condition = updatedItem;
      } else {
        const arr = [...(clone[nested.field] || [])];
        arr[nested.index] = updatedItem;
        clone[nested.field] = arr;
      }
    } else {
      if (nested.field === 'condition') {
        clone.condition = this.deepUpdateNested({ ...clone.condition }, nested.nested, updatedItem);
      } else {
        const arr = [...(clone[nested.field] || [])];
        arr[nested.index] = this.deepUpdateNested({ ...arr[nested.index] }, nested.nested, updatedItem);
        clone[nested.field] = arr;
      }
    }
    return clone;
  }

  private removeItemAtPath(path: ItemPath): void {
    this.draft.update(d => {
      const newDraft = { ...d };
      const section = path.section;
      if (!path.nested) {
        (newDraft as any)[section] = (d as any)[section].filter((_: any, idx: number) => idx !== path.index);
      } else {
        const newList = [...(d as any)[section]];
        newList[path.index] = this.deepRemoveNested({ ...newList[path.index] }, path.nested);
        (newDraft as any)[section] = newList;
      }
      return newDraft;
    });
  }

  private deepRemoveNested(parent: any, nested: NestedPath): any {
    const clone = { ...parent };
    if (!nested.nested) {
      if (nested.field === 'condition') {
        clone.condition = undefined;
      } else {
        clone[nested.field] = (clone[nested.field] || []).filter((_: any, idx: number) => idx !== nested.index);
      }
    } else {
      if (nested.field === 'condition') {
        clone.condition = this.deepRemoveNested({ ...clone.condition }, nested.nested);
      } else {
        const arr = [...(clone[nested.field] || [])];
        arr[nested.index] = this.deepRemoveNested({ ...arr[nested.index] }, nested.nested);
        clone[nested.field] = arr;
      }
    }
    return clone;
  }

  // --- Panel event handlers ---
  onPanelItemChanged(item: any): void {
    const frame = this.currentFrame();
    if (!frame) return;
    this.updateItemAtPath(frame.path, item);
  }

  onPanelItemRemoved(): void {
    const frame = this.currentFrame();
    if (!frame) return;
    this.removeItemAtPath(frame.path);
    this.popPanel();
  }

  onEditNestedBlock(event: { field: string, index: number, label: string }): void {
    const frame = this.currentFrame();
    if (!frame) return;
    const nestedPath: NestedPath = { field: event.field as any, index: event.index };
    const newPath = this.appendNestedPath(frame.path, nestedPath);
    this.pushPanel('block', newPath, event.label);
  }

  onEditNestedCondition(event: { field: string, index: number, label: string }): void {
    const frame = this.currentFrame();
    if (!frame) return;
    const nestedPath: NestedPath = { field: event.field as any, index: event.index };
    const newPath = this.appendNestedPath(frame.path, nestedPath);
    // Resolve the item to determine if it's a group or leaf
    const item = this.resolveItemAtPath(newPath);
    const isGroup = item && (item.type === 'and' || item.type === 'or' ||
      (item.type === 'not' && item.condition &&
        (item.condition.type === 'and' || item.condition.type === 'or')));
    this.pushPanel(isGroup ? 'conditionGroup' : 'condition', newPath, event.label);
  }

  private appendNestedPath(basePath: ItemPath, append: NestedPath): ItemPath {
    const newPath = { ...basePath };
    if (!newPath.nested) {
      newPath.nested = append;
    } else {
      let current = { ...newPath.nested };
      newPath.nested = current;
      while (current.nested) {
        current.nested = { ...current.nested };
        current = current.nested;
      }
      current.nested = append;
    }
    return newPath;
  }

  // --- Lifecycle ---

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('workflowId');
    if (id) {
      this.isEditMode.set(true);
      this.workflowId.set(id);
      this.loadWorkflow(id);
    }
  }

  private loadWorkflow(id: string): void {
    this.isLoading.set(true);
    this.api.getWorkflow(id).subscribe({
      next: (wf) => {
        try {
          this.draft.set(definitionToDraft(wf));
          this.isLoading.set(false);
        } catch (e: any) {
          this.loadError.set(e?.message || 'Failed to parse workflow');
          this.isLoading.set(false);
        }
      },
      error: (err) => {
        this.loadError.set(err?.message || 'Failed to load workflow');
        this.isLoading.set(false);
      }
    });
  }

  // --- Draft helpers ---
  patchDraft(changes: Partial<WorkflowDraft>): void {
    this.draft.update(d => ({ ...d, ...changes }));
  }

  // --- Triggers ---
  addTrigger(): void {
    const t = newTriggerDraft();
    this.draft.update(d => ({ ...d, triggers: [...d.triggers, t] }));
    const idx = this.draft().triggers.length - 1;
    this.openPanel('trigger', 'triggers', idx, 'New Trigger');
  }

  updateTrigger(i: number, t: WorkflowTriggerDraft): void {
    this.draft.update(d => {
      const triggers = [...d.triggers];
      triggers[i] = t;
      return { ...d, triggers };
    });
  }

  removeTrigger(i: number): void {
    this.draft.update(d => ({ ...d, triggers: d.triggers.filter((_, idx) => idx !== i) }));
  }

  // --- Guard conditions (root group pattern) ---

  readonly rootConditionGroup = computed(() => {
    const conds = this.draft().conditions;
    if (conds.length === 0) return null;
    const root = conds[0];
    if (root.type === 'and' || root.type === 'or') return root;
    if (root.type === 'not' && root.condition &&
        (root.condition.type === 'and' || root.condition.type === 'or')) return root;
    return null;
  });

  conditionChildCount(root: WorkflowConditionDraft): number {
    if (root.type === 'not' && root.condition) {
      return root.condition.conditions?.length || 0;
    }
    return root.conditions?.length || 0;
  }

  conditionGroupSummary(root: WorkflowConditionDraft): string {
    const count = this.conditionChildCount(root);
    if (count === 0) return 'No conditions defined';
    return `${count} condition${count !== 1 ? 's' : ''}`;
  }

  rootOperatorLabel(root: WorkflowConditionDraft): string {
    if (root.type === 'not') {
      const inner = root.condition;
      return `NOT ${(inner?.type || 'and').toUpperCase()}`;
    }
    return root.type.toUpperCase();
  }

  openConditionGroup(): void {
    if (this.draft().conditions.length === 0) {
      const root = newRootConditionGroup();
      this.draft.update(d => ({ ...d, conditions: [root] }));
    }
    this.openPanel('conditionGroup', 'conditions', 0, 'Guard Conditions');
  }

  updateCondition(i: number, c: WorkflowConditionDraft): void {
    this.draft.update(d => {
      const conditions = [...d.conditions];
      conditions[i] = c;
      return { ...d, conditions };
    });
  }

  removeCondition(i: number): void {
    this.draft.update(d => ({ ...d, conditions: d.conditions.filter((_, idx) => idx !== i) }));
  }

  // --- Blocks ---
  addBlock(type: string): void {
    const b = newBlockDraft(type);
    this.draft.update(d => ({ ...d, blocks: [...d.blocks, b] }));
    const idx = this.draft().blocks.length - 1;
    const label = b.name || type;
    this.openPanel('block', 'blocks', idx, label);
  }

  updateBlock(i: number, b: WorkflowBlockDraft): void {
    this.draft.update(d => {
      const blocks = [...d.blocks];
      blocks[i] = b;
      return { ...d, blocks };
    });
  }

  removeBlock(i: number): void {
    this.draft.update(d => ({ ...d, blocks: d.blocks.filter((_, idx) => idx !== i) }));
  }

  moveBlock(i: number, dir: -1 | 1): void {
    this.draft.update(d => {
      const blocks = [...d.blocks];
      [blocks[i], blocks[i + dir]] = [blocks[i + dir], blocks[i]];
      return { ...d, blocks };
    });
  }

  // --- Tags ---
  onTagKeydown(event: KeyboardEvent): void {
    if (event.key === 'Enter' || event.key === ',') {
      event.preventDefault();
      this.addTag();
    }
  }

  addTag(): void {
    const tag = this.tagInput().trim().replace(/,$/, '');
    if (tag && !this.draft().tags.includes(tag)) {
      this.draft.update(d => ({ ...d, tags: [...d.tags, tag] }));
    }
    this.tagInput.set('');
  }

  addTagFromChipInput(event: MatChipInputEvent): void {
    const tag = (event.value || '').trim();
    if (tag && !this.draft().tags.includes(tag)) {
      this.draft.update(d => ({ ...d, tags: [...d.tags, tag] }));
    }
    event.chipInput.clear();
  }

  removeTag(tag: string): void {
    this.draft.update(d => ({ ...d, tags: d.tags.filter(t => t !== tag) }));
  }

  // --- Save ---
  save(): void {
    if (!this.isValid()) return;
    this.isSaving.set(true);
    this.saveError.set(null);

    const payload = draftToPayload(this.draft());
    const id = this.workflowId();
    const req = id
      ? this.api.updateWorkflowDefinition(id, payload)
      : this.api.createWorkflow(payload);

    req.subscribe({
      next: (wf) => {
        this.isSaving.set(false);
        this.router.navigate(['/workflows', wf.id, 'definition']);
      },
      error: (err) => {
        this.saveError.set(err?.message || 'Failed to save workflow');
        this.isSaving.set(false);
      }
    });
  }

  cancel(): void {
    if (this.isPanelOpen()) {
      this.closePanel();
      return;
    }
    if (window.history.length > 1) {
      this.location.back();
    } else {
      this.router.navigate(['/workflows']);
    }
  }

  patchName(e: Event): void {
    this.patchDraft({ name: (e.target as HTMLInputElement).value });
  }

  patchDescription(e: Event): void {
    this.patchDraft({ description: (e.target as HTMLTextAreaElement).value });
  }

  patchTagInput(e: Event): void {
    this.tagInput.set((e.target as HTMLInputElement).value);
  }

}
