import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { ConfigService } from '../services/config.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const config = inject(ConfigService);

  // Don't add auth to health endpoint
  if (req.url.endsWith('/health')) {
    return next(req);
  }

  const token = config.bearerToken();
  if (!token) {
    return next(req);
  }

  return next(req.clone({
    setHeaders: { Authorization: `Bearer ${token}` }
  }));
};
