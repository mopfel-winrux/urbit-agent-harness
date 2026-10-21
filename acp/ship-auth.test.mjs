import assert from 'node:assert/strict';
import test from 'node:test';
import { guestDeskHeaders, loginDesk, requestHeaders } from './ship-auth.mjs';

test('key clients obtain a guest cookie without sending a login code', async () => {
  const replies = [
    [303, { location: '//ship.example/~/holm/sink/harness/~/name' }],
    [303, { location: '//harness.ship.example/~/holm/gain/0v1', 'set-cookie': '__Host-urbauth-~zod=guest-root' }],
    [303, { location: '/~/name', 'set-cookie': '__Host-urbauth-~zod=guest-desk' }],
    [200, {}],
  ];
  const headers = await guestDeskHeaders('https://harness.ship.example', async (url, options) => {
    assert.notEqual(url.pathname, '/~/login');
    assert.equal(options.body, undefined);
    const [status, headers] = replies.shift();
    return new Response('', { status, headers });
  });
  assert.equal(headers.cookie, '__Host-urbauth-~zod=guest-desk');
  assert.equal(headers.origin, 'https://harness.ship.example');
});

test('login follows desk scoping and keeps cookies on their own origins', async () => {
  const steps = [
    ['https://ship.example/~/login', 200, { 'set-cookie': '__Host-urbauth-~zod=root; Secure' }],
    ['https://harness.ship.example/~/holm/jump/~/name', 303, { location: '//ship.example/~/holm/sink/harness/~/name' }],
    ['https://ship.example/~/holm/sink/harness/~/name', 303, { location: '//harness.ship.example/~/holm/gain/0v1' }],
    ['https://harness.ship.example/~/holm/gain/0v1', 303, { location: '/~/name', 'set-cookie': '__Host-urbauth-~zod=desk; Secure' }],
    ['https://harness.ship.example/~/name', 200, {}],
  ];
  const seen = [];
  const result = await loginDesk('https://harness.ship.example', 'test-code', async (url, options) => {
    const [expected, status, headers] = steps.shift();
    assert.equal(url.href, expected);
    assert.deepEqual(requestHeaders(url), { origin: url.origin, 'sec-fetch-site': 'same-origin' });
    assert.equal(options.redirect, 'manual');
    seen.push(options);
    return new Response('', { status, headers });
  });
  assert.equal(steps.length, 0);
  assert.equal(seen[0].body, 'password=test-code');
  assert.deepEqual(seen.map(step => step.headers.cookie), [undefined, undefined, '__Host-urbauth-~zod=root', undefined, '__Host-urbauth-~zod=desk']);
  assert.deepEqual(result, { cookie: '__Host-urbauth-~zod=desk', shipName: 'zod' });
});

test('login refuses redirects outside the ship before sending a cookie', async () => {
  let requests = 0;
  await assert.rejects(loginDesk('https://harness.ship.example', 'test-code', async () => {
    requests++;
    return requests === 1
      ? new Response('', { headers: { 'set-cookie': 'urbauth-~zod=root' } })
      : new Response('', { status: 303, headers: { location: 'https://another.example/' } });
  }), /Unexpected desk login redirect/);
  assert.equal(requests, 2);
});

test('loopback login sends the matching origin and checks failures', async () => {
  const result = await loginDesk('http://localhost:8081', 'test-code', async (url, options) => {
    assert.equal(url.href, 'http://localhost:8081/~/login');
    assert.equal(options.headers.origin, 'http://localhost:8081');
    return new Response('', { headers: { 'set-cookie': 'urbauth-~zod=local' } });
  });
  assert.equal(result.shipName, 'zod');
  await assert.rejects(loginDesk('http://localhost:8081', 'bad-code', async () => new Response('', { status: 400 })), /login failed: 400/);
});
