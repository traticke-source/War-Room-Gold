export default function handler(_req, res) {
  const url = process.env.SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY;
  if (!url || !anonKey) return res.status(503).json({ configured: false });
  res.setHeader('Cache-Control', 'public, max-age=300');
  return res.status(200).json({ configured: true, url, anonKey });
}
