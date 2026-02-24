import { Injectable, signal, effect } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  readonly isDarkMode = signal(false);

  constructor() {
    // Check localStorage override first
    const stored = localStorage.getItem('hk-log-viewer:theme');
    if (stored) {
      this.isDarkMode.set(stored === 'dark');
    } else {
      // Fall back to system preference
      this.isDarkMode.set(window.matchMedia('(prefers-color-scheme: dark)').matches);
    }

    // Listen to system preference changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
      if (!localStorage.getItem('hk-log-viewer:theme')) {
        this.isDarkMode.set(e.matches);
      }
    });

    // Apply theme attribute whenever signal changes
    effect(() => {
      document.documentElement.setAttribute('data-theme', this.isDarkMode() ? 'dark' : 'light');
    });
  }

  toggle(): void {
    this.isDarkMode.set(!this.isDarkMode());
    localStorage.setItem('hk-log-viewer:theme', this.isDarkMode() ? 'dark' : 'light');
  }
}
