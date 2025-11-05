"use client";
import { msal } from "@/lib/msalClient";
import { useState } from "react";

export default function Home() {
  const [status, setStatus] = useState<string>("");

  async function signIn() {
    try {
      await msal.loginPopup({
        scopes: [process.env.NEXT_PUBLIC_API_SCOPE!],
      });
      setStatus("Signed in");
    } catch (e:any) {
      setStatus("Sign-in failed: " + e.message);
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
        headers: { Authorization: `Bearer ${resp.accessToken}` }
      });
      const t = await r.text();
      setStatus(`Downstream responded (${r.status}): ${t}`);
    } catch (e:any) {
      setStatus("Call failed: " + e.message);
    }
  }

  async function readSecret() {
    try {
      const r = await fetch("/api/kv-secret");
      const t = await r.text();
      setStatus(`KV secret: ${t}`);
    } catch (e:any) {
      setStatus("KV read failed: " + e.message);
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
      <pre>{status}</pre>
    </main>
  );
}
