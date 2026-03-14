import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useTick } from './useTick';

// Helper: advance fake timers inside React's act() so state updates flush
const advance = (ms: number) => act(() => { vi.advanceTimersByTime(ms); });

describe('useTick', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('starts at 0 initially', () => {
    const { result } = renderHook(() => useTick(true, 1000));
    expect(result.current).toBe(0);
  });

  it('increments tick at specified interval when active is true', () => {
    const { result } = renderHook(() => useTick(true, 500));

    expect(result.current).toBe(0);

    advance(500);
    expect(result.current).toBe(1);

    advance(500);
    expect(result.current).toBe(2);

    advance(500);
    expect(result.current).toBe(3);
  });

  it('does not tick when active is false', () => {
    const { result } = renderHook(() => useTick(false, 500));

    expect(result.current).toBe(0);

    advance(500);
    expect(result.current).toBe(0);

    advance(500);
    expect(result.current).toBe(0);
  });

  it('stops ticking when active becomes false', () => {
    const { result, rerender } = renderHook(({ active, interval }) => useTick(active, interval), {
      initialProps: { active: true, interval: 500 },
    });

    advance(500);
    expect(result.current).toBe(1);

    rerender({ active: false, interval: 500 });

    advance(500);
    expect(result.current).toBe(1); // Should not increment
  });

  it('resumes ticking when active becomes true again', () => {
    const { result, rerender } = renderHook(({ active, interval }) => useTick(active, interval), {
      initialProps: { active: false, interval: 500 },
    });

    expect(result.current).toBe(0);

    rerender({ active: true, interval: 500 });

    advance(500);
    expect(result.current).toBe(1);

    advance(500);
    expect(result.current).toBe(2);
  });

  it('cleans up timer on unmount', () => {
    const { unmount } = renderHook(() => useTick(true, 500));

    unmount();

    // Should not cause errors when advancing timers after unmount
    expect(() => {
      advance(500);
    }).not.toThrow();
  });

  it('uses default interval of 1000ms', () => {
    const { result } = renderHook(() => useTick(true)); // No intervalMs specified

    advance(1000);
    expect(result.current).toBe(1);

    advance(1000);
    expect(result.current).toBe(2);
  });

  it('respects custom intervals', () => {
    const { result: result100 } = renderHook(() => useTick(true, 100));
    const { result: result200 } = renderHook(() => useTick(true, 200));

    advance(100);
    expect(result100.current).toBe(1);
    expect(result200.current).toBe(0);

    advance(100);
    expect(result100.current).toBe(2);
    expect(result200.current).toBe(1);
  });

  it('handles interval changes', () => {
    const { result, rerender } = renderHook(({ active, interval }) => useTick(active, interval), {
      initialProps: { active: true, interval: 500 },
    });

    advance(500);
    expect(result.current).toBe(1);

    rerender({ active: true, interval: 100 });

    advance(100);
    expect(result.current).toBe(2);

    advance(100);
    expect(result.current).toBe(3);
  });

  it('handles very small intervals', () => {
    const { result } = renderHook(() => useTick(true, 1));

    advance(1);
    expect(result.current).toBe(1);

    advance(1);
    expect(result.current).toBe(2);

    advance(1);
    expect(result.current).toBe(3);
  });

  it('handles large intervals', () => {
    const { result } = renderHook(() => useTick(true, 10000));

    advance(5000);
    expect(result.current).toBe(0);

    advance(5000);
    expect(result.current).toBe(1);

    advance(10000);
    expect(result.current).toBe(2);
  });

  it('can be used as a dependency to trigger recalculations', () => {
    const { result } = renderHook(() => {
      const tick = useTick(true, 250);
      return { tick, product: tick * 2 };
    });

    expect(result.current.tick).toBe(0);
    expect(result.current.product).toBe(0);

    advance(250);
    expect(result.current.tick).toBe(1);
    expect(result.current.product).toBe(2);

    advance(250);
    expect(result.current.tick).toBe(2);
    expect(result.current.product).toBe(4);
  });

  it('maintains tick count incrementally', () => {
    const { result } = renderHook(() => useTick(true, 100));

    for (let i = 0; i < 10; i++) {
      advance(100);
      expect(result.current).toBe(i + 1);
    }
  });

  it('toggles active multiple times correctly', () => {
    const { result, rerender } = renderHook(({ active }) => useTick(active, 300), {
      initialProps: { active: true },
    });

    advance(300);
    expect(result.current).toBe(1);

    rerender({ active: false });
    advance(300);
    expect(result.current).toBe(1);

    rerender({ active: true });
    advance(300);
    expect(result.current).toBe(2);

    rerender({ active: false });
    advance(300);
    expect(result.current).toBe(2);

    rerender({ active: true });
    advance(300);
    expect(result.current).toBe(3);
  });

  it('clears previous interval when active becomes true after being false', () => {
    const { result, rerender } = renderHook(({ active, interval }) => useTick(active, interval), {
      initialProps: { active: true, interval: 500 },
    });

    advance(500);
    expect(result.current).toBe(1);

    rerender({ active: false, interval: 500 });

    rerender({ active: true, interval: 500 });

    advance(500);
    expect(result.current).toBe(2);
  });

  it('works with small interval', () => {
    const { result } = renderHook(() => useTick(true, 50));

    advance(50);
    expect(result.current).toBe(1);

    advance(50);
    expect(result.current).toBe(2);
  });

  it('provides stable tick value across rerenders when inactive', () => {
    const { result, rerender } = renderHook(({ active, interval }) => useTick(active, interval), {
      initialProps: { active: false, interval: 500 },
    });

    const firstTick = result.current;

    rerender({ active: false, interval: 500 });
    expect(result.current).toBe(firstTick);

    rerender({ active: false, interval: 1000 });
    expect(result.current).toBe(firstTick);
  });
});
