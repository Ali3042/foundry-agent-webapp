import { Button, Tooltip } from '@fluentui/react-components';
import { Info16Regular } from '@fluentui/react-icons';
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
}) => (
  <section className={styles.contextBar} aria-label="Response context">
    <div className={styles.controlGroup}>
      <span id="interaction-mode-label" className={styles.label}>Mode</span>
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

    <label className={`${styles.controlGroup} ${styles.industryGroup}`}>
      <span className={styles.label}>Industry</span>
      <select
        className={styles.select}
        value={industryContext}
        disabled={disabled}
        onChange={(event) => onIndustryContextChange(event.target.value as IndustryContext)}
      >
        <option value="">All industries</option>
        {INDUSTRY_CONTEXTS.map((industry) => (
          <option key={industry} value={industry}>{industry}</option>
        ))}
      </select>
    </label>

    <Tooltip
      content="Mode and industry guide the response; they do not restrict retrieval. An explicit request always takes precedence."
      relationship="description"
      positioning="above"
    >
      <Button
        appearance="subtle"
        size="small"
        icon={<Info16Regular />}
        aria-label="About response context"
        className={styles.infoButton}
      />
    </Tooltip>
  </section>
);
