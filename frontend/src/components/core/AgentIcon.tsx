import { ShareCloudMark } from '../icons/ShareCloudMark';
import styles from './AgentIcon.module.css';

interface AgentIconProps {
  alt?: string;
  size?: 'small' | 'medium' | 'large';
  logoUrl?: string;
}

const sizeMap = {
  small: 32,
  medium: 40,
  large: 48,
} as const;

export function AgentIcon({
  alt = 'ShareCloud Bids',
  size = 'medium',
  logoUrl,
}: AgentIconProps) {
  const pixels = sizeMap[size];
  const hasApprovedCustomLogo = Boolean(
    logoUrl && !logoUrl.toLowerCase().includes('avatar_default')
  );

  if (hasApprovedCustomLogo) {
    return (
      <img
        src={logoUrl}
        alt={alt}
        width={pixels}
        height={pixels}
        className={styles.customLogo}
      />
    );
  }

  return (
    <span
      className={styles.markContainer}
      role="img"
      aria-label={alt}
      style={{ width: pixels, height: pixels }}
    >
      <ShareCloudMark size={Math.round(pixels * 0.72)} />
    </span>
  );
}
