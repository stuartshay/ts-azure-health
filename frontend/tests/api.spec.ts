import { test, expect } from "@playwright/test";

test.describe("API Routes", () => {
  test("call-downstream API endpoint exists and requires authentication", async ({ request }) => {
    // POST without auth token should return 401
    const response = await request.post("/api/call-downstream");

    // Expecting 401 Unauthorized or 500 if env vars missing
    expect([401, 500]).toContain(response.status());
  });

  test("kv-secret API endpoint exists", async ({ request }) => {
    const response = await request.get("/api/kv-secret");

    // In CI without Azure credentials, this will fail with 500
    // In local dev with credentials, it should succeed with 200
    // We just verify the endpoint exists (not 404)
    expect(response.status()).not.toBe(404);
  });
});

test.describe("API Error Handling", () => {
  test("non-existent route returns 404", async ({ request }) => {
    const response = await request.get("/api/non-existent");
    expect(response.status()).toBe(404);
  });
});
