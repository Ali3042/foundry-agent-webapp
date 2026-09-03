import {
  INDUSTRY_CONTEXTS,
  INTERACTION_MODES,
  type IndustryContext,
  type InteractionMode,
} from '../types/sharecloud';
import styles from './ShareCloudContextBar.module.css';

interface ShareCloudContextBarProps {
  interactionMode: InteractionMode;
  industryContext: IndustryContext;
  disabled?: boolean;
  onInteractionModeChange: (mode: InteractionMode) => void;
  onIndustryContextChange: (industry: IndustryContext) => void;
}

export const ShareCloudContextBar: React.FC<ShareCloudContextBarProps> = ({
  interactionMode,
  industryContext,
  disabled = false,
  onInteractionModeChange,
  onIndustryContextChange,
}) => {
  return (
    <section className={styles.contextBar} aria-label="Response context">
      <div className={styles.fieldGroup}>
        <span id="interaction-mode-label" className={styles.label}>
          Interaction mode
        </span>
        <div
          className={styles.segmentedControl}
          role="radiogroup"
          aria-labelledby="interaction-mode-label"
        >
          {INTERACTION_MODES.map((mode) => {
            const isSelected = interactionMode === mode;
            return (
              <button
                key={mode}
                type="button"
                role="radio"
                aria-checked={isSelected}
                className={`${styles.segmentButton} ${isSelected ? styles.segmentButtonSelected : ''}`}
                disabled={disabled}
                onClick={() => onInteractionModeChange(mode)}
              >
                {mode}
              </button>
            );
          })}
        </div>
      </div>

      <label className={styles.fieldGroup}>
        <span className={styles.label}>
          Industry context <span className={styles.optional}>Optional</span>
        </span>
        <select
          className={styles.select}
          value={industryContext}
          disabled={disabled}
          onChange={(event) => onIndustryContextChange(event.target.value as IndustryContext)}
        >
          <option value="">All industries</option>
          {INDUSTRY_CONTEXTS.map((industry) => (
            <option key={industry} value={industry}>
              {industry}
            </option>
          ))}
        </select>
      </label>

      <p className={styles.helperText}>
        Context guides the response; it does not restrict retrieval. An explicit request takes precedence.
      </p>
    </section>
  );
};
