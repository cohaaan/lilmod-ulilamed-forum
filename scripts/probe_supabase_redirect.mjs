/** Quick probe: what redirect_to does Supabase use for each origin? */
const origins = [
  'http://localhost:62746',
  'http://localhost:3000',
  'http://localhost:8080',
  'https://lilmod-ulilamed.vercel.app',
];

for (const origin of origins) {
  const url = `https://lxcbaortmbhjsthycdkt.supabase.co/auth/v1/authorize?provider=google&redirect_to=${encodeURIComponent(origin)}`;
  const res = await fetch(url, { redirect: 'manual' });
  const loc = res.headers.get('location') ?? '';
  const match = loc.match(/redirect_to=([^&]+)/);
  const rt = match ? decodeURIComponent(match[1]) : '(not in location — check state/JWT)';
  console.log(`\nApp origin: ${origin}`);
  console.log(`  Supabase status: ${res.status}`);
  if (loc.includes('accounts.google.com')) {
    console.log(`  → Google OAuth OK`);
    // redirect_to is often embedded in state, not visible in Google URL
    console.log(`  Requested redirect_to: ${origin}`);
  } else if (loc.includes('error') || res.status >= 400) {
    console.log(`  → ERROR location: ${loc.slice(0, 200)}`);
  } else {
    console.log(`  → location: ${loc.slice(0, 120)}`);
  }
}
