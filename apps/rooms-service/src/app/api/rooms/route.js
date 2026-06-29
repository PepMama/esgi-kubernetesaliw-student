import { Pool } from "pg";

export const dynamic = "force-dynamic";

let pool;
function getPool() {
  if (!pool && process.env.DATABASE_URL) pool = new Pool({ connectionString: process.env.DATABASE_URL });
  return pool;
}

const FALLBACK = [
  { id: 1, site_id: 1, name: "Versailles",  capacity: 12 },
  { id: 2, site_id: 1, name: "Concorde",    capacity: 8 },
  { id: 3, site_id: 2, name: "Fourvière",   capacity: 10 }
];

export async function GET(request) {
  const url = new URL(request.url);
  const siteId = url.searchParams.get("site_id");
  const p = getPool();
  if (!p) {
    const filtered = siteId ? FALLBACK.filter(r => r.site_id === Number(siteId)) : FALLBACK;
    return Response.json({ rooms: filtered, source: "fallback" });
  }
  try {
    const q = siteId
      ? await p.query("SELECT id, site_id, name, capacity FROM rooms WHERE site_id = $1", [siteId])
      : await p.query("SELECT id, site_id, name, capacity FROM rooms ORDER BY id");
    return Response.json({ rooms: q.rows, source: "postgres" });
  } catch (err) {
    return Response.json({ rooms: FALLBACK, source: "fallback", error: err.message });
  }
}
