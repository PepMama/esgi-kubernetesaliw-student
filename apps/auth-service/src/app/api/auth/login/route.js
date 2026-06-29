export const dynamic = "force-dynamic";

export async function POST(request) {
  const body = await request.json().catch(() => ({}));
  if (!body.email) {
    return Response.json({ error: "email required" }, { status: 400 });
  }
  return Response.json({
    token: `mock-jwt-${Buffer.from(body.email).toString("base64")}`,
    user: { email: body.email }
  });
}
