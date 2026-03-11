import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useDebounce } from './useDebounce';

// Helper: advance fake timers inside React's act() so state updates flush
const advance = (ms: number) => act(() => { vi.advanceTimersByTime(ms); });

describe('useDebounce', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('returns initial value immediately', () => {
    const { result } = renderHook(() => useDebounce('initial', 500));
    expect(result.current).toBe('initial');
  });

  it('does not update value until debounce delay has passed', () => {
    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 'first', delay: 500 },
    });

    expect(result.current).toBe('first');

    rerender({ value: 'second', delay: 500 });
    expect(result.current).toBe('first');

    advance(250);
    expect(result.current).toBe('first');

    advance(250);
    expect(result.current).toBe('second');
  });

  it('updates value after delay elapses', () => {
    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 'original', delay: 1000 },
    });

    rerender({ value: 'updated', delay: 1000 });
    expect(result.current).toBe('original');

    advance(1000);
    expect(result.current).toBe('updated');
  });

  it('resets timer when value changes before delay', () => {
    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 'value1', delay: 500 },
    });

    rerender({ value: 'value2', delay: 500 });
    advance(250);

    rerender({ value: 'value3', delay: 500 });
    advance(250);
    expect(result.current).toBe('value1'); // Still original

    advance(250);
    expect(result.current).toBe('value3'); // Now updated to latest
  });

  it('works with different delay values', () => {
    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 'test', delay: 100 },
    });

    rerender({ value: 'changed', delay: 100 });
    advance(100);
    expect(result.current).toBe('changed');

    rerender({ value: 'value2', delay: 500 });
    advance(250);
    expect(result.current).toBe('changed');

    advance(250);
    expect(result.current).toBe('value2');
  });

  it('works with non-primitive types (objects)', () => {
    const obj1 = { name: 'Alice', age: 30 };
    const obj2 = { name: 'Bob', age: 25 };

    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: obj1, delay: 300 },
    });

    expect(result.current).toBe(obj1);

    rerender({ value: obj2, delay: 300 });
    expect(result.current).toBe(obj1);

    advance(300);
    expect(result.current).toBe(obj2);
  });

  it('works with non-primitive types (arrays)', () => {
    const arr1 = [1, 2, 3];
    const arr2 = [4, 5, 6];

    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: arr1, delay: 200 },
    });

    expect(result.current).toBe(arr1);

    rerender({ value: arr2, delay: 200 });
    expect(result.current).toBe(arr1);

    advance(200);
    expect(result.current).toBe(arr2);
  });

  it('cleans up timer on unmount', () => {
    const { unmount, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 'initial', delay: 500 },
    });

    rerender({ value: 'updated', delay: 500 });
    unmount();

    // Advancing timers after unmount should not cause errors
    expect(() => {
      advance(500);
    }).not.toThrow();
  });

  it('handles zero delay', () => {
    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 'zero', delay: 0 },
    });

    rerender({ value: 'updated', delay: 0 });
    advance(0);
    expect(result.current).toBe('updated');
  });

  it('handles multiple rapid value changes', () => {
    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 'initial', delay: 100 },
    });

    rerender({ value: 'change1', delay: 100 });
    advance(20);

    rerender({ value: 'change2', delay: 100 });
    advance(20);

    rerender({ value: 'change3', delay: 100 });
    advance(20);

    rerender({ value: 'change4', delay: 100 });
    advance(100);

    expect(result.current).toBe('change4');
  });

  it('preserves debounced value when delay changes', () => {
    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 'value1', delay: 100 },
    });

    // Start a 100ms debounce for value2
    rerender({ value: 'value2', delay: 100 });
    advance(50); // 50ms in — still debouncing

    // Change delay to 200ms — this resets the timer to a fresh 200ms window
    rerender({ value: 'value2', delay: 200 });
    expect(result.current).toBe('value1'); // Not updated yet

    advance(150); // 150ms of the new 200ms window — still not fired
    expect(result.current).toBe('value1');

    advance(50); // Now the full 200ms has elapsed
    expect(result.current).toBe('value2');
  });

  it('handles null and undefined values', () => {
    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: null as unknown as string, delay: 100 },
    });

    expect(result.current).toBeNull();

    rerender({ value: undefined as unknown as string, delay: 100 });
    advance(100);
    expect(result.current).toBeUndefined();
  });

  it('handles numeric values', () => {
    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 42, delay: 150 },
    });

    expect(result.current).toBe(42);

    rerender({ value: 100, delay: 150 });
    expect(result.current).toBe(42);

    advance(150);
    expect(result.current).toBe(100);
  });

  it('cancels previous timeout when value changes and delay resets', () => {
    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 'a', delay: 200 },
    });

    expect(result.current).toBe('a');

    rerender({ value: 'b', delay: 200 });
    advance(100);
    expect(result.current).toBe('a'); // Still old, timer reset

    advance(200);
    expect(result.current).toBe('b');
  });

  it('works with string values containing special characters', () => {
    const specialStr = 'hello@world#$%^&*()';

    const { result, rerender } = renderHook(({ value, delay }) => useDebounce(value, delay), {
      initialProps: { value: 'normal', delay: 100 },
    });

    expect(result.current).toBe('normal');

    rerender({ value: specialStr, delay: 100 });
    expect(result.current).toBe('normal'); // Still old value until timer fires

    advance(100);
    // After delay, should have updated to special string
    expect(result.current).toBe(specialStr);
  });
});
