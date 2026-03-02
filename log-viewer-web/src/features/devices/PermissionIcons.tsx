import { useMemo } from 'react';
import { Icon } from '@/components/Icon';

interface PermissionIconsProps {
  permissions: string[];
}

export function PermissionIcons({ permissions }: PermissionIconsProps) {
  const perms = useMemo(() => new Set(permissions.map(p => p.toLowerCase())), [permissions]);

  return (
    <span className="inline-flex items-center gap-1">
      {perms.has('read') && (
        <span title="Readable">
          <Icon name="eye" size={13} className="perm-icon" style={{ color: 'var(--text-tertiary)' }} />
        </span>
      )}
      {perms.has('write') && (
        <span title="Writable">
          <Icon name="pencil" size={13} className="perm-icon" style={{ color: 'var(--text-tertiary)' }} />
        </span>
      )}
      {perms.has('notify') && (
        <span title="Supports notifications">
          <Icon name="bell" size={13} className="perm-icon" style={{ color: 'var(--text-tertiary)' }} />
        </span>
      )}
    </span>
  );
}
