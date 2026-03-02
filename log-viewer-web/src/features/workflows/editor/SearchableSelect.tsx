import { useState, useMemo, useCallback, useRef, useEffect } from 'react';
import { Icon } from '@/components/Icon';

export interface SelectOption {
  id: string;
  label: string;
  secondary?: string;
}

interface SearchableSelectProps {
  label: string;
  options: SelectOption[];
  selectedId: string;
  onSelect: (id: string) => void;
  onClear: () => void;
  placeholder: string;
}

export function SearchableSelect({
  label,
  options,
  selectedId,
  onSelect,
  onClear,
  placeholder,
}: SearchableSelectProps) {
  const [query, setQuery] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const [focusedIndex, setFocusedIndex] = useState(-1);
  const wrapRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const selectedLabel = useMemo(() => options.find((o) => o.id === selectedId)?.label ?? '', [options, selectedId]);

  const filtered = useMemo(() => {
    if (!query) return options;
    const q = query.toLowerCase();
    return options.filter(
      (o) => o.label.toLowerCase().includes(q) || (o.secondary ?? '').toLowerCase().includes(q),
    );
  }, [options, query]);

  // Close on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (wrapRef.current && !wrapRef.current.contains(e.target as Node)) {
        setIsOpen(false);
        setQuery('');
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        setFocusedIndex((prev) => Math.min(prev + 1, filtered.length - 1));
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        setFocusedIndex((prev) => Math.max(prev - 1, 0));
      } else if (e.key === 'Enter' && focusedIndex >= 0 && filtered[focusedIndex]) {
        e.preventDefault();
        onSelect(filtered[focusedIndex]!.id);
        setIsOpen(false);
        setQuery('');
        inputRef.current?.blur();
      } else if (e.key === 'Escape') {
        setIsOpen(false);
        setQuery('');
        inputRef.current?.blur();
      }
    },
    [filtered, focusedIndex, onSelect],
  );

  return (
    <div className="picker-field" ref={wrapRef}>
      <label>{label}</label>
      <div className="picker-input-wrap">
        <input
          ref={inputRef}
          className="picker-input"
          value={isOpen ? query : selectedLabel}
          placeholder={placeholder}
          onFocus={() => {
            setIsOpen(true);
            setQuery('');
            setFocusedIndex(-1);
          }}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={handleKeyDown}
        />
        {selectedId && (
          <button
            className="picker-clear"
            onClick={(e) => {
              e.stopPropagation();
              onClear();
              setQuery('');
            }}
            title="Clear"
            type="button"
          >
            <Icon name="xmark-circle-fill" size={14} />
          </button>
        )}
      </div>
      {isOpen && (
        <div className="picker-dropdown">
          {filtered.length === 0 ? (
            <div className="picker-empty">No results</div>
          ) : (
            filtered.map((opt, i) => (
              <div
                key={opt.id}
                className={`picker-option${i === focusedIndex ? ' focused' : ''}${opt.id === selectedId ? ' selected' : ''}`}
                onMouseDown={(e) => {
                  e.preventDefault();
                  onSelect(opt.id);
                  setIsOpen(false);
                  setQuery('');
                }}
                onMouseEnter={() => setFocusedIndex(i)}
              >
                <span>{opt.label}</span>
                {opt.secondary && <span className="picker-opt-secondary">{opt.secondary}</span>}
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}
