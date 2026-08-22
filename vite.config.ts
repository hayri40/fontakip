import { defineConfig, Plugin } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

// Safe stream reader that never hangs
function readStreamBody(req: any): Promise<string> {
  return new Promise((resolve) => {
    if (req.body && typeof req.body === 'object') {
      try {
        return resolve(JSON.stringify(req.body));
      } catch {
        return resolve('');
      }
    }
    if (typeof req.body === 'string') {
      return resolve(req.body);
    }
    if (req.readableEnded || req.complete) {
      return resolve('');
    }
    let data = '';
    const onData = (chunk: any) => {
      data += chunk.toString();
    };
    const onEnd = () => {
      cleanup();
      resolve(data);
    };
    const onError = () => {
      cleanup();
      resolve(data);
    };
    const timer = setTimeout(() => {
      cleanup();
      resolve(data);
    }, 1500);

    const cleanup = () => {
      clearTimeout(timer);
      req.removeListener('data', onData);
      req.removeListener('end', onEnd);
      req.removeListener('error', onError);
    };

    req.on('data', onData);
    req.on('end', onEnd);
    req.on('error', onError);
  });
}

// API proxy middleware to bypass browser CORS in dev and preview modes
function devApiProxyPlugin(): Plugin {
  const handler = async (req: any, res: any, next: any) => {
    const rawUrl = req.url || '';

    if (rawUrl.startsWith('/api/proxy')) {
      // Handle CORS preflight requests
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-API-Key, x-api-key, x-api-token, apikey, *');

      if (req.method === 'OPTIONS') {
        res.statusCode = 204;
        res.end();
        return;
      }

      try {
        const urlObj = new URL(rawUrl, `http://${req.headers.host || 'localhost'}`);
        let targetUrl = urlObj.searchParams.get('url') || '';
        let queryApiKey = urlObj.searchParams.get('apiKey') || urlObj.searchParams.get('apikey') || urlObj.searchParams.get('x-api-key') || '';

        let body: any = {};
        if (req.method === 'POST' || req.method === 'PUT') {
          const rawBody = await readStreamBody(req);
          if (rawBody) {
            try {
              body = JSON.parse(rawBody);
            } catch {
              body = {};
            }
          }
        }

        if (!targetUrl && body?.url) {
          targetUrl = body.url;
        }

        if (!targetUrl) {
          res.statusCode = 400;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ error: 'Missing target url parameter' }));
          return;
        }

        const headers: Record<string, string> = {};

        // Forward accept if present
        if (req.headers['accept']) {
          headers['Accept'] = String(req.headers['accept']);
        } else {
          headers['Accept'] = 'application/json, text/plain, */*';
        }

        // Priority for API Key from query, body, or headers
        const apiKey = queryApiKey || 
          req.headers['x-api-key'] || 
          req.headers['X-API-Key'] || 
          req.headers['apikey'] || 
          body?.apiKey || 
          (body?.headers && (body.headers['X-API-Key'] || body.headers['x-api-key'] || body.headers['apikey']));

        if (apiKey) {
          headers['X-API-Key'] = String(apiKey).trim();
        }

        headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

        const method = (req.method === 'GET' ? (urlObj.searchParams.get('method') || 'GET') : (body?.method || 'GET')).toUpperCase();
        
        const fetchOptions: RequestInit = {
          method,
          headers,
        };

        if (method !== 'GET' && method !== 'HEAD' && body?.body) {
          fetchOptions.body = typeof body.body === 'string' ? body.body : JSON.stringify(body.body);
        }

        // Upstream fetch with 8s abort timeout
        const controller = new AbortController();
        const fetchTimer = setTimeout(() => controller.abort(), 8000);
        fetchOptions.signal = controller.signal;

        try {
          const upstreamRes = await fetch(targetUrl, fetchOptions);
          clearTimeout(fetchTimer);

          res.statusCode = upstreamRes.status;
          const contentType = upstreamRes.headers.get('content-type') || 'application/json';
          res.setHeader('Content-Type', contentType);

          const data = await upstreamRes.arrayBuffer();
          res.end(Buffer.from(data));
        } catch (fetchErr: any) {
          clearTimeout(fetchTimer);
          res.statusCode = 502;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ 
            error: 'Upstream servise ulaşılamadı: ' + (fetchErr.name === 'AbortError' ? 'Zaman aşımı (8s)' : (fetchErr.message || 'Bağlantı hatası')),
            url: targetUrl,
          }));
        }
      } catch (err: any) {
        console.error('Dev Proxy Middleware Error:', err);
        res.statusCode = 500;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ error: 'Proxy iç hatası: ' + (err.message || 'Bilinmeyen hata') }));
      }
      return;
    }
    next();
  };

  return {
    name: 'dev-api-proxy',
    configureServer(server) {
      server.middlewares.use(handler);
    },
    configurePreviewServer(server) {
      server.middlewares.use(handler);
    },
  };
}

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss(), devApiProxyPlugin()],
  server: {
    host: '0.0.0.0',
    port: 3000,
    allowedHosts: true,
  },
  preview: {
    host: '0.0.0.0',
    port: 3000,
    allowedHosts: true,
  },
});
