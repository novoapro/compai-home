import { StateChangeLog } from './state-change-log.model';

export interface PaginatedLogsResponse {
  logs: StateChangeLog[];
  total: number;
  offset: number;
  limit: number;
}

export interface LogQueryParams {
  categories?: string[];
  device_name?: string;
  date?: string;
  from?: string;
  to?: string;
  offset?: number;
  limit?: number;
}
