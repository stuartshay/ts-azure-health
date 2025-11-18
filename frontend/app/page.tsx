"use client";
import { msal } from "@/lib/msalClient";
import { useState } from "react";

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

export default function Home() {
  const [status, setStatus] = useState<string>("");

  async function signIn() {
    try {
      await msal.loginPopup({
        scopes: [process.env.NEXT_PUBLIC_API_SCOPE!],
      });
      setStatus("Signed in");
    } catch (e: unknown) {
      const message = e instanceof Error ? e.message : String(e);
      setStatus("Sign-in failed: " + message);
    }
  }

  async function callDownstream() {
    try {
      const account = msal.getAllAccounts()[0];
      if (!account) return setStatus("No account; sign in first.");
      const resp = await msal.acquireTokenSilent({
        account,
        scopes: [process.env.NEXT_PUBLIC_API_SCOPE!],
      });
      const r = await fetch("/api/call-downstream", {
        method: "POST",
        headers: { Authorization: `Bearer ${resp.accessToken}` },
      });
      const t = await r.text();
      setStatus(`Downstream responded (${r.status}): ${t}`);
    } catch (e: unknown) {
      const message = e instanceof Error ? e.message : String(e);
      setStatus("Call failed: " + message);
    }
  }

  async function readSecret() {
    try {
      setStatus("Checking backend health...");
      const r = await fetch("/api/health-check");

      if (!r.ok) {
        const errorText = await r.text();
        setStatus(`Health check failed (${r.status}): ${errorText}`);
        return;
      }

      const healthData: HealthCheckResponse = await r.json();

      // Format the health check response
      let statusMessage = "";

      if (healthData.success) {
        statusMessage = `✅ Backend Health Check: ${healthData.status}\n\n`;
        statusMessage += `URL: ${healthData.backendUrl}\n`;
        statusMessage += `Status Code: ${healthData.statusCode}\n`;
        statusMessage += `Response Time: ${healthData.responseTime}ms\n`;
        statusMessage += `Timestamp: ${healthData.timestamp ? new Date(healthData.timestamp).toLocaleString() : "N/A"}\n`;

        if (healthData.details && Object.keys(healthData.details).length > 0) {
          statusMessage += `\nDetails:\n${JSON.stringify(healthData.details, null, 2)}`;
        }
      } else {
        statusMessage = `❌ Backend Health Check: ${healthData.status || "Failed"}\n\n`;

        if (healthData.backendUrl) {
          statusMessage += `URL: ${healthData.backendUrl}\n`;
        }

        if (healthData.statusCode) {
          statusMessage += `Status Code: ${healthData.statusCode}\n`;
        }

        if (healthData.responseTime) {
          statusMessage += `Response Time: ${healthData.responseTime}ms\n`;
        }

        if (healthData.error) {
          statusMessage += `\nError: ${healthData.error}`;
        }

        if (healthData.timestamp) {
          statusMessage += `\nTimestamp: ${new Date(healthData.timestamp).toLocaleString()}`;
        }
      }

      setStatus(statusMessage);
    } catch (e: unknown) {
      const message = e instanceof Error ? e.message : String(e);
      setStatus(`❌ Health check request failed: ${message}`);
    }
  }

  return (
    <main style={{ padding: 24, display: "grid", gap: 12 }}>
      <h1>Pwsh Azure Health — Frontend Smoke Test</h1>
      <div style={{ display: "flex", gap: 8 }}>
        <button onClick={signIn}>Sign in</button>
        <button onClick={callDownstream}>Call Protected API</button>
        <button onClick={readSecret}>Read KV Secret (server)</button>
      </div>
      <pre
        style={{
          whiteSpace: "pre-wrap",
          wordBreak: "break-word",
          backgroundColor: "#f5f5f5",
          padding: "12px",
          borderRadius: "4px",
          border: "1px solid #ddd",
        }}
      >
        {status}
      </pre>
    </main>
  );
}
