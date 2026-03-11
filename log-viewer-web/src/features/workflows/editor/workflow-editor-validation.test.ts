import { describe, it, expect } from 'vitest';
import { validateDraft } from './workflow-editor-validation';
import type { WorkflowDraft } from './workflow-editor-types';
import { emptyDraft } from './workflow-editor-types';

describe('validateDraft', () => {
  it('returns empty array for valid complete workflow', () => {
    const draft: WorkflowDraft = {
      name: 'Valid Workflow',
      description: 'A complete workflow',
      isEnabled: true,
      continueOnError: false,
      tags: [],
      triggers: [
        {
          _draftId: 'trigger-1',
          type: 'deviceStateChange',
          deviceId: 'device-1',
          characteristicId: 'char-1',
        },
      ],
      conditions: [],
      blocks: [
        {
          _draftId: 'block-1',
          block: 'action',
          type: 'controlDevice',
          deviceId: 'device-2',
        },
      ],
    };

    const errors = validateDraft(draft);
    expect(errors).toEqual([]);
  });

  it('returns error when name is empty', () => {
    const draft = emptyDraft();
    draft.name = '';

    const errors = validateDraft(draft);
    expect(errors).toContain('Name is required');
  });

  it('returns error when name is only whitespace', () => {
    const draft = emptyDraft();
    draft.name = '   ';

    const errors = validateDraft(draft);
    expect(errors).toContain('Name is required');
  });

  it('returns error when no triggers provided', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.triggers = [];

    const errors = validateDraft(draft);
    expect(errors).toContain('At least one trigger is required');
  });

  it('returns error when no blocks provided', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'schedule',
        scheduleType: 'daily',
      },
    ];
    draft.blocks = [];

    const errors = validateDraft(draft);
    expect(errors).toContain('At least one block is required');
  });

  it('returns error when deviceStateChange trigger missing device', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
        characteristicId: 'char-1',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).toContain('Device trigger: a device is required');
  });

  it('returns error when deviceStateChange trigger missing characteristic', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
        deviceId: 'device-1',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).toContain('Device trigger: a characteristic is required');
  });

  it('returns multiple errors for deviceStateChange missing both device and characteristic', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).toContain('Device trigger: a device is required');
    expect(errors).toContain('Device trigger: a characteristic is required');
  });

  it('returns error when weekly schedule has no selected days', () => {
    const draft = emptyDraft();
    draft.name = 'Weekly Schedule';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'schedule',
        scheduleType: 'weekly',
        scheduleDays: [],
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).toContain('Weekly schedule: select at least one day');
  });

  it('passes validation when weekly schedule has selected days', () => {
    const draft = emptyDraft();
    draft.name = 'Weekly Schedule';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'schedule',
        scheduleType: 'weekly',
        scheduleDays: [1, 3, 5],
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).not.toContain('Weekly schedule: select at least one day');
  });

  it('passes validation for schedule triggers other than weekly', () => {
    const draftDaily = emptyDraft();
    draftDaily.name = 'Daily Schedule';
    draftDaily.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'schedule',
        scheduleType: 'daily',
      },
    ];
    draftDaily.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
    ];

    const errors = validateDraft(draftDaily);
    expect(errors).not.toContain('Weekly schedule: select at least one day');
  });

  it('returns error when Block Result conditions without continueOnError', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.continueOnError = false;
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
        deviceId: 'device-1',
        characteristicId: 'char-1',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'flowControl',
        type: 'conditional',
        condition: {
          _draftId: 'cond-1',
          type: 'blockResult',
          blockResultScope: { scope: 'any' },
        },
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).toContain('Block Result conditions require "Continue on Error" to be enabled');
  });

  it('passes validation when Block Result conditions with continueOnError enabled', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.continueOnError = true;
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
        deviceId: 'device-1',
        characteristicId: 'char-1',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'flowControl',
        type: 'conditional',
        condition: {
          _draftId: 'cond-1',
          type: 'blockResult',
          blockResultScope: { scope: 'any' },
        },
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).not.toContain('Block Result conditions require "Continue on Error" to be enabled');
  });

  it('detects blockResult in nested conditions', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.continueOnError = false;
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
        deviceId: 'device-1',
        characteristicId: 'char-1',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'flowControl',
        type: 'conditional',
        condition: {
          _draftId: 'cond-1',
          type: 'and',
          conditions: [
            {
              _draftId: 'cond-2',
              type: 'deviceState',
              deviceId: 'device-1',
            },
            {
              _draftId: 'cond-3',
              type: 'blockResult',
              blockResultScope: { scope: 'any' },
            },
          ],
        },
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).toContain('Block Result conditions require "Continue on Error" to be enabled');
  });

  it('detects blockResult in thenBlocks', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.continueOnError = false;
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
        deviceId: 'device-1',
        characteristicId: 'char-1',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'flowControl',
        type: 'conditional',
        thenBlocks: [
          {
            _draftId: 'block-2',
            block: 'flowControl',
            type: 'conditional',
            condition: {
              _draftId: 'cond-1',
              type: 'blockResult',
              blockResultScope: { scope: 'any' },
            },
          },
        ],
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).toContain('Block Result conditions require "Continue on Error" to be enabled');
  });

  it('detects blockResult in elseBlocks', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.continueOnError = false;
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
        deviceId: 'device-1',
        characteristicId: 'char-1',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'flowControl',
        type: 'conditional',
        elseBlocks: [
          {
            _draftId: 'block-2',
            block: 'flowControl',
            type: 'conditional',
            condition: {
              _draftId: 'cond-1',
              type: 'blockResult',
              blockResultScope: { scope: 'any' },
            },
          },
        ],
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).toContain('Block Result conditions require "Continue on Error" to be enabled');
  });

  it('detects blockResult in grouped blocks', () => {
    const draft = emptyDraft();
    draft.name = 'Test';
    draft.continueOnError = false;
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
        deviceId: 'device-1',
        characteristicId: 'char-1',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'flowControl',
        type: 'group',
        blocks: [
          {
            _draftId: 'block-2',
            block: 'flowControl',
            type: 'conditional',
            condition: {
              _draftId: 'cond-1',
              type: 'blockResult',
              blockResultScope: { scope: 'any' },
            },
          },
        ],
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).toContain('Block Result conditions require "Continue on Error" to be enabled');
  });

  it('returns all validation errors at once', () => {
    const draft: WorkflowDraft = {
      name: '',
      description: '',
      isEnabled: false,
      continueOnError: false,
      tags: [],
      triggers: [],
      conditions: [],
      blocks: [],
    };

    const errors = validateDraft(draft);
    expect(errors.length).toBeGreaterThanOrEqual(2);
    expect(errors).toContain('Name is required');
    expect(errors).toContain('At least one trigger is required');
    expect(errors).toContain('At least one block is required');
  });

  it('allows multiple triggers', () => {
    const draft = emptyDraft();
    draft.name = 'Multiple Triggers';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
        deviceId: 'device-1',
        characteristicId: 'char-1',
      },
      {
        _draftId: 'trigger-2',
        type: 'schedule',
        scheduleType: 'daily',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).not.toContain('At least one trigger is required');
  });

  it('allows multiple blocks', () => {
    const draft = emptyDraft();
    draft.name = 'Multiple Blocks';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'deviceStateChange',
        deviceId: 'device-1',
        characteristicId: 'char-1',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
      {
        _draftId: 'block-2',
        block: 'action',
        type: 'log',
      },
    ];

    const errors = validateDraft(draft);
    expect(errors).not.toContain('At least one block is required');
  });

  it('validates webhook trigger (which has no specific requirements)', () => {
    const draft = emptyDraft();
    draft.name = 'Webhook Trigger';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'webhook',
        token: 'webhook-token-123',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
    ];

    const errors = validateDraft(draft);
    expect(errors.length).toBe(0);
  });

  it('validates workflow trigger (which has no specific requirements)', () => {
    const draft = emptyDraft();
    draft.name = 'Workflow Trigger';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'workflow',
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
    ];

    const errors = validateDraft(draft);
    expect(errors.length).toBe(0);
  });

  it('validates sunEvent trigger (which has no specific validation in validateDraft)', () => {
    const draft = emptyDraft();
    draft.name = 'Sun Event Trigger';
    draft.triggers = [
      {
        _draftId: 'trigger-1',
        type: 'sunEvent',
        event: 'sunrise',
        offsetMinutes: 0,
      },
    ];
    draft.blocks = [
      {
        _draftId: 'block-1',
        block: 'action',
        type: 'controlDevice',
      },
    ];

    const errors = validateDraft(draft);
    expect(errors.length).toBe(0);
  });
});
