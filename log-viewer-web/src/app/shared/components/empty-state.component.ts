import { Component, input } from '@angular/core';
import { IconComponent } from './icon.component';

@Component({
  selector: 'app-empty-state',
  standalone: true,
  imports: [IconComponent],
  template: `
    <div class="empty-state">
      <div class="icon-wrapper">
        <app-icon [name]="icon()" [size]="48" />
      </div>
      <h3>{{ title() }}</h3>
      <p>{{ message() }}</p>
    </div>
  `,
  styles: [`
    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: var(--spacing-xl) var(--spacing-lg);
      min-height: 300px;
      text-align: center;
    }
    .icon-wrapper {
      color: var(--text-tertiary);
      margin-bottom: var(--spacing-md);
    }
    h3 {
      font-size: var(--font-size-lg);
      font-weight: var(--font-weight-semibold);
      color: var(--text-primary);
      margin-bottom: var(--spacing-xs);
    }
    p {
      font-size: var(--font-size-sm);
      color: var(--text-secondary);
      max-width: 300px;
    }
  `]
})
export class EmptyStateComponent {
  icon = input('bolt-circle-fill');
  title = input('No data');
  message = input('');
}
