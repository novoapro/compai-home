import { Component, inject, signal, OnInit, OnDestroy } from '@angular/core';
import { Location } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { Subscription } from 'rxjs';
import { ApiService } from '../../core/services/api.service';
import { WebSocketService } from '../../core/services/websocket.service';
import { MobileTopBarService } from '../../core/services/mobile-topbar.service';
import { WorkflowDefinition } from '../../core/models/workflow-definition.model';
import { IconComponent } from '../../shared/components/icon.component';
import { DefinitionTriggerComponent } from './components/definition-trigger.component';
import { DefinitionConditionComponent } from './components/definition-condition.component';
import { DefinitionBlockTreeComponent } from './components/definition-block-tree.component';
import { PullToRefreshDirective } from '../../shared/directives/pull-to-refresh.directive';

@Component({
  selector: 'app-workflow-definition',
  standalone: true,
  imports: [
    IconComponent, PullToRefreshDirective,
    DefinitionTriggerComponent, DefinitionConditionComponent, DefinitionBlockTreeComponent,
  ],
  templateUrl: './workflow-definition.component.html',
  styleUrl: './workflow-definition.component.css',
})
export class WorkflowDefinitionComponent implements OnInit, OnDestroy {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private location = inject(Location);
  private api = inject(ApiService);
  private wsService = inject(WebSocketService);
  private topBar = inject(MobileTopBarService);
  private wsSub?: Subscription;

  workflow = signal<WorkflowDefinition | null>(null);
  isLoading = signal(true);
  isDuplicating = signal(false);
  error = signal<string | null>(null);

  private workflowId = '';

  onPullRefresh = (): void => {
    this.loadWorkflow();
  };

  ngOnInit(): void {
    this.workflowId = this.route.snapshot.paramMap.get('workflowId') || '';
    this.loadWorkflow();

    this.wsSub = this.wsService.workflowsUpdated$.subscribe(workflows => {
      if (workflows.some(w => w.id === this.workflowId)) {
        this.loadWorkflow();
      }
    });
  }

  ngOnDestroy(): void {
    this.wsSub?.unsubscribe();
  }

  private loadWorkflow(): void {
    if (!this.workflowId) return;

    this.isLoading.set(true);
    this.error.set(null);

    this.api.getWorkflow(this.workflowId).subscribe({
      next: (wf) => {
        this.workflow.set(wf);
        this.isLoading.set(false);
        this.topBar.set(wf.name, null, false);
      },
      error: (err) => {
        this.error.set(err?.message || 'Failed to load workflow');
        this.isLoading.set(false);
      }
    });
  }

  goBack(): void {
    if (window.history.length > 1) {
      this.location.back();
    } else {
      this.router.navigate(['/workflows']);
    }
  }

  editWorkflow(): void {
    this.router.navigate(['/workflows', this.workflowId, 'edit']);
  }

  deleteWorkflow(): void {
    const wf = this.workflow();
    if (!wf) return;
    if (!confirm(`Delete "${wf.name}"? This cannot be undone.`)) return;
    this.api.deleteWorkflow(this.workflowId).subscribe({
      next: () => {
        this.router.navigate(['/workflows']);
      },
      error: (err) => {
        this.error.set(err?.message || 'Failed to delete workflow');
      }
    });
  }

  viewExecutionLogs(): void {
    this.router.navigate(['/workflows', this.workflowId]);
  }

  duplicateWorkflow(): void {
    const wf = this.workflow();
    if (!wf) return;

    this.isDuplicating.set(true);
    const copy: Partial<WorkflowDefinition> = {
      name: `${wf.name} (Copy)`,
      description: wf.description,
      isEnabled: false,
      continueOnError: wf.continueOnError,
      retriggerPolicy: wf.retriggerPolicy,
      metadata: wf.metadata,
      triggers: wf.triggers,
      conditions: wf.conditions,
      blocks: wf.blocks,
    };

    this.api.createWorkflow(copy).subscribe({
      next: (created) => {
        this.isDuplicating.set(false);
        this.router.navigate(['/workflows', created.id, 'edit']);
      },
      error: (err) => {
        this.isDuplicating.set(false);
        this.error.set(err?.message || 'Failed to duplicate workflow');
      }
    });
  }

  formatDate(iso: string): string {
    const d = new Date(iso);
    return d.toLocaleString(undefined, {
      month: 'short', day: 'numeric', year: '2-digit',
      hour: '2-digit', minute: '2-digit',
    });
  }
}
