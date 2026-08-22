import test from 'node:test';
import assert from 'node:assert/strict';

import { buildSummaryEmail } from '../src/emailFormatter.js';

test('buildSummaryEmail creates fund summary subject and body', () => {
  const result = buildSummaryEmail({
    summaryType: 'fund',
    recipientEmail: 'user@example.com',
    snapshot: {
      generatedAt: '2026-08-13T09:30:00.000Z',
      totalProfitLoss: 4520,
      totalPortfolioValue: 150000,
      items: [
        {
          code: 'ABC',
          name: 'ABC Fon',
          dailyChangePercent: 1.25,
        },
      ],
    },
  });

  assert.equal(result.subject, '📈 Günlük Fon Özeti');
  assert.match(result.text, /ABC Fon/);
  assert.match(result.text, /\+%1,25/);
  assert.match(result.text, /150\.000,00|₺150\.000,00/);
});
