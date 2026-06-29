import { Pool } from "pg";
import Redis from "ioredis";

export const dynamic = "force-dynamic";

let pool;
let redis;

function getPool() {
  if (!pool && process.env.DATABASE_URL) pool = new Pool({ connectionString: process.env.DATABASE_URL });
  return pool;
}
function getRedis() {
  if (!redis && process.env.REDIS_URL) redis = new Redis(process.env.REDIS_URL, { lazyConnect: true });
  return redis;
}

export async function GET(request) {
  const r = getRedis();
  const cacheKey = "bookings:list";
  if (r) {
    try {
      await r.connect().catch(() => {});
      const cached = await r.get(cacheKey);
      if (cached) return Response.json({ bookings: JSON.parse(cached), source: "redis" });
    } catch {}
  }
  const p = getPool();
  let bookings = [];
  if (p) {
    try {
      const { rows } = await p.query("SELECT id, room_id, user_id, starts_at, ends_at FROM bookings ORDER BY starts_at DESC LIMIT 50");
      bookings = rows;
    } catch {}
  }
  if (r) { try { await r.set(cacheKey, JSON.stringify(bookings), "EX", 30); } catch {} }
  return Response.json({ bookings, source: p ? "postgres" : "fallback" });
}

export async function POST(request) {
  const body = await request.json().catch(() => ({}));
  if (!body.room_id || !body.starts_at || !body.ends_at) {
    return Response.json({ error: "room_id, starts_at, ends_at required" }, { status: 400 });
  }
  const p = getPool();
  if (!p) return Response.json({ id: Math.floor(Math.random() * 1000), ...body }, { status: 201 });
  try {
    const { rows } = await p.query(
      "INSERT INTO bookings (room_id, user_id, starts_at, ends_at) VALUES ($1, $2, $3, $4) RETURNING id",
      [body.room_id, body.user_id || 1, body.starts_at, body.ends_at]
    );
    const r = getRedis();
    if (r) { try { await r.connect().catch(() => {}); await r.del("bookings:list"); } catch {} }
    return Response.json({ id: rows[0].id, ...body }, { status: 201 });
  } catch (err) {
    return Response.json({ error: err.message }, { status: 500 });
  }
}
