const Icon = ({ children, size = 18 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{children}</svg>
)

export const HarnessIcon = ({ size }) => <Icon size={size}><path d="M5 4v16M19 4v16M5 12h14" /><circle cx="12" cy="12" r="2.5" /></Icon>
export const PlusIcon = () => <Icon><path d="M12 5v14M5 12h14" /></Icon>
export const SettingsIcon = () => <Icon><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-2.8 2.8-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.6v.2h-4V21a1.7 1.7 0 0 0-1-1.6 1.7 1.7 0 0 0-1.9.3l-.1.1L4.2 17l.1-.1a1.7 1.7 0 0 0 .3-1.9A1.7 1.7 0 0 0 3 14H2.8v-4H3a1.7 1.7 0 0 0 1.6-1 1.7 1.7 0 0 0-.3-1.9L4.2 7 7 4.2l.1.1A1.7 1.7 0 0 0 9 4.6 1.7 1.7 0 0 0 10 3V2.8h4V3a1.7 1.7 0 0 0 1 1.6 1.7 1.7 0 0 0 1.9-.3l.1-.1L19.8 7l-.1.1a1.7 1.7 0 0 0-.3 1.9 1.7 1.7 0 0 0 1.6 1h.2v4H21a1.7 1.7 0 0 0-1.6 1Z" /></Icon>
export const InspectIcon = () => <Icon><path d="M4 5h16v14H4zM8 9h8M8 13h5" /></Icon>
export const MoonIcon = () => <Icon><path d="M20.5 14.2A8 8 0 0 1 9.8 3.5 8.5 8.5 0 1 0 20.5 14.2Z" /></Icon>
export const SendIcon = () => <Icon><path d="m22 2-7 20-4-9-9-4Z" /><path d="M22 2 11 13" /></Icon>
export const StopIcon = () => <Icon><rect x="7" y="7" width="10" height="10" rx="1" /></Icon>
export const RenameIcon = () => <Icon size={15}><path d="m4 20 4.2-1 10.4-10.4a2.1 2.1 0 0 0-3-3L5.2 16Z" /><path d="m14.5 6.5 3 3" /></Icon>
export const TrashIcon = () => <Icon size={15}><path d="M4 7h16M9 7V4h6v3M7 7l1 13h8l1-13" /></Icon>
export const BackIcon = () => <Icon><path d="m15 18-6-6 6-6" /></Icon>
