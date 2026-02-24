import { Component, inject } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { IconComponent } from './shared/components/icon.component';
import { ThemeService } from './core/services/theme.service';
import { ConfigService } from './core/services/config.service';
import { PollingService } from './core/services/polling.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, IconComponent],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected theme = inject(ThemeService);
  protected config = inject(ConfigService);
  protected polling = inject(PollingService);

  onRefresh(): void {
    this.polling.refresh();
  }
}
