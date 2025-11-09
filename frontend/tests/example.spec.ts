import { test, expect } from "@playwright/test";

test("homepage has correct title and heading", async ({ page }) => {
  await page.goto("/");

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/Health/i);

  // Expect the main heading to be visible
  const heading = page.getByRole("heading", { level: 1 });
  await expect(heading).toBeVisible();
});

test("navigation works correctly", async ({ page }) => {
  await page.goto("/");

  // Check that we can navigate
  await expect(page).toHaveURL("http://localhost:3000/");
});
