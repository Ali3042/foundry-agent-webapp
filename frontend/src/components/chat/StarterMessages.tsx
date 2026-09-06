import type { ReactNode } from 'react';
import styles from './StarterMessages.module.css';

interface IStarterMessageProps {
  agentName?: string;
  agentDescription?: string;
  agentLogo?: string;
  starterPrompts?: string[];
  onPromptClick?: (prompt: string) => void;
}

const promptTemplates = [
  {
    kind: 'Find evidence',
    prompt: 'Find relevant <Sector> credentials for <Capability>',
  },
  {
    kind: 'Compare evidence',
    prompt: 'Compare our evidence against <Client requirement>',
  },
  {
    kind: 'Draft a response',
    prompt: 'Draft a <150-word> response to <Bid question>',
  },
] as const;

const renderTemplate = (prompt: string): ReactNode[] =>
  prompt.split(/(<[^>]+>)/g).filter(Boolean).map((part, index) =>
    /^<[^>]+>$/.test(part)
      ? <span key={`${part}-${index}`} className={styles.token}>{part}</span>
      : <span key={`${part}-${index}`}>{part}</span>
  );

/**
 * Product-specific empty state. Prompt templates populate the composer for editing;
 * they are not submitted immediately.
 */
export const StarterMessages = ({ onPromptClick }: IStarterMessageProps): ReactNode => (
  <div className={styles.zeroPrompt}>
    <div className={styles.content}>
      <span className={styles.eyebrow}>Trusted organisational knowledge</span>
      <h1 className={styles.heading}>Find trusted evidence. Draft with confidence.</h1>
      <p className={styles.caption}>
        Search ShareCloud&apos;s curated knowledge and turn it into review-ready bid material.
      </p>
    </div>

    {onPromptClick && (
      <ul className={styles.promptList} aria-label="Prompt templates">
        {promptTemplates.map(({ kind, prompt }) => (
          <li key={kind}>
            <button
              className={styles.promptCard}
              onClick={() => onPromptClick(prompt)}
              type="button"
              aria-label={`${kind}: ${prompt}`}
            >
              <span className={styles.promptKind}>{kind}</span>
              <span className={styles.promptText}>{renderTemplate(prompt)}</span>
            </button>
          </li>
        ))}
      </ul>
    )}

    <p className={styles.helper}>Select a template to edit it before sending.</p>
  </div>
);
