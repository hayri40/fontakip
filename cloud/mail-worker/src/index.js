import express from 'express';

import { loadConfig } from './config.js';
import { createFirestoreRepository } from './firestoreRepository.js';
import { createGmailClient } from './gmailClient.js';
import { createSummaryWorker } from './summaryWorker.js';

const config = loadConfig();
const repository = createFirestoreRepository(config);
const gmailClient = createGmailClient(config);
const summaryWorker = createSummaryWorker({ repository, gmailClient });

const app = express();
app.use(express.json());

app.get('/healthz', (_request, response) => {
  response.status(200).json({
    ok: true,
    service: 'fontakip-mail-worker',
  });
});

app.post('/jobs/fund-summary', async (_request, response) => {
  try {
    const result = await summaryWorker.runFundSummaries();
    response.status(200).json(result);
  } catch (error) {
    console.error('Fund summary job failed', error);
    response.status(500).json({
      error: 'fund-summary-failed',
      message: error instanceof Error ? error.message : String(error),
    });
  }
});

app.post('/jobs/stock-summary', async (_request, response) => {
  try {
    const result = await summaryWorker.runStockSummaries();
    response.status(200).json(result);
  } catch (error) {
    console.error('Stock summary job failed', error);
    response.status(500).json({
      error: 'stock-summary-failed',
      message: error instanceof Error ? error.message : String(error),
    });
  }
});

app.listen(config.port, () => {
  console.log(`fontakip-mail-worker listening on port ${config.port}`);
});
