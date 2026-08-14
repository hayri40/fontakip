import { google } from 'googleapis';

function encodeHeader(value) {
  return `=?UTF-8?B?${Buffer.from(value, 'utf8').toString('base64')}?=`;
}

function toBase64Url(value) {
  return Buffer.from(value, 'utf8')
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');
}

function buildRawMessage({
  fromName,
  fromEmail,
  toEmail,
  subject,
  text,
}) {
  const headers = [
    `From: ${encodeHeader(fromName)} <${fromEmail}>`,
    `To: ${toEmail}`,
    `Subject: ${encodeHeader(subject)}`,
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset="UTF-8"',
    'Content-Transfer-Encoding: 8bit',
    '',
    text,
  ];
  return toBase64Url(headers.join('\r\n'));
}

export function createGmailClient(config) {
  const oauth2Client = new google.auth.OAuth2(
    config.gmailClientId,
    config.gmailClientSecret,
  );
  oauth2Client.setCredentials({
    refresh_token: config.gmailRefreshToken,
  });

  const gmail = google.gmail({
    version: 'v1',
    auth: oauth2Client,
  });

  return {
    async sendMail({ toEmail, subject, text }) {
      const raw = buildRawMessage({
        fromName: config.gmailSenderName,
        fromEmail: config.gmailSenderEmail,
        toEmail,
        subject,
        text,
      });

      const response = await gmail.users.messages.send({
        userId: 'me',
        requestBody: { raw },
      });

      return response.data;
    },
  };
}
