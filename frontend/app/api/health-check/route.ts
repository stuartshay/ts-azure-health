import { DefaultAzureCredential, ManagedIdentityCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";

interface HealthCheckResponse {
  success: boolean;
  backendUrl?: string;
  status?: string;
  statusCode?: number;
  responseTime?: number;
  timestamp?: string;
  error?: string;
  details?: Record<string, unknown>;
}

export async function GET() {
  const startTime = Date.now();

  try {
    // Step 1: Read the backend URL from Key Vault
    const credential = process.env.AZURE_CLIENT_ID
      ? new ManagedIdentityCredential(process.env.AZURE_CLIENT_ID)
      : new DefaultAzureCredential();

    const kvUrl = process.env.KV_URL;
    if (!kvUrl) {
      return Response.json(
        {
          success: false,
          error: "KV_URL environment variable not configured",
        } as HealthCheckResponse,
        { status: 500 }
      );
    }

    const secretName = process.env.KV_FUNCTION_URL_SECRET_NAME || "function-app-url-dev";
    const client = new SecretClient(kvUrl, credential);

    let backendUrl: string;
    try {
      const secret = await client.getSecret(secretName);
      backendUrl = secret.value ?? "";

      if (!backendUrl) {
        return Response.json(
          {
            success: false,
            error: `Secret '${secretName}' is empty in Key Vault`,
          } as HealthCheckResponse,
          { status: 500 }
        );
      }
    } catch (kvError: unknown) {
      const message = kvError instanceof Error ? kvError.message : String(kvError);
      return Response.json(
        {
          success: false,
          error: `Failed to read secret '${secretName}' from Key Vault: ${message}`,
        } as HealthCheckResponse,
        { status: 500 }
      );
    }

    // Step 2: Call the backend health endpoint
    const healthUrl = `${backendUrl.replace(/\/$/, "")}/api/health`;

    try {
      // Add timeout to prevent hanging requests
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);

      const healthResponse = await fetch(healthUrl, {
        method: "GET",
        signal: controller.signal,
        headers: {
          "User-Agent": "ts-azure-health-frontend/1.0",
        },
      });

      clearTimeout(timeoutId);

      const responseTime = Date.now() - startTime;
      const isHealthy = healthResponse.ok;

      // Try to parse response body as JSON
      let responseBody: Record<string, unknown> | string;
      const contentType = healthResponse.headers.get("content-type");
      try {
        if (contentType?.includes("application/json")) {
          responseBody = (await healthResponse.json()) as Record<string, unknown>;
        } else {
          responseBody = await healthResponse.text();
        }
      } catch {
        responseBody = "Unable to parse response";
      }

      return Response.json(
        {
          success: isHealthy,
          backendUrl: healthUrl,
          status: isHealthy ? "Healthy" : "Unhealthy",
          statusCode: healthResponse.status,
          responseTime,
          timestamp: new Date().toISOString(),
          details: typeof responseBody === "object" ? responseBody : { raw: responseBody },
        } as HealthCheckResponse,
        { status: 200 }
      );
    } catch (fetchError: unknown) {
      const responseTime = Date.now() - startTime;
      const message = fetchError instanceof Error ? fetchError.message : String(fetchError);
      const isTimeout = message.includes("aborted") || message.includes("timeout");

      return Response.json(
        {
          success: false,
          backendUrl: healthUrl,
          status: "Unreachable",
          error: isTimeout
            ? "Health check timeout (5s exceeded)"
            : `Failed to reach backend: ${message}`,
          responseTime,
          timestamp: new Date().toISOString(),
        } as HealthCheckResponse,
        { status: 200 } // Return 200 so frontend can display the error details
      );
    }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    return Response.json(
      {
        success: false,
        error: `Health check failed: ${message}`,
        timestamp: new Date().toISOString(),
      } as HealthCheckResponse,
      { status: 500 }
    );
  }
}
