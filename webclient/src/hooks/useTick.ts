import { useState, useEffect } from 'react';

/**
 * Returns an incrementing counter that updates every `intervalMs` while `active` is true.
 * Use the returned value as a dependency in useMemo to force recalculation of elapsed times.
 */
export function useTick(active: boolean, intervalMs = 1000): number {
  const [tick, setTick] = useState(0);

  useEffect(() => {
    if (!active) return;
    const id = setInterval(() => setTick(t => t + 1), intervalMs);
    return () => clearInterval(id);
  }, [active, intervalMs]);

  return tick;
}
