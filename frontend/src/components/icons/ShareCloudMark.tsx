interface ShareCloudMarkProps {
  size?: number;
  className?: string;
  title?: string;
}

/**
 * Original ShareCloud product mark.
 *
 * This is deliberately not the PwC logo: it is an application-specific knowledge
 * mark that uses a PwC-aligned warm palette while avoiding unapproved corporate
 * logo reproduction.
 */
export const ShareCloudMark: React.FC<ShareCloudMarkProps> = ({
  size = 32,
  className,
  title,
}) => (
  <svg
    className={className}
    width={size}
    height={size}
    viewBox="0 0 48 48"
    role={title ? 'img' : 'presentation'}
    aria-hidden={title ? undefined : true}
    aria-label={title}
    focusable="false"
  >
    <rect x="5" y="15" width="24" height="25" rx="3" fill="#A32020" />
    <rect x="12" y="8" width="26" height="27" rx="3" fill="#D04A02" />
    <rect x="21" y="4" width="22" height="23" rx="3" fill="#EB8C00" />
    <path
      d="M18 17h13M18 22h9M18 27h12"
      stroke="#FFFFFF"
      strokeWidth="2"
      strokeLinecap="round"
      opacity="0.94"
    />
  </svg>
);
