import { useState, useEffect, useCallback } from 'react';
import { Icon } from '@/components/Icon';
import type { ApiClient, OAuthCredentialResponse, OAuthCredentialCreated } from '@/lib/api';

interface Props {
  api: ApiClient;
}

export function OAuthCredentials({ api }: Props) {
  const [credentials, setCredentials] = useState<OAuthCredentialResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [newName, setNewName] = useState('');
  const [created, setCreated] = useState<OAuthCredentialCreated | null>(null);
  const [copied, setCopied] = useState(false);

  const loadCredentials = useCallback(async () => {
    try {
      const data = await api.getOAuthCredentials();
      setCredentials(data);
    } catch { /* ignore */ }
    setLoading(false);
  }, [api]);

  useEffect(() => { loadCredentials(); }, [loadCredentials]);

  const handleCreate = async () => {
    const name = newName.trim();
    if (!name) return;
    try {
      const cred = await api.createOAuthCredential(name);
      setCreated(cred);
      setShowCreate(false);
      setNewName('');
      loadCredentials();
    } catch { /* ignore */ }
  };

  const handleRevoke = async (id: string) => {
    if (!confirm('Revoke this credential? All active sessions will be terminated.')) return;
    await api.revokeOAuthCredential(id);
    loadCredentials();
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Permanently delete this credential?')) return;
    await api.deleteOAuthCredential(id);
    loadCredentials();
  };

  const copyConfig = () => {
    if (!created) return;
    const config = `Client ID: ${created.clientId}\nClient Secret: ${created.clientSecret}\nToken Endpoint: ${created.tokenEndpoint}\nAuthorization Endpoint: ${created.authorizationEndpoint}`;
    navigator.clipboard.writeText(config);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  if (loading) return <div className="loading-spinner"><Icon name="spinner" size={20} className="animate-spin-custom" /></div>;

  return (
    <div>
      <h3 className="section-heading">OAuth Credentials</h3>
      <p className="hint" style={{ marginBottom: '1rem' }}>
        OAuth 2.1 credentials for MCP clients. Each credential generates a client ID and secret.
      </p>

      {credentials.map(cred => (
        <div key={cred.id} className="form-group" style={{ opacity: cred.isRevoked ? 0.6 : 1 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <strong>{cred.name}</strong>
              {cred.isRevoked && <span style={{ color: 'var(--color-error)', marginLeft: 8, fontSize: 12 }}>REVOKED</span>}
            </div>
            <span className="hint">{new Date(cred.createdAt).toLocaleDateString()}</span>
          </div>
          <div style={{ fontFamily: 'monospace', fontSize: 12, color: 'var(--color-text-secondary)' }}>
            ID: {cred.clientId.substring(0, 16)}...
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
            {!cred.isRevoked && (
              <button className="btn btn-secondary" style={{ fontSize: 12, padding: '4px 8px' }} onClick={() => handleRevoke(cred.id)}>
                Revoke
              </button>
            )}
            <button className="btn btn-secondary" style={{ fontSize: 12, padding: '4px 8px', color: 'var(--color-error)' }} onClick={() => handleDelete(cred.id)}>
              Delete
            </button>
          </div>
        </div>
      ))}

      {showCreate ? (
        <div className="form-group">
          <input
            type="text"
            className="form-input"
            placeholder="Client name (e.g. Claude Desktop)"
            value={newName}
            onChange={e => setNewName(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleCreate()}
            autoFocus
          />
          <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
            <button className="btn btn-primary" onClick={handleCreate}>Create</button>
            <button className="btn btn-secondary" onClick={() => { setShowCreate(false); setNewName(''); }}>Cancel</button>
          </div>
        </div>
      ) : (
        <button className="btn btn-secondary" onClick={() => setShowCreate(true)}>
          <Icon name="plus-circle" size={16} /><span>Add OAuth Credential</span>
        </button>
      )}

      {created && (
        <div className="settings-card" style={{ marginTop: 16, border: '1px solid var(--color-success)' }}>
          <h4>Credential Created</h4>
          <p className="hint" style={{ color: 'var(--color-error)' }}>Save these now — the secret won't be shown again.</p>
          <div style={{ fontFamily: 'monospace', fontSize: 13, marginTop: 8 }}>
            <div><strong>Client ID:</strong> {created.clientId}</div>
            <div><strong>Client Secret:</strong> {created.clientSecret}</div>
            <div><strong>Token Endpoint:</strong> {created.tokenEndpoint}</div>
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
            <button className="btn btn-primary" onClick={copyConfig}>
              {copied ? 'Copied!' : 'Copy Configuration'}
            </button>
            <button className="btn btn-secondary" onClick={() => setCreated(null)}>Dismiss</button>
          </div>
        </div>
      )}
    </div>
  );
}
