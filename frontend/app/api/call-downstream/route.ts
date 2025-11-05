import type { NextRequest } from "next/server";
import { ConfidentialClientApplication } from "@azure/msal-node";

export async function POST(req: NextRequest) {
  const auth = req.headers.get("authorization") ?? "";
  const incomingJwt = auth.replace(/^Bearer\s+/i, "");
  if (!incomingJwt) return new Response("Missing token", { status: 401 });

  const msal = new ConfidentialClientApplication({
    auth: {
      clientId: process.env.AAD_BFF_CLIENT_ID!,
      clientSecret: process.env.AAD_BFF_CLIENT_SECRET!, // move to KV/MI later
      authority: `https://login.microsoftonline.com/${process.env.AAD_TENANT_ID}`
    }
  });

  const result = await msal.acquireTokenOnBehalfOf({
    oboAssertion: incomingJwt,
    scopes: [process.env.AAD_DOWNSTREAM_SCOPE!],
  });

  const r = await fetch(process.env.DOWNSTREAM_API_URL!, {
    method: "GET",
    headers: { Authorization: `Bearer ${result!.accessToken}` }
  });
  const text = await r.text();
  return new Response(text, { status: r.status });
}
