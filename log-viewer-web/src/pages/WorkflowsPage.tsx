import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router';
import { Icon } from '@/components/Icon';
import { EmptyState } from '@/components/EmptyState';
import { ConfirmDialog } from '@/components/ConfirmDialog';
import { AIGenerateDialog } from '@/components/AIGenerateDialog';
import { WorkflowCard } from '@/features/workflows/WorkflowCard';
import { useApi } from '@/hooks/useApi';
import { useWebSocket } from '@/contexts/WebSocketContext';
import type { Workflow } from '@/types/workflow-log';
import './WorkflowsPage.css';

export function WorkflowsPage() {
  const api = useApi();
  const ws = useWebSocket();
  const navigate = useNavigate();

  const [workflows, setWorkflows] = useState<Workflow[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');

  const loadWorkflows = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const wfs = await api.getWorkflows();
      setWorkflows(wfs);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to load workflows');
    } finally {
      setIsLoading(false);
    }
  }, [api]);

  useEffect(() => {
    loadWorkflows();
  }, [loadWorkflows]);

  // WebSocket: real-time workflow list updates
  useEffect(() => {
    const unsub = ws.onWorkflowsUpdated((updated) => {
      setWorkflows(updated);
    });
    return unsub;
  }, [ws]);

  const filteredWorkflows = useMemo(() => {
    if (!searchQuery.trim()) return workflows;
    const q = searchQuery.toLowerCase();
    return workflows.filter((wf) => wf.name.toLowerCase().includes(q));
  }, [workflows, searchQuery]);

  const toggleWorkflow = useCallback(async (workflow: Workflow, enabled: boolean) => {
    // Optimistic update
    setWorkflows(prev => prev.map(w => w.id === workflow.id ? { ...w, isEnabled: enabled } : w));

    try {
      const updated = await api.updateWorkflow(workflow.id, { isEnabled: enabled });
      setWorkflows(prev => prev.map(w => w.id === updated.id ? updated : w));
    } catch {
      // Revert
      setWorkflows(prev => prev.map(w => w.id === workflow.id ? { ...w, isEnabled: !enabled } : w));
      setError('Failed to update workflow');
    }
  }, [api]);

  const [deleteTarget, setDeleteTarget] = useState<Workflow | null>(null);
  const [showAIDialog, setShowAIDialog] = useState(false);

  const handleGenerate = useCallback(async (prompt: string) => {
    return api.generateWorkflow(prompt);
  }, [api]);

  const handleViewWorkflow = useCallback((id: string) => {
    setShowAIDialog(false);
    navigate(`/workflows/${id}/definition`);
  }, [navigate]);

  const confirmDelete = useCallback(async () => {
    if (!deleteTarget) return;
    try {
      await api.deleteWorkflow(deleteTarget.id);
      setWorkflows(prev => prev.filter(w => w.id !== deleteTarget.id));
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to delete workflow');
    }
    setDeleteTarget(null);
  }, [api, deleteTarget]);

  return (
    <div className="wf-list-page">
      {/* Desktop page header */}
      <div className="wf-page-header">
        <h1 className="wf-page-title">Workflows</h1>
        {isLoading && <span className="wf-loading-dot" />}
        <div className="wf-search-wrap desktop">
          <Icon name="magnifyingglass" size={13} className="wf-search-icon" />
          <input
            className="wf-search-input"
            type="text"
            placeholder="Search workflows..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          {searchQuery && (
            <button className="wf-search-clear" onClick={() => setSearchQuery('')} type="button">
              <Icon name="xmark-circle-fill" size={14} />
            </button>
          )}
        </div>
        <button className="wf-ai-btn" onClick={() => setShowAIDialog(true)}>
          <Icon name="sparkles" size={15} />
          Generate with AI
        </button>
        <button className="wf-new-btn" onClick={() => navigate('/workflows/new')}>
          <Icon name="plus" size={15} />
          New Workflow
        </button>
      </div>

      {/* Mobile toolbar: search + icon CTAs */}
      <div className="wf-mobile-toolbar">
        <div className="wf-search-wrap">
          <Icon name="magnifyingglass" size={13} className="wf-search-icon" />
          <input
            className="wf-search-input"
            type="text"
            placeholder="Search workflows..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          {searchQuery && (
            <button className="wf-search-clear" onClick={() => setSearchQuery('')} type="button">
              <Icon name="xmark-circle-fill" size={14} />
            </button>
          )}
        </div>
        <button className="wf-toolbar-icon-btn ai" onClick={() => setShowAIDialog(true)} title="Generate with AI">
          <Icon name="sparkles" size={17} />
        </button>
        <button className="wf-toolbar-icon-btn primary" onClick={() => navigate('/workflows/new')} title="New Workflow">
          <Icon name="plus" size={17} />
        </button>
      </div>

      {/* Error */}
      {error && (
        <div className="wf-error-banner animate-fade-in">
          <Icon name="exclamation-triangle" size={16} />
          <span>{error}</span>
        </div>
      )}

      {/* Skeleton Loading */}
      {isLoading && workflows.length === 0 && (
        <div className="wf-skeleton-list">
          {Array.from({ length: 10 }, (_, i) => (
            <div key={i} className="wf-skeleton-card skeleton" style={{ animationDelay: `${i * 100}ms` }} />
          ))}
        </div>
      )}

      {/* Empty */}
      {!isLoading && workflows.length === 0 && !error && (
        <EmptyState
          icon="bolt-circle-fill"
          title="No workflows"
          message="No workflows yet. Tap New Workflow to create your first automation."
        />
      )}

      {/* Search no results */}
      {!isLoading && workflows.length > 0 && filteredWorkflows.length === 0 && searchQuery.trim() && (
        <EmptyState
          icon="magnifyingglass"
          title="No matches"
          message={`No workflows matching "${searchQuery}".`}
        />
      )}

      {/* Workflow card list */}
      {filteredWorkflows.length > 0 && (
        <div className="wf-card-list">
          {filteredWorkflows.map((wf, i) => (
            <WorkflowCard
              key={wf.id}
              workflow={wf}
              index={i}
              onToggleEnabled={(enabled) => toggleWorkflow(wf, enabled)}
              onDelete={() => setDeleteTarget(wf)}
              onClick={() => navigate(`/workflows/${wf.id}/definition`)}
            />
          ))}
        </div>
      )}

      <AIGenerateDialog
        open={showAIDialog}
        onClose={() => setShowAIDialog(false)}
        onGenerate={handleGenerate}
        onViewWorkflow={handleViewWorkflow}
      />

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Workflow"
        message={`Delete "${deleteTarget?.name}"? This cannot be undone.`}
        confirmLabel="Delete"
        destructive
        onConfirm={confirmDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  );
}
