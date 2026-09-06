import { Button } from '@fluentui/react-components';
import { Add20Regular } from '@fluentui/react-icons';
import { ShareCloudMark } from './icons/ShareCloudMark';
import styles from './ShareCloudHeader.module.css';

interface ShareCloudHeaderProps {
  onNewChat?: () => void;
  disabled?: boolean;
}

export const ShareCloudHeader: React.FC<ShareCloudHeaderProps> = ({
  onNewChat,
  disabled = false,
}) => (
  <header className={styles.header}>
    <div className={styles.lockup}>
      <ShareCloudMark size={42} title="ShareCloud Bids" />
      <div className={styles.titleGroup}>
        <span className={styles.title}>ShareCloud Bids</span>
        <span className={styles.subtitle}>Evidence-led bid discovery and drafting</span>
      </div>
    </div>

    {onNewChat && (
      <Button
        appearance="primary"
        icon={<Add20Regular />}
        onClick={onNewChat}
        disabled={disabled}
        className={styles.newChatButton}
      >
        New chat
      </Button>
    )}
  </header>
);
