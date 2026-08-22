import test from 'node:test';
import assert from 'node:assert/strict';

import { createSummaryWorker } from '../src/summaryWorker.js';

test('summary worker skips holiday runs and logs holiday_skip', async () => {
  const calls = [];
  const worker = createSummaryWorker({
    repository: {
      async listRecipientsForSummary() {
        calls.push('list');
        return [];
      },
      async markSummarySent() {
        calls.push('mark');
      },
    },
    gmailClient: {
      async sendMail() {
        calls.push('send');
      },
    },
    calendar: {
      isMarketOpen() {
        return false;
      },
    },
    logger: {
      info(message) {
        calls.push(message);
      },
    },
  });

  const result = await worker.runFundSummaries();

  assert.deepEqual(result, {
    summaryType: 'fund',
    processedCount: 0,
    sentCount: 0,
    skippedCount: 0,
    skippedReason: 'holiday_skip',
    sentAt: result.sentAt,
  });
  assert.equal(calls.length, 1);
  assert.match(calls[0], /reason":"holiday_skip"/);
});

test('summary worker sends mail on open days', async () => {
  const calls = [];
  const worker = createSummaryWorker({
    repository: {
      async listRecipientsForSummary() {
        return [
          {
            userId: 'user-1',
            recipientEmail: 'user@example.com',
            snapshot: {
              generatedAt: '2026-08-14T09:00:00.000Z',
              totalProfitLoss: 100,
              totalPortfolioValue: 1000,
              items: [
                {
                  code: 'ABC',
                  name: 'ABC Fon',
                  dailyChangePercent: 1.25,
                },
              ],
            },
          },
        ];
      },
      async markSummarySent(payload) {
        calls.push(['mark', payload.userId, payload.summaryType]);
      },
    },
    gmailClient: {
      async sendMail(payload) {
        calls.push(['send', payload.toEmail, payload.subject]);
      },
    },
    calendar: {
      isMarketOpen() {
        return true;
      },
    },
    logger: {
      info() {},
      error() {},
    },
  });

  const result = await worker.runFundSummaries();

  assert.equal(result.sentCount, 1);
  assert.equal(result.processedCount, 1);
  assert.equal(result.skippedReason, null);
  assert.deepEqual(calls, [
    ['send', 'user@example.com', '📈 Günlük Fon Özeti'],
    ['mark', 'user-1', 'fund'],
  ]);
});
