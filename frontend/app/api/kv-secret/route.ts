import { DefaultAzureCredential, ManagedIdentityCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";
import type { NextRequest } from "next/server";

export async function GET(_req: NextRequest) {
  const credential = process.env.AZURE_CLIENT_ID
    ? new ManagedIdentityCredential(process.env.AZURE_CLIENT_ID)
    : new DefaultAzureCredential();

  const kvUrl = process.env.KV_URL!;
  const client = new SecretClient(kvUrl, credential);
  const secret = await client.getSecret(process.env.KV_SECRET_NAME!);
  return new Response(secret.value ?? "", { status: 200 });
}
