import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router';
import { useSetTopBar } from '@/contexts/TopBarContext';
import { Icon } from '@/components/Icon';
import { EmptyState } from '@/components/EmptyState';
import { AutomationLogRow } from '@/features/automations/AutomationLogRow';
import { useApi } from '@/hooks/useApi';
import { useWebSocket } from '@/contexts/WebSocketContext';
import type { AutomationExecutionLog } from '@/types/automation-log';
import './AutomationExecutionListPage.css';

export function AutomationExecutionListPage() {
  const { automationId } = useParams<{ automationId: string }>();
  const navigate = useNavigate();
  const api = useApi();
  const ws = useWebSocket();

  const [logs, setLogs] = useState<AutomationExecutionLog[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  useSetTopBar('Executions', logs.length > 0 ? logs.length : null, isLoading);

  const loadLogs = useCallback(async () => {
    if (!automationId) return;
    setIsLoading(true);
    setError(null);
    try {
      const result = await api.getAutomationLogs(automationId, 100);
      setLogs(result);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to load execution logs');
    } finally {
      setIsLoading(false);
    }
  }, [api, automationId]);

  useEffect(() => {
    loadLogs();
  }, [loadLogs]);

  // WebSocket: real-time automation log updates
  useEffect(() => {
    const unsubLog = ws.onAutomationLog((msg) => {
      if (msg.data.automationId !== automationId) return;

      setLogs(current => {
        if (msg.type === 'new') {
          if (current.some(l => l.id === msg.data.id)) return current;
          return [msg.data, ...current];
        } else if (msg.type === 'updated') {
          const idx = current.findIndex(l => l.id === msg.data.id);
          if (idx < 0) return current;
          // Don't overwrite a completed status with running
          if (current[idx]!.status !== 'running' && msg.data.status === 'running') return current;
          const updated = [...current];
          updated[idx] = msg.data;
          return updated;
        }
        return current;
      });
    });

    const unsubCleared = ws.onLogsCleared(() => {
      setLogs([]);
    });

    return () => { unsubLog(); unsubCleared(); };
  }, [ws, automationId]);

  const handleLogClick = useCallback((logId: string) => {
    navigate(`/automations/${automationId}/${logId}`);
  }, [navigate, automationId]);

  const goBack = useCallback(() => {
    if (window.history.length > 1) {
      navigate(-1);
    } else {
      navigate(`/automations/${automationId}/definition`);
    }
  }, [navigate, automationId]);

  return (
    <div className="wfel-page">
      <button className="wfel-back-btn" onClick={goBack}>
        <span style={{ transform: 'rotate(90deg)', display: 'inline-flex' }}>
          <Icon name="chevron-down" size={14} />
        </span>
        <span>Back to Automations</span>
      </button>

      <div className="wfel-page-header">
        <h1 className="wfel-page-title">Execution Logs</h1>
        {isLoading && <span className="wfel-loading-dot" />}
      </div>

      {error && (
        <div className="wfel-error-banner animate-fade-in">
          <Icon name="exclamation-triangle" size={16} />
          <span>{error}</span>
        </div>
      )}

      {isLoading && logs.length === 0 && (
        <div className="wfel-skeleton-list">
          {Array.from({ length: 10 }, (_, i) => (
            <div key={i} className="wfel-skeleton-card skeleton" style={{ animationDelay: `${i * 100}ms` }} />
          ))}
        </div>
      )}

      {!isLoading && logs.length === 0 && !error && (
        <EmptyState
          icon="bolt-circle-fill"
          title="No executions"
          message="This automation hasn't been executed yet. Trigger it and execution logs will appear here."
        />
      )}

      {logs.length > 0 && (
        <div className="wfel-log-list">
          {logs.map((log, i) => (
            <AutomationLogRow
              key={log.id}
              log={log}
              index={i}
              onClick={handleLogClick}
            />
          ))}
        </div>
      )}
    </div>
  );
}
