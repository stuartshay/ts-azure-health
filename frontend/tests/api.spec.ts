import { test, expect } from "@playwright/test";

test.describe("API Routes", () => {
  test("call-downstream API returns successful response", async ({ request }) => {
    const response = await request.get("/api/call-downstream");

    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);

    const data = await response.json();
    expect(data).toBeDefined();
  });

  test("kv-secret API returns successful response", async ({ request }) => {
    const response = await request.get("/api/kv-secret");

    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);
  });
});

test.describe("API Error Handling", () => {
  test("non-existent route returns 404", async ({ request }) => {
    const response = await request.get("/api/non-existent");
    expect(response.status()).toBe(404);
  });
});
