import { describe, it, expect, vi } from "vitest";
import { paintLineGraph } from "../../src/features/system/models/GraphUtils.js";

function mockCtx() {
  const gradientObj = { addColorStop: vi.fn() };
  return {
    reset: vi.fn(),
    beginPath: vi.fn(),
    moveTo: vi.fn(),
    lineTo: vi.fn(),
    fill: vi.fn(),
    stroke: vi.fn(),
    createLinearGradient: vi.fn(() => gradientObj),
    _gradient: gradientObj,
    strokeStyle: null,
    fillStyle: null,
    lineWidth: null,
  };
}

function mockCanvas(w, h, ctx) {
  return { width: w, height: h, getContext: vi.fn(() => ctx) };
}

const withAlpha = (color, alpha) => `${color}@${alpha}`;

// ---------------------------------------------------------------------------
// Guard clauses
// ---------------------------------------------------------------------------

describe("paintLineGraph guards", () => {
  it("returns early for empty data", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(100, 50, ctx);
    paintLineGraph(canvas, [], "red", withAlpha);
    expect(ctx.reset).not.toHaveBeenCalled();
  });

  it("returns early for zero-width canvas", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(0, 50, ctx);
    paintLineGraph(canvas, [0.5], "red", withAlpha);
    expect(ctx.reset).not.toHaveBeenCalled();
  });

  it("returns early for zero-height canvas", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(100, 0, ctx);
    paintLineGraph(canvas, [0.5], "red", withAlpha);
    expect(ctx.reset).not.toHaveBeenCalled();
  });
});

// ---------------------------------------------------------------------------
// Default behavior (fill + stroke)
// ---------------------------------------------------------------------------

describe("paintLineGraph default", () => {
  it("resets context and draws fill + stroke", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(100, 50, ctx);
    paintLineGraph(canvas, [0, 0.5, 1.0], "blue", withAlpha);

    expect(ctx.reset).toHaveBeenCalledOnce();
    // Fill path: beginPath + moveTo(bottom-left) + lineTo per point + lineTo(bottom-right) + fill
    // Stroke path: beginPath + moveTo/lineTo per point + stroke
    expect(ctx.beginPath).toHaveBeenCalledTimes(2);
    expect(ctx.fill).toHaveBeenCalledOnce();
    expect(ctx.stroke).toHaveBeenCalledOnce();
  });

  it("uses default gradient alphas 0.3 top and 0.0 bottom", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(100, 50, ctx);
    paintLineGraph(canvas, [0.5], "green", withAlpha);

    expect(ctx._gradient.addColorStop).toHaveBeenCalledWith(0, "green@0.3");
    expect(ctx._gradient.addColorStop).toHaveBeenCalledWith(1, "green@0");
  });

  it("sets strokeStyle and lineWidth", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(100, 50, ctx);
    paintLineGraph(canvas, [0.5, 0.5], "red", withAlpha);

    expect(ctx.strokeStyle).toBe("red");
    expect(ctx.lineWidth).toBe(2);
  });
});

// ---------------------------------------------------------------------------
// Options
// ---------------------------------------------------------------------------

describe("paintLineGraph options", () => {
  it("respects fill: false (no gradient, no fill call)", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(100, 50, ctx);
    paintLineGraph(canvas, [0.5, 1.0], "red", withAlpha, { fill: false });

    expect(ctx.createLinearGradient).not.toHaveBeenCalled();
    expect(ctx.fill).not.toHaveBeenCalled();
    // Should still stroke
    expect(ctx.stroke).toHaveBeenCalledOnce();
  });

  it("respects custom fillAlphaTop and fillAlphaBot", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(100, 50, ctx);
    paintLineGraph(canvas, [0.5], "blue", withAlpha, {
      fillAlphaTop: 0.8,
      fillAlphaBot: 0.2,
    });

    expect(ctx._gradient.addColorStop).toHaveBeenCalledWith(0, "blue@0.8");
    expect(ctx._gradient.addColorStop).toHaveBeenCalledWith(1, "blue@0.2");
  });

  it("applies yScale to y-coordinates", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(100, 100, ctx);
    // Single data point at 1.0 (max), yScale 0.5 → y should be 100 - (1.0 * 100 * 0.5) = 50
    paintLineGraph(canvas, [1.0], "red", withAlpha, {
      fill: false,
      yScale: 0.5,
    });

    // Stroke path: moveTo(0, 50)
    expect(ctx.moveTo).toHaveBeenCalledWith(0, 50);
  });

  it("default yScale is 1.0", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(100, 100, ctx);
    paintLineGraph(canvas, [1.0], "red", withAlpha, { fill: false });

    // y = 100 - (1.0 * 100 * 1.0) = 0
    expect(ctx.moveTo).toHaveBeenCalledWith(0, 0);
  });
});

// ---------------------------------------------------------------------------
// Coordinate calculations
// ---------------------------------------------------------------------------

describe("paintLineGraph coordinates", () => {
  it("spaces points evenly across canvas width", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(200, 100, ctx);
    paintLineGraph(canvas, [0, 0, 0], "red", withAlpha, { fill: false });

    // 3 points → spacing = 200 / (3-1) = 100
    // Point 0: x=0, Point 1: x=100, Point 2: x=200
    expect(ctx.moveTo).toHaveBeenCalledWith(0, 100); // y = 100 - 0 = 100
    expect(ctx.lineTo).toHaveBeenCalledWith(100, 100);
    expect(ctx.lineTo).toHaveBeenCalledWith(200, 100);
  });

  it("handles single data point (full canvas width)", () => {
    const ctx = mockCtx();
    const canvas = mockCanvas(100, 100, ctx);
    paintLineGraph(canvas, [0.5], "red", withAlpha, { fill: false });

    // Single point → w = canvas.width = 100, x = 0 * 100 = 0
    // y = 100 - (0.5 * 100 * 1.0) = 50
    expect(ctx.moveTo).toHaveBeenCalledWith(0, 50);
  });
});
