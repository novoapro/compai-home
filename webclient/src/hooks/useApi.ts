import { useAuth } from '@/contexts/AuthContext';
import type { ApiClient } from '@/lib/api';

export function useApi(): ApiClient {
  return useAuth().api;
}
