/**
 * Traces Supabase Google OAuth redirect chain without completing Google login.
 * Usage: node scripts/debug_google_oauth.mjs [appUrl]
 */
import { chromium } from 'playwright';

const appUrl = process.argv[2] ?? 'http://localhost:62746';
const loginUrl = `${appUrl.replace(/\/$/, '')}/#/login`;

function parseRedirectTo(url) {
  try {
    const u = new URL(url);
    return u.searchParams.get('redirect_to');
  } catch {
    return null;
  }
}

async function main() {
  console.log('=== Google OAuth debug ===');
  console.log('App URL:', appUrl);
  console.log('Login URL:', loginUrl);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 800, height: 900 } });
  const page = await context.newPage();

  const navigations = [];
  page.on('framenavigated', (frame) => {
    if (frame === page.mainFrame()) navigations.push(frame.url());
  });

  const responses = [];
  page.on('response', (res) => {
    const url = res.url();
    if (url.includes('supabase.co/auth') || url.includes('accounts.google.com')) {
      responses.push({ status: res.status(), url: url.slice(0, 200) });
    }
  });

  console.log('\n1. Loading login page…');
  const load = await page.goto(loginUrl, { waitUntil: 'networkidle', timeout: 30000 });
  console.log('   HTTP status:', load?.status());

  await page.waitForTimeout(2000);
  await page.screenshot({ path: '/tmp/oauth-login.png' });
  console.log('   Screenshot: /tmp/oauth-login.png');

  const popupPromise = context.waitForEvent('page', { timeout: 8000 }).catch(() => null);

  console.log('\n2. Clicking "Continue with Google" (canvas coords)…');
  for (const y of [250, 280, 310]) {
    await page.mouse.click(400, y);
    await page.waitForTimeout(800);
    if (navigations.some((u) => u.includes('supabase.co') || u.includes('google.com'))) break;
  }

  const popup = await popupPromise;
  if (popup) {
    await popup.waitForLoadState('domcontentloaded', { timeout: 10000 }).catch(() => {});
    console.log('   Popup opened:', popup.url().slice(0, 120));
    navigations.push(popup.url());
  }

  const current = page.url();
  console.log('   Current URL:', current);

  const supabaseNav = navigations.find((u) => u.includes('supabase.co/auth/v1/authorize'));
  const googleNav = navigations.find((u) => u.includes('accounts.google.com'));

  if (supabaseNav) {
    const redirectTo = parseRedirectTo(supabaseNav);
    console.log('\n3. Supabase authorize URL found');
    console.log('   redirect_to:', redirectTo ?? '(missing)');
    if (redirectTo) {
      const rt = new URL(redirectTo);
      console.log('   redirect host:', rt.host);
      console.log('   redirect port:', rt.port || '(default)');
      if (rt.host !== new URL(appUrl).host) {
        console.log('   ⚠ MISMATCH: redirect_to host ≠ app host');
        console.log('     App host:     ', new URL(appUrl).host);
        console.log('     redirect_to:  ', rt.host);
      } else {
        console.log('   ✓ redirect_to matches app host');
      }
    }
  } else if (googleNav) {
    console.log('\n3. Jumped straight to Google (popup or redirect)');
    const state = new URL(googleNav).searchParams.get('state');
    console.log('   Google URL (truncated):', googleNav.slice(0, 120) + '…');
    if (state) console.log('   state param present: yes');
  } else {
    console.log('\n3. ⚠ No Supabase/Google navigation detected after click');
    console.log('   All navigations:', navigations);
  }

  if (responses.length) {
    console.log('\n4. Auth-related HTTP responses:');
    for (const r of responses) console.log(`   ${r.status} ${r.url}`);
  }

  // Probe Supabase provider directly
  console.log('\n5. Probing Supabase authorize endpoint…');
  const probeRedirect = appUrl.replace(/\/$/, '');
  const probeUrl =
    `https://lxcbaortmbhjsthycdkt.supabase.co/auth/v1/authorize?provider=google&redirect_to=${encodeURIComponent(probeRedirect)}`;
  const probe = await page.request.get(probeUrl, { maxRedirects: 0 }).catch((e) => e);
  if (probe?.status) {
    console.log('   Status:', probe.status());
    const loc = probe.headers()['location'];
    if (loc) {
      console.log('   Location (truncated):', loc.slice(0, 150) + '…');
      if (loc.includes('accounts.google.com')) {
        console.log('   ✓ Google provider is ENABLED on Supabase');
      } else if (loc.includes('error') || probe.status() >= 400) {
        console.log('   ✗ Provider may be misconfigured');
      }
    }
  } else {
    console.log('   Probe error:', String(probe));
  }

  // Test callback port reachability
  console.log('\n6. Callback port check…');
  for (const port of [3000, 8080, new URL(appUrl).port || '80']) {
    if (!port || port === '80') continue;
    try {
      const r = await page.request.get(`http://localhost:${port}/`, { timeout: 2000 });
      console.log(`   localhost:${port} → HTTP ${r.status()}`);
    } catch {
      console.log(`   localhost:${port} → NOT REACHABLE (connection refused)`);
    }
  }

  await browser.close();
  console.log('\n=== Done ===');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
