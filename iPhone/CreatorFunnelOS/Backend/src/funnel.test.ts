import { describe, expect, it } from "vitest";
import { keywordMatches } from "./funnel.js";

describe("keyword matching", () => {
  it("matches a whole keyword without case sensitivity", () => {
    expect(keywordMatches("Please send me the BRAND guide!", "brand")).toBe(true);
  });

  it("does not match inside a larger word", () => {
    expect(keywordMatches("I love rebranding", "brand")).toBe(false);
  });

  it("normalizes Unicode before matching", () => {
    expect(keywordMatches("ＣＨＥＣＫＬＩＳＴ", "CHECKLIST")).toBe(true);
  });
});
