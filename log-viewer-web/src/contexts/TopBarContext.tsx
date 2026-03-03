import { createContext, useContext, useState, useCallback, useEffect, type ReactNode } from 'react';

interface TopBarContextValue {
  title: string;
  badge: string | number | null;
  showLoading: boolean;
  setTopBar: (title: string, badge?: string | number | null, showLoading?: boolean) => void;
}

const TopBarContext = createContext<TopBarContextValue | null>(null);

export function TopBarProvider({ children }: { children: ReactNode }) {
  const [title, setTitle] = useState('');
  const [badge, setBadge] = useState<string | number | null>(null);
  const [showLoading, setShowLoading] = useState(false);

  const setTopBar = useCallback((t: string, b: string | number | null = null, loading = false) => {
    setTitle(t);
    setBadge(b);
    setShowLoading(loading);
  }, []);

  return (
    <TopBarContext.Provider value={{ title, badge, showLoading, setTopBar }}>
      {children}
    </TopBarContext.Provider>
  );
}

export function useTopBar(): TopBarContextValue {
  const ctx = useContext(TopBarContext);
  if (!ctx) throw new Error('useTopBar must be used within TopBarProvider');
  return ctx;
}

/** Hook for pages to set the topbar title/badge on mount */
export function useSetTopBar(title: string, badge?: string | number | null, showLoading?: boolean) {
  const { setTopBar } = useTopBar();
  useEffect(() => {
    setTopBar(title, badge ?? null, showLoading ?? false);
  }, [title, badge, showLoading, setTopBar]);
}
