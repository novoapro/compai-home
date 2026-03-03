import { describe, it, expect, beforeEach } from 'vitest';
import { render } from '@testing-library/react';
import { ConfigProvider, useConfig } from './ConfigContext';

function TestConsumer() {
  const { config, isConfigured, baseUrl } = useConfig();
  return (
    <div>
      <span data-testid="address">{config.serverAddress}</span>
      <span data-testid="port">{config.serverPort}</span>
      <span data-testid="token">{config.bearerToken}</span>
      <span data-testid="configured">{String(isConfigured)}</span>
      <span data-testid="baseUrl">{baseUrl}</span>
    </div>
  );
}

describe('ConfigContext', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('provides default values when no localStorage', () => {
    const { getByTestId } = render(
      <ConfigProvider><TestConsumer /></ConfigProvider>
    );

    expect(getByTestId('address').textContent).toBe('localhost');
    expect(getByTestId('port').textContent).toBe('3000');
  });

  it('isConfigured is false when no bearer token', () => {
    const { getByTestId } = render(
      <ConfigProvider><TestConsumer /></ConfigProvider>
    );

    expect(getByTestId('configured').textContent).toBe('false');
  });

  it('isConfigured is true when bearer token saved in localStorage', () => {
    localStorage.setItem('hk-log-viewer:_saved', '1');
    localStorage.setItem('hk-log-viewer:bearerToken', 'my-token');

    const { getByTestId } = render(
      <ConfigProvider><TestConsumer /></ConfigProvider>
    );

    expect(getByTestId('configured').textContent).toBe('true');
    expect(getByTestId('token').textContent).toBe('my-token');
  });

  it('constructs baseUrl correctly', () => {
    const { getByTestId } = render(
      <ConfigProvider><TestConsumer /></ConfigProvider>
    );

    expect(getByTestId('baseUrl').textContent).toBe('http://localhost:3000');
  });

  it('loads values from localStorage when user has saved', () => {
    localStorage.setItem('hk-log-viewer:_saved', '1');
    localStorage.setItem('hk-log-viewer:serverAddress', '192.168.1.100');
    localStorage.setItem('hk-log-viewer:serverPort', '8080');

    const { getByTestId } = render(
      <ConfigProvider><TestConsumer /></ConfigProvider>
    );

    expect(getByTestId('address').textContent).toBe('192.168.1.100');
    expect(getByTestId('port').textContent).toBe('8080');
  });

  it('ignores localStorage when user has not explicitly saved', () => {
    // Stale localStorage without the _saved flag should be ignored
    localStorage.setItem('hk-log-viewer:serverAddress', '10.0.0.99');
    localStorage.setItem('hk-log-viewer:serverPort', '9999');

    const { getByTestId } = render(
      <ConfigProvider><TestConsumer /></ConfigProvider>
    );

    expect(getByTestId('address').textContent).toBe('localhost');
    expect(getByTestId('port').textContent).toBe('3000');
  });

  it('throws when useConfig is used outside provider', () => {
    expect(() => {
      render(<TestConsumer />);
    }).toThrow('useConfig must be used within ConfigProvider');
  });
});
