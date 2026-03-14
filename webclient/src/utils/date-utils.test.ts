import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { formatDuration, formatTime, getDayKey, getDayLabel } from './date-utils';

describe('formatDuration', () => {
  it('formats milliseconds', () => {
    const start = '2024-01-01T00:00:00.000Z';
    const end = '2024-01-01T00:00:00.500Z';
    expect(formatDuration(start, end)).toBe('500ms');
  });

  it('formats seconds', () => {
    const start = '2024-01-01T00:00:00.000Z';
    const end = '2024-01-01T00:00:05.300Z';
    expect(formatDuration(start, end)).toBe('5.3s');
  });

  it('formats minutes and seconds', () => {
    const start = '2024-01-01T00:00:00.000Z';
    const end = '2024-01-01T00:02:30.000Z';
    expect(formatDuration(start, end)).toBe('2m 30s');
  });
});

describe('formatTime', () => {
  it('returns a time string', () => {
    const result = formatTime('2024-01-01T14:30:45.000Z');
    // Locale-dependent, just check it's a non-empty string
    expect(result).toBeTruthy();
    expect(typeof result).toBe('string');
  });
});

describe('getDayKey', () => {
  it('returns YYYY-MM-DD format', () => {
    expect(getDayKey('2024-06-15T12:00:00.000Z')).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});

describe('getDayLabel', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2024-06-15T12:00:00.000Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('returns "Today" for current day', () => {
    const todayKey = getDayKey(new Date().toISOString());
    expect(getDayLabel(todayKey)).toBe('Today');
  });

  it('returns "Yesterday" for previous day', () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const key = getDayKey(yesterday.toISOString());
    expect(getDayLabel(key)).toBe('Yesterday');
  });
});
