import { Pool } from "pg";

export const dynamic = "force-dynamic";

let pool;
function getPool() {
  if (!pool && process.env.DATABASE_URL) {
    pool = new Pool({ connectionString: process.env.DATABASE_URL });
  }
  return pool;
}

const FALLBACK = [
  { id: 1, name: "SalleEnFrance Paris République", city: "Paris", region: "Île-de-France" },
  { id: 2, name: "SalleEnFrance Lyon Part-Dieu", city: "Lyon", region: "Auvergne-Rhône-Alpes" },
  { id: 3, name: "SalleEnFrance Marseille Vieux-Port", city: "Marseille", region: "PACA" },
  { id: 4, name: "SalleEnFrance Bordeaux Chartrons", city: "Bordeaux", region: "Nouvelle-Aquitaine" },
  { id: 5, name: "SalleEnFrance Lille Euralille", city: "Lille", region: "Hauts-de-France" }
];

export async function GET() {
  const p = getPool();
  if (!p) return Response.json({ sites: FALLBACK, source: "fallback" });
  try {
    const { rows } = await p.query("SELECT id, name, city, region FROM sites ORDER BY id");
    return Response.json({ sites: rows, source: "postgres" });
  } catch (err) {
    return Response.json({ sites: FALLBACK, source: "fallback", error: err.message });
  }
}
