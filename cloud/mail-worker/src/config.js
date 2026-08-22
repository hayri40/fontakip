const requiredKeys = [
  'GMAIL_CLIENT_ID',
  'GMAIL_CLIENT_SECRET',
  'GMAIL_REFRESH_TOKEN',
  'GMAIL_SENDER_EMAIL',
];

export function loadConfig() {
  const config = {
    port: Number.parseInt(process.env.PORT ?? '8080', 10),
    projectId: process.env.GOOGLE_CLOUD_PROJECT ?? process.env.GCLOUD_PROJECT,
    gmailClientId: process.env.GMAIL_CLIENT_ID ?? '',
    gmailClientSecret: process.env.GMAIL_CLIENT_SECRET ?? '',
    gmailRefreshToken: process.env.GMAIL_REFRESH_TOKEN ?? '',
    gmailSenderEmail: process.env.GMAIL_SENDER_EMAIL ?? '',
    gmailSenderName:
      process.env.GMAIL_SENDER_NAME ?? 'FontTakip Bildirimleri',
    usersCollection: process.env.FIRESTORE_USERS_COLLECTION ?? 'users',
    preferencesCollection:
      process.env.FIRESTORE_PREFERENCES_COLLECTION ?? 'email_preferences',
    snapshotsCollection:
      process.env.FIRESTORE_SNAPSHOTS_COLLECTION ?? 'portfolio_snapshots',
  };

  const missingKeys = requiredKeys.filter((key) => {
    const value = process.env[key];
    return value == null || value.trim().length === 0;
  });

  if (missingKeys.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missingKeys.join(', ')}`,
    );
  }

  return config;
}
