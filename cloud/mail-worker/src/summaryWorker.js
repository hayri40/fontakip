import { buildSummaryEmail } from './emailFormatter.js';
import { createTurkeyMarketCalendar } from './marketCalendar.js';

function logHolidaySkip(logger, payload) {
  const message = JSON.stringify({
    reason: 'holiday_skip',
    ...payload,
  });

  if (typeof logger.info === 'function') {
    logger.info(message);
    return;
  }

  if (typeof logger.log === 'function') {
    logger.log(message);
    return;
  }

  console.log(message);
}

export function createSummaryWorker({
  repository,
  gmailClient,
  calendar = createTurkeyMarketCalendar(),
  logger = console,
}) {
  async function run(summaryType) {
    const sentAt = new Date();

    if (!calendar.isMarketOpen(sentAt)) {
      logHolidaySkip(logger, {
        summaryType,
        sentAt: sentAt.toISOString(),
      });

      return {
        summaryType,
        processedCount: 0,
        sentCount: 0,
        skippedCount: 0,
        skippedReason: 'holiday_skip',
        sentAt: sentAt.toISOString(),
      };
    }

    const recipients = await repository.listRecipientsForSummary(summaryType);
    let sentCount = 0;
    let skippedCount = 0;

    for (const recipient of recipients) {
      if (!recipient.snapshot?.items?.length) {
        skippedCount += 1;
        continue;
      }

      const email = buildSummaryEmail({
        summaryType,
        recipientEmail: recipient.recipientEmail,
        snapshot: recipient.snapshot,
      });

      try {
        await gmailClient.sendMail({
          toEmail: recipient.recipientEmail,
          subject: email.subject,
          text: email.text,
        });
        await repository.markSummarySent({
          userId: recipient.userId,
          summaryType,
          sentAt,
        });
        sentCount += 1;
      } catch (error) {
        logger.error(
          `Failed to send ${summaryType} summary for ${recipient.userId}:`,
          error,
        );
      }
    }

    return {
      summaryType,
      processedCount: recipients.length,
      sentCount,
      skippedCount,
      skippedReason: null,
      sentAt: sentAt.toISOString(),
    };
  }

  return {
    runFundSummaries() {
      return run('fund');
    },
    runStockSummaries() {
      return run('stock');
    },
  };
}
