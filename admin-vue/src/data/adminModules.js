import chatIcon from '../assets/skino-icon-chat.png'
import contactsIcon from '../assets/skino-icon-history.png'
import crmIcon from '../assets/skino-nav-chat.png'
import routineIcon from '../assets/skino-icon-routine.png'
import scanIcon from '../assets/skino-icon-scan.png'

export const adminModules = [
  {
    title: 'Contacts',
    subtitle: 'Users, specialists, leads, and notes',
    accent: '#f98128',
    icon: 'people',
    image: contactsIcon,
  },
  {
    title: 'CRM',
    subtitle: 'Specialist appointment cards and follow-up',
    accent: '#0e5c56',
    icon: 'calendar',
    image: crmIcon,
  },
  {
    title: 'Care',
    subtitle: 'Routine progress and follow-up operations',
    accent: '#f98128',
    icon: 'spark',
    image: routineIcon,
  },
  {
    title: 'Scan Review',
    subtitle: 'Scan quality, results, bad scan review',
    accent: '#0e5c56',
    icon: 'chart',
    image: scanIcon,
  },
  {
    title: 'AI Training',
    subtitle: 'Consented samples and label review',
    accent: '#f98128',
    icon: 'spark',
    image: chatIcon,
  },
]
