import { describe, it, expect } from 'vitest';
import {
  characteristicDisplayName,
  getCharacteristicDisplayUnit,
  formatCharacteristicValue,
} from './characteristic-types';

describe('characteristicDisplayName', () => {
  it('returns display name for known UUID (Power)', () => {
    expect(characteristicDisplayName('00000025-0000-1000-8000-0026BB765291')).toBe('Power');
  });

  it('returns display name for known UUID (Brightness)', () => {
    expect(characteristicDisplayName('00000008-0000-1000-8000-0026BB765291')).toBe('Brightness');
  });

  it('returns display name for known UUID (Hue)', () => {
    expect(characteristicDisplayName('00000013-0000-1000-8000-0026BB765291')).toBe('Hue');
  });

  it('returns display name for known UUID (Current Temperature)', () => {
    expect(characteristicDisplayName('00000011-0000-1000-8000-0026BB765291')).toBe(
      'Current Temperature',
    );
  });

  it('handles case-insensitive UUID lookups', () => {
    const result = characteristicDisplayName('00000025-0000-1000-8000-0026BB765291'.toLowerCase());
    expect(result).toBe('Power');
  });

  it('returns fallback for non-UUID format', () => {
    const result = characteristicDisplayName('PowerState');
    expect(result).toContain('Power');
  });

  it('capitalizes fallback names with dashes', () => {
    const result = characteristicDisplayName('motion-detected');
    expect(result).toBe('Motion Detected');
  });

  it('capitalizes fallback names with underscores', () => {
    const result = characteristicDisplayName('battery_level');
    expect(result).toBe('Battery Level');
  });

  it('capitalizes fallback names with dots', () => {
    const result = characteristicDisplayName('door.state');
    expect(result).toBe('Door State');
  });

  it('returns original unknown UUID when not found', () => {
    const uuid = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF';
    const result = characteristicDisplayName(uuid);
    expect(result).toBe(uuid);
  });

  it('returns original text for simple unknown strings', () => {
    const result = characteristicDisplayName('UnknownCharacteristic');
    // Should still try to format it
    expect(result).toBeTruthy();
  });

  it('returns display name for Door State', () => {
    expect(characteristicDisplayName('0000000E-0000-1000-8000-0026BB765291')).toBe('Door State');
  });

  it('returns display name for Lock State', () => {
    expect(characteristicDisplayName('0000001D-0000-1000-8000-0026BB765291')).toBe('Lock State');
  });

  it('returns display name for Motion Detected', () => {
    expect(characteristicDisplayName('00000022-0000-1000-8000-0026BB765291')).toBe('Motion Detected');
  });

  it('returns display name for Battery Level', () => {
    expect(characteristicDisplayName('00000068-0000-1000-8000-0026BB765291')).toBe('Battery Level');
  });

  it('returns display name for Contact State', () => {
    expect(characteristicDisplayName('0000006A-0000-1000-8000-0026BB765291')).toBe('Contact State');
  });

  it('returns display name for Occupancy Detected', () => {
    expect(characteristicDisplayName('00000071-0000-1000-8000-0026BB765291')).toBe(
      'Occupancy Detected',
    );
  });

  it('returns display name for Smoke Detected', () => {
    expect(characteristicDisplayName('00000076-0000-1000-8000-0026BB765291')).toBe('Smoke Detected');
  });

  it('returns display name for CO Detected', () => {
    expect(characteristicDisplayName('00000069-0000-1000-8000-0026BB765291')).toBe('CO Detected');
  });
});

describe('getCharacteristicDisplayUnit', () => {
  it('returns celsius for temperature characteristics by default', () => {
    expect(
      getCharacteristicDisplayUnit('00000011-0000-1000-8000-0026BB765291'),
    ).toBe('°C');
  });

  it('returns fahrenheit for temperature when units specified', () => {
    expect(
      getCharacteristicDisplayUnit('00000011-0000-1000-8000-0026BB765291', 'fahrenheit'),
    ).toBe('°F');
  });

  it('returns percent for brightness', () => {
    expect(getCharacteristicDisplayUnit('00000008-0000-1000-8000-0026BB765291')).toBe('%');
  });

  it('returns percent for saturation', () => {
    expect(getCharacteristicDisplayUnit('0000002F-0000-1000-8000-0026BB765291')).toBe('%');
  });

  it('returns percent for battery level', () => {
    expect(getCharacteristicDisplayUnit('00000068-0000-1000-8000-0026BB765291')).toBe('%');
  });

  it('returns percent for humidity', () => {
    expect(getCharacteristicDisplayUnit('00000010-0000-1000-8000-0026BB765291')).toBe('%');
  });

  it('returns degrees for hue', () => {
    expect(getCharacteristicDisplayUnit('00000013-0000-1000-8000-0026BB765291')).toBe('°');
  });

  it('returns kelvin for color temperature', () => {
    expect(getCharacteristicDisplayUnit('000000CE-0000-1000-8000-0026BB765291')).toBe('K');
  });

  it('returns null for characteristics without units', () => {
    expect(getCharacteristicDisplayUnit('00000025-0000-1000-8000-0026BB765291')).toBeNull();
  });

  it('returns null for unknown characteristics', () => {
    expect(getCharacteristicDisplayUnit('FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF')).toBeNull();
  });

  it('returns percent for rotation speed', () => {
    expect(getCharacteristicDisplayUnit('00000029-0000-1000-8000-0026BB765291')).toBe('%');
  });

  it('returns percent for position', () => {
    expect(getCharacteristicDisplayUnit('0000006D-0000-1000-8000-0026BB765291')).toBe('%');
  });
});

describe('formatCharacteristicValue', () => {
  it('returns -- for undefined value', () => {
    expect(formatCharacteristicValue(undefined, '00000025-0000-1000-8000-0026BB765291')).toBe('--');
  });

  it('returns -- for null value', () => {
    expect(formatCharacteristicValue(null, '00000025-0000-1000-8000-0026BB765291')).toBe('--');
  });

  it('formats boolean power as On/Off', () => {
    expect(formatCharacteristicValue(true, '00000025-0000-1000-8000-0026BB765291')).toBe('On');
    expect(formatCharacteristicValue(false, '00000025-0000-1000-8000-0026BB765291')).toBe('Off');
  });

  it('formats numeric power as On/Off', () => {
    expect(formatCharacteristicValue(1, '00000025-0000-1000-8000-0026BB765291')).toBe('On');
    expect(formatCharacteristicValue(0, '00000025-0000-1000-8000-0026BB765291')).toBe('Off');
  });

  it('formats motion detected boolean', () => {
    expect(formatCharacteristicValue(true, '00000022-0000-1000-8000-0026BB765291')).toBe('On');
    expect(formatCharacteristicValue(false, '00000022-0000-1000-8000-0026BB765291')).toBe('Off');
  });

  it('formats contact state boolean', () => {
    expect(formatCharacteristicValue(true, '0000006A-0000-1000-8000-0026BB765291')).toBe('On');
    expect(formatCharacteristicValue(false, '0000006A-0000-1000-8000-0026BB765291')).toBe('Off');
  });

  it('formats brightness as number', () => {
    expect(formatCharacteristicValue(75, '00000008-0000-1000-8000-0026BB765291')).toBe('75');
  });

  it('formats saturation as number', () => {
    expect(formatCharacteristicValue(50, '0000002F-0000-1000-8000-0026BB765291')).toBe('50');
  });

  it('formats battery level as number', () => {
    expect(formatCharacteristicValue(85, '00000068-0000-1000-8000-0026BB765291')).toBe('85');
  });

  it('formats temperature with one decimal place', () => {
    expect(formatCharacteristicValue(20.5, '00000011-0000-1000-8000-0026BB765291')).toBe('20.5');
  });

  it('formats temperature rounding to one decimal', () => {
    expect(formatCharacteristicValue(20.123, '00000011-0000-1000-8000-0026BB765291')).toBe('20.1');
  });

  it('formats door state by index', () => {
    expect(formatCharacteristicValue(0, '0000000E-0000-1000-8000-0026BB765291')).toBe('Open');
    expect(formatCharacteristicValue(1, '0000000E-0000-1000-8000-0026BB765291')).toBe('Closed');
    expect(formatCharacteristicValue(2, '0000000E-0000-1000-8000-0026BB765291')).toBe('Opening');
    expect(formatCharacteristicValue(3, '0000000E-0000-1000-8000-0026BB765291')).toBe('Closing');
    expect(formatCharacteristicValue(4, '0000000E-0000-1000-8000-0026BB765291')).toBe('Stopped');
  });

  it('returns numeric string for unknown door state index', () => {
    expect(formatCharacteristicValue(99, '0000000E-0000-1000-8000-0026BB765291')).toBe('99');
  });

  it('formats lock state by index', () => {
    expect(formatCharacteristicValue(0, '0000001D-0000-1000-8000-0026BB765291')).toBe('Unsecured');
    expect(formatCharacteristicValue(1, '0000001D-0000-1000-8000-0026BB765291')).toBe('Secured');
    expect(formatCharacteristicValue(2, '0000001D-0000-1000-8000-0026BB765291')).toBe('Jammed');
    expect(formatCharacteristicValue(3, '0000001D-0000-1000-8000-0026BB765291')).toBe('Unknown');
  });

  it('returns numeric string for unknown lock state index', () => {
    expect(formatCharacteristicValue(99, '0000001D-0000-1000-8000-0026BB765291')).toBe('99');
  });

  it('formats occupancy detected boolean', () => {
    expect(formatCharacteristicValue(true, '00000071-0000-1000-8000-0026BB765291')).toBe('On');
    expect(formatCharacteristicValue(false, '00000071-0000-1000-8000-0026BB765291')).toBe('Off');
  });

  it('formats smoke detected boolean', () => {
    expect(formatCharacteristicValue(true, '00000076-0000-1000-8000-0026BB765291')).toBe('On');
    expect(formatCharacteristicValue(false, '00000076-0000-1000-8000-0026BB765291')).toBe('Off');
  });

  it('formats CO detected boolean', () => {
    expect(formatCharacteristicValue(true, '00000069-0000-1000-8000-0026BB765291')).toBe('On');
    expect(formatCharacteristicValue(false, '00000069-0000-1000-8000-0026BB765291')).toBe('Off');
  });

  it('falls back to On/Off for unknown boolean characteristics', () => {
    expect(formatCharacteristicValue(true, 'UnknownBooleanChar')).toBe('On');
    expect(formatCharacteristicValue(false, 'UnknownBooleanChar')).toBe('Off');
  });

  it('returns string representation of unknown values', () => {
    expect(formatCharacteristicValue('custom-value', 'UnknownChar')).toBe('custom-value');
  });

  it('handles percentage value of 0', () => {
    expect(formatCharacteristicValue(0, '00000008-0000-1000-8000-0026BB765291')).toBe('0');
  });

  it('handles percentage value of 100', () => {
    expect(formatCharacteristicValue(100, '00000008-0000-1000-8000-0026BB765291')).toBe('100');
  });

  it('handles temperature of 0 celsius', () => {
    expect(formatCharacteristicValue(0, '00000011-0000-1000-8000-0026BB765291')).toBe('0.0');
  });

  it('formats active boolean characteristic', () => {
    expect(formatCharacteristicValue(true, '000000B0-0000-1000-8000-0026BB765291')).toBe('On');
    expect(formatCharacteristicValue(false, '000000B0-0000-1000-8000-0026BB765291')).toBe('Off');
  });

  it('handles NaN for percentage characteristics', () => {
    expect(formatCharacteristicValue(NaN, '00000008-0000-1000-8000-0026BB765291')).toBe('0');
  });

  it('handles Infinity for percentage characteristics', () => {
    expect(formatCharacteristicValue(Infinity, '00000008-0000-1000-8000-0026BB765291')).toBe('0');
  });
});
