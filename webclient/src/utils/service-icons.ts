export function getServiceIcon(serviceName: string | undefined): string | null {
  const name = serviceName?.toLowerCase();
  if (!name) return null;

  if (name.includes('lightbulb') || name.includes('light')) return 'hk-lightbulb';
  if (name.includes('switch') || name.includes('button')) return 'hk-switch';
  if (name.includes('outlet') || name.includes('plug')) return 'hk-outlet';
  if (name.includes('fan')) return 'hk-fan';
  if (name.includes('thermostat') || name.includes('heater') || name.includes('cooler') || name.includes('ac')) return 'hk-thermostat';
  if (name.includes('garage')) return 'hk-garage';
  if (name.includes('lock')) return 'hk-lock';
  if (name.includes('window') || name.includes('blind') || name.includes('shade')) return 'hk-window-covering';
  if (name.includes('motion')) return 'hk-motion';
  if (name.includes('occupancy') || name.includes('presence')) return 'hk-occupancy';
  if (name.includes('temperature') || name.includes('temp')) return 'hk-temperature';
  if (name.includes('humidity')) return 'hk-humidity';
  if (name.includes('contact') || name.includes('door')) return 'hk-contact';
  if (name.includes('leak') || name.includes('water')) return 'hk-leak';
  if (name.includes('smoke') || name.includes('monoxide') || name.includes('dioxide')) return 'hk-smoke';
  if (name.includes('security') || name.includes('alarm')) return 'hk-security';
  if (name.includes('camera') || name.includes('video')) return 'hk-camera';
  if (name.includes('tv') || name.includes('television')) return 'hk-tv';
  if (name.includes('speaker') || name.includes('audio')) return 'hk-speaker';
  if (name.includes('valve') || name.includes('faucet') || name.includes('irrigation')) return 'hk-valve';
  if (name.includes('doorbell') || name.includes('bell')) return 'hk-doorbell';
  if (name.includes('purifier') || name.includes('air purifier')) return 'hk-air-purifier';
  if (name.includes('air quality') || name.includes('airquality') || name.includes('air_quality')) return 'hk-air-quality';
  if (name.includes('battery')) return 'hk-battery';
  if (name.includes('microphone') || name.includes('mic')) return 'hk-microphone';
  if (name.includes('filter')) return 'hk-filter';
  if (name.includes('robot') || name.includes('vacuum') || name.includes('roomba')) return 'hk-robot-vacuum';
  if (name.includes('curtain') || name.includes('drape')) return 'hk-curtain';

  return null;
}
