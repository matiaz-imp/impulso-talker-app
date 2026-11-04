import { test, expect } from "@playwright/test";

test.describe("Impulso Talker", () => {
  test("dev server responds", async ({ page }) => {
    // Just verify the dev server is running and responds
    const response = await page.goto("/");
    expect(response?.status()).toBe(200);
  });

  test("page has html structure", async ({ page }) => {
    await page.goto("/");

    // Verify basic HTML structure exists
    const html = await page.content();
    expect(html).toContain("<html");
    expect(html).toContain("<body");
  });

  test("la marca es Impulso Talker y no Handy", async ({ page }) => {
    await page.goto("/");
    expect(await page.title()).toBe("Impulso Talker");
    // Solo el texto visible: los comentarios de CSS heredados de Handy no cuentan.
    const visible = await page.locator("body").innerText();
    expect(visible).not.toMatch(/\bHandy\b/);
  });
});
