import { Component, input, computed } from '@angular/core';
import { IconComponent } from './icon.component';
import { LogCategory, CATEGORY_META } from '../../core/models/state-change-log.model';

@Component({
  selector: 'app-category-icon',
  standalone: true,
  imports: [IconComponent],
  template: `
    <div class="icon-circle" [style.background-color]="bgColor()" [style.color]="color()">
      <app-icon [name]="iconName()" [size]="iconSize()" />
    </div>
  `,
  styles: [`
    .icon-circle {
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 50%;
      flex-shrink: 0;
    }
  `],
  host: {
    '[style.width.px]': 'size()',
    '[style.height.px]': 'size()',
  }
})
export class CategoryIconComponent {
  category = input.required<LogCategory>();
  size = input(28);

  readonly iconSize = computed(() => Math.round(this.size() * 0.52));

  readonly color = computed(() => {
    return CATEGORY_META[this.category()]?.color || 'var(--tint-main)';
  });

  readonly bgColor = computed(() => {
    // We use an approach to convert to rgba with 0.15 opacity
    // Since CSS variables, we replicate this as a lighter tint
    return `color-mix(in srgb, ${CATEGORY_META[this.category()]?.color || 'var(--tint-main)'} 15%, transparent)`;
  });

  readonly iconName = computed(() => {
    return CATEGORY_META[this.category()]?.icon || 'bolt-circle-fill';
  });
}
