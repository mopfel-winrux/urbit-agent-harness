export function requestHeaders(url) {
  return { origin: new URL(url).origin, 'sec-fetch-site': 'same-origin' };
}

async function deskCookie(shipUrl, code, fetcher) {
  const desk = new URL(shipUrl);
  const root = new URL(desk);
  if (root.hostname.startsWith('harness.')) root.hostname = root.hostname.slice(8);
  const allowed = new Set([desk.origin, root.origin]);
  const cookies = new Map();
  const remember = (url, response) => {
    const cookie = (response.headers.get('set-cookie') || '').split(';')[0];
    if (cookie) cookies.set(url.origin, cookie);
  };
  if (code !== undefined) {
    const response = await fetcher(new URL('/~/login', root), {
      method: 'POST',
      redirect: 'manual',
      signal: AbortSignal.timeout(15_000),
      headers: { ...requestHeaders(root), 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ password: code }).toString(),
    });
    if (!response.ok) throw new Error(`login failed: ${response.status}`);
    remember(root, response);
    await response.text();
  }
  if (desk.origin !== root.origin) {
    let url = new URL('/~/holm/jump/~/name', desk);
    for (let redirects = 0; ; redirects++) {
      if (!allowed.has(url.origin) || redirects > 5) throw new Error('Unexpected desk login redirect');
      const next = await fetcher(url, {
        redirect: 'manual',
        signal: AbortSignal.timeout(15_000),
        headers: { ...requestHeaders(url), ...(cookies.has(url.origin) ? { cookie: cookies.get(url.origin) } : {}) },
      });
      remember(url, next);
      await next.text();
      if (next.status !== 303) {
        if (!next.ok) throw new Error(`desk login failed: ${next.status}`);
        break;
      }
      const location = next.headers.get('location');
      if (!location) throw new Error('Desk login redirect has no location');
      url = new URL(location, url);
    }
    if (!cookies.has(desk.origin)) throw new Error('Desk handshake returned no cookie');
  }
  return cookies.get(desk.origin);
}

export async function guestDeskHeaders(shipUrl, fetcher = fetch) {
  const cookie = await deskCookie(shipUrl, undefined, fetcher);
  return { ...requestHeaders(shipUrl), ...(cookie ? { cookie } : {}) };
}

export async function loginDesk(shipUrl, code, fetcher = fetch) {
  const cookie = await deskCookie(shipUrl, code, fetcher);
  const match = cookie?.match(/(?:__Host-)?urbauth-~([\w-]+)=/);
  if (!match) throw new Error('login: no ship cookie');
  return { cookie, shipName: match[1] };
}
