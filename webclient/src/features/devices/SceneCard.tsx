import { memo } from 'react';
import { Icon } from '@/components/Icon';
import type { RESTScene } from '@/types/homekit-device';

interface SceneCardProps {
  scene: RESTScene;
}

export const SceneCard = memo(function SceneCard({ scene }: SceneCardProps) {
  return (
    <div className="scene-card">
      <div className="scene-card-icon">
        <Icon name="play-circle-fill" size={24} style={{ color: 'var(--tint-main)' }} />
      </div>
      <div className="scene-card-info">
        <span className="scene-card-name">{scene.name}</span>
        <span className="scene-card-meta">
          {scene.actionCount} {scene.actionCount === 1 ? 'action' : 'actions'}
        </span>
      </div>
      <div className="scene-card-right">
        {scene.type && (
          <span className="scene-type-badge">{scene.type}</span>
        )}
        {scene.isExecuting && (
          <span className="scene-executing">
            <span className="scene-executing-dot" />
            Executing
          </span>
        )}
      </div>
    </div>
  );
});
