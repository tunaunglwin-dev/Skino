export const contactFields = [
  {
    group: 'Identity',
    fields: ['Display name', 'Contact type', 'Status', 'Source'],
  },
  {
    group: 'Real account link',
    fields: ['Linked user ID', 'Gmail email', 'Primary email', 'Avatar'],
  },
  {
    group: 'Contact details',
    fields: ['Phone', 'Specialty', 'Company', 'Tags'],
  },
  {
    group: 'Operations',
    fields: ['Internal note', 'Last seen', 'CRM notes', 'Module history'],
  },
]

export const contactWorkflow = [
  'Google login creates or updates a user contact automatically.',
  'Admin can create manual contacts for specialists, sellers, vendors, or leads.',
  'Notes stay on the contact and later connect to CRM, orders, appointments, and scan history.',
  'Every module should reference contact_id instead of copying customer/vendor data.',
]

export const contactSamples = [
  {
    name: 'Aye Chan',
    type: 'App user',
    email: 'ayechan@gmail.com',
    source: 'Google',
    status: 'Active',
  },
  {
    name: 'Dr. Hnin Wadi',
    type: 'Specialist',
    email: 'clinic@example.com',
    source: 'Manual',
    status: 'Active',
  },
  {
    name: 'Glow Partner Co.',
    type: 'Vendor',
    email: 'sales@glow.test',
    source: 'Manual',
    status: 'Review',
  },
]
