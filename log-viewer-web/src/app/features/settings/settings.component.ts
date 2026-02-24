import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ConfigService } from '../../core/services/config.service';
import { ApiService } from '../../core/services/api.service';
import { IconComponent } from '../../shared/components/icon.component';

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [FormsModule, IconComponent],
  templateUrl: './settings.component.html',
  styleUrl: './settings.component.css',
})
export class SettingsComponent {
  protected config = inject(ConfigService);
  private api = inject(ApiService);

  serverAddress = '';
  serverPort = 3000;
  bearerToken = '';
  pollingInterval = 10;

  connectionStatus = signal<'idle' | 'testing' | 'success' | 'error'>('idle');
  saved = signal(false);

  constructor() {
    this.serverAddress = this.config.serverAddress();
    this.serverPort = this.config.serverPort();
    this.bearerToken = this.config.bearerToken();
    this.pollingInterval = this.config.pollingInterval();
  }

  testConnection(): void {
    this.applyToConfig();
    this.connectionStatus.set('testing');
    this.api.checkHealth().subscribe(ok => {
      this.connectionStatus.set(ok ? 'success' : 'error');
      setTimeout(() => this.connectionStatus.set('idle'), 3000);
    });
  }

  save(): void {
    this.applyToConfig();
    this.config.save();
    this.saved.set(true);
    setTimeout(() => this.saved.set(false), 2000);
  }

  private applyToConfig(): void {
    this.config.serverAddress.set(this.serverAddress);
    this.config.serverPort.set(this.serverPort);
    this.config.bearerToken.set(this.bearerToken);
    this.config.pollingInterval.set(this.pollingInterval);
  }
}
