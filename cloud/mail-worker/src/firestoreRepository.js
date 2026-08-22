import { Firestore } from '@google-cloud/firestore';

export function createFirestoreRepository(config) {
  const firestore = new Firestore({
    projectId: config.projectId,
  });

  return {
    async listRecipientsForSummary(summaryType) {
      const enabledField =
        summaryType === 'fund' ? 'fundSummaryEnabled' : 'stockSummaryEnabled';
      const snapshotField =
        summaryType === 'fund' ? 'fundSnapshot' : 'stockSnapshot';

      const preferenceSnapshot = await firestore
        .collection(config.preferencesCollection)
        .where(enabledField, '==', true)
        .get();

      const recipients = [];
      for (const documentSnapshot of preferenceSnapshot.docs) {
        const userId = documentSnapshot.id;
        const preferences = documentSnapshot.data();

        const [userDocument, snapshotDocument] = await Promise.all([
          firestore.collection(config.usersCollection).doc(userId).get(),
          firestore.collection(config.snapshotsCollection).doc(userId).get(),
        ]);

        if (!userDocument.exists || !snapshotDocument.exists) {
          continue;
        }

        const user = userDocument.data() ?? {};
        const snapshots = snapshotDocument.data() ?? {};
        const summarySnapshot = snapshots[snapshotField];

        if (user.isGoogleLinked !== true) {
          continue;
        }

        const recipientEmail = preferences.recipientEmail ?? user.googleEmail;
        if (
          typeof recipientEmail !== 'string' ||
          recipientEmail.trim().length === 0
        ) {
          continue;
        }

        if (
          !summarySnapshot ||
          !Array.isArray(summarySnapshot.items) ||
          summarySnapshot.items.length === 0
        ) {
          continue;
        }

        recipients.push({
          userId,
          recipientEmail,
          snapshot: summarySnapshot,
        });
      }

      return recipients;
    },

    async markSummarySent({ userId, summaryType, sentAt }) {
      const fieldName =
        summaryType === 'fund' ? 'lastFundSentAt' : 'lastStockSentAt';
      await firestore
        .collection(config.preferencesCollection)
        .doc(userId)
        .set(
          {
            [fieldName]: sentAt.toISOString(),
            updatedAt: sentAt.toISOString(),
          },
          { merge: true },
        );
    },
  };
}
