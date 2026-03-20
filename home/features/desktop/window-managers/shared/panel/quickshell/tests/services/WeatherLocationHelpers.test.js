import { describe, it, expect } from "vitest";
import { buildLocationPlan, cityQueryVariants } from "../../src/services/WeatherLocationHelpers.js";

describe("buildLocationPlan", () => {
  it("honors the configured priority order", () => {
    expect(buildLocationPlan("latlon_city_auto", true, true, true)).toEqual([
      "latlon",
      "city",
      "auto",
    ]);

    expect(buildLocationPlan("auto_city_latlon", true, true, true)).toEqual([
      "auto",
      "city",
      "latlon",
    ]);
  });

  it("drops unavailable sources while preserving order", () => {
    expect(buildLocationPlan("city_auto_latlon", false, true, true)).toEqual([
      "city",
      "auto",
    ]);

    expect(buildLocationPlan("latlon_city_auto", false, false, true)).toEqual([
      "auto",
    ]);
  });
});

describe("cityQueryVariants", () => {
  it("keeps the original city query and adds a simplified city-only fallback", () => {
    expect(cityQueryVariants("Minneapolis, MN")).toEqual([
      "Minneapolis, MN",
      "Minneapolis",
    ]);
  });

  it("returns an empty list for blank queries", () => {
    expect(cityQueryVariants("   ")).toEqual([]);
  });
});
