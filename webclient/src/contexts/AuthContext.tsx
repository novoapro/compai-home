import { createContext, useContext, useMemo, useCallback, useRef, type ReactNode } from 'react';
import { useConfig } from './ConfigContext';
import { createApiClient, type ApiClient } from '@/lib/api';
import { createOAuthClient } from '@/lib/oauth-client';

interface AuthContextValue {
  api: ApiClient;
  getAccessToken: () => Promise<string>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const { config, baseUrl } = useConfig();
  const oauthClientRef = useRef<ReturnType<typeof createOAuthClient> | null>(null);

  // Recreate OAuth client when credentials change
  const oauthClient = useMemo(() => {
    if (config.authMethod !== 'oauth' || !config.oauthClientId || !config.oauthClientSecret) {
      oauthClientRef.current = null;
      return null;
    }
    const client = createOAuthClient({
      baseUrl,
      clientId: config.oauthClientId,
      clientSecret: config.oauthClientSecret,
    });
    oauthClientRef.current = client;
    return client;
  }, [baseUrl, config.authMethod, config.oauthClientId, config.oauthClientSecret]);

  const getAccessToken = useCallback(async (): Promise<string> => {
    if (config.authMethod === 'bearer') {
      return config.bearerToken;
    }
    if (!oauthClientRef.current) {
      throw new Error('OAuth not configured');
    }
    return oauthClientRef.current.getAccessToken();
  }, [config.authMethod, config.bearerToken]);

  // Single API client using token resolver — no Proxy needed
  const api = useMemo(() => {
    if (config.authMethod === 'oauth' && oauthClient) {
      return createApiClient(
        baseUrl,
        () => oauthClient.getAccessToken(),
        () => oauthClient.clearTokens(),
      );
    }
    return createApiClient(baseUrl, config.bearerToken);
  }, [baseUrl, config.authMethod, config.bearerToken, oauthClient]);

  const value = useMemo(() => ({ api, getAccessToken }), [api, getAccessToken]);

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
