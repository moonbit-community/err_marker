// README demo of err_marker. Every marker, colour and column comes from the
// real renderer: src/scenes.json holds `Report::render(..., color=true)`
// output split into grapheme clusters, with the column and width of each
// cluster computed by `@cursor` (see ../README.md). Nothing here re-implements
// the layout; it only animates it.
import React from "react";
import {
  AbsoluteFill,
  Easing,
  Sequence,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import scenes from "./scenes.json";

type Cell = { t: string; col: number; w: number; c: string | null };

const PALETTE = {
  bg0: "#070b18",
  bg1: "#121a36",
  card: "#0d1326",
  border: "#27325a",
  text: "#cdd6ee",
  dim: "#6b7699",
  prompt: "#7ee0a8",
  accent: "#a78bfa",
  error: "#ff5c7a",
  warning: "#ffc861",
  secondary: "#6aa8ff",
  bold: "#ffffff",
};

const colorOf = (c: string | null) =>
  c === "error"
    ? PALETTE.error
    : c === "warning"
      ? PALETTE.warning
      : c === "secondary"
        ? PALETTE.secondary
        : c === "bold"
          ? PALETTE.bold
          : PALETTE.text;

const CELL = 15; // px per terminal column
const LINE = 36; // px per line
const FONT = "'JetBrains Mono', 'SF Mono', Menlo, monospace";

const INTRO = 50;
const SCENE = 96;
const TYPE_SPEED = 1.6; // characters per frame
const OUTRO = 70;
const FADE = 10;

type SceneSpec = {
  key: keyof typeof scenes;
  command: string;
  caption: string;
};

const SCENES: SceneSpec[] = [
  {
    key: "argv",
    command: "sudoku export a.txt sovle out.txt",
    caption: "a typo in argv",
  },
  {
    key: "missing",
    command: "sudoku export a.txt",
    caption: "a missing argument is an insertion point",
  },
  {
    key: "cjk",
    command: "sudoku check row1.txt",
    caption: "CJK widths · UAX #11",
  },
  {
    key: "emoji",
    command: "moon run demo",
    caption: "grapheme clusters · UAX #29",
  },
];

export const DEMO_FRAMES = INTRO + SCENES.length * SCENE + OUTRO;

const isMarker = (cell: Cell) =>
  (cell.t === "^" || cell.t === "-") && cell.c !== null;

// The marker row is the second line of every scene; its marker cells sweep
// in from left to right, everything after them (the label) follows.
const Row: React.FC<{
  cells: Cell[];
  index: number;
  frame: number;
}> = ({ cells, index, frame: sceneFrame }) => {
  const frame = sceneFrame;
  const { fps } = useVideoConfig();
  const lineStart = index * 7;
  return (
    <div style={{ position: "relative", height: LINE }}>
      {cells.map((cell, i) => {
        const marker = index === 1 && isMarker(cell);
        const start = marker ? 6 + cell.col * 0.9 : lineStart + (index === 1 ? 14 : 0);
        const s = spring({ frame: frame - start, fps, config: { damping: 14, mass: 0.5 } });
        const opacity = interpolate(frame - start, [0, 6], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        });
        const color = colorOf(cell.c);
        return (
          <span
            key={i}
            style={{
              position: "absolute",
              left: cell.col * CELL,
              width: cell.w * CELL,
              textAlign: "center",
              color,
              opacity,
              fontWeight: cell.c && cell.c !== "secondary" ? 700 : 400,
              transform: marker
                ? `translateY(${(1 - s) * -14}px) scale(${0.6 + 0.4 * s})`
                : `translateX(${(1 - s) * 10}px)`,
              textShadow: marker ? `0 0 ${12 * s}px ${color}` : "none",
            }}
          >
            {cell.t}
          </span>
        );
      })}
    </div>
  );
};

const Window: React.FC<{ children: React.ReactNode; title: string }> = ({
  children,
  title,
}) => (
  <div
    style={{
      width: 820,
      borderRadius: 18,
      background: PALETTE.card,
      border: `1px solid ${PALETTE.border}`,
      boxShadow: "0 30px 80px rgba(0,0,0,0.55), 0 0 0 1px rgba(167,139,250,0.08)",
      overflow: "hidden",
    }}
  >
    <div
      style={{
        height: 38,
        display: "flex",
        alignItems: "center",
        gap: 8,
        padding: "0 16px",
        borderBottom: `1px solid ${PALETTE.border}`,
        color: PALETTE.dim,
        fontFamily: FONT,
        fontSize: 15,
      }}
    >
      {["#ff5f57", "#febc2e", "#28c840"].map((c) => (
        <div key={c} style={{ width: 12, height: 12, borderRadius: 6, background: c }} />
      ))}
      <div style={{ flex: 1, textAlign: "center", marginRight: 52 }}>{title}</div>
    </div>
    <div style={{ padding: "22px 28px 26px", fontFamily: FONT, fontSize: 24 }}>{children}</div>
  </div>
);

const Typed: React.FC<{ text: string; frame: number; speed?: number }> = ({
  text,
  frame,
  speed = 1.6,
}) => {
  const n = Math.max(0, Math.min(text.length, Math.floor(frame * speed)));
  const caret = frame % 16 < 9 || n < text.length;
  return (
    <span>
      {text.slice(0, n)}
      <span style={{ opacity: caret ? 1 : 0, color: PALETTE.accent }}>▍</span>
    </span>
  );
};

const Scene: React.FC<{ spec: SceneSpec }> = ({ spec }) => {
  const frame = useCurrentFrame();
  const rows = scenes[spec.key] as Cell[][];
  const fadeIn = interpolate(frame, [0, FADE], [0, 1], { extrapolateRight: "clamp" });
  const fadeOut = interpolate(frame, [SCENE - FADE, SCENE], [1, 0], {
    extrapolateLeft: "clamp",
  });
  const chip = spring({ frame: frame - 4, fps: 30, config: { damping: 16 } });
  // Rows start once the command has been typed.
  const typed = Math.ceil(spec.command.length / TYPE_SPEED) + 2;
  return (
    <AbsoluteFill
      style={{ alignItems: "center", justifyContent: "center", opacity: fadeIn * fadeOut }}
    >
      <div
        style={{
          position: "absolute",
          top: 34,
          padding: "6px 16px",
          borderRadius: 999,
          background: "rgba(167,139,250,0.14)",
          border: "1px solid rgba(167,139,250,0.45)",
          color: PALETTE.accent,
          fontFamily: FONT,
          fontSize: 17,
          transform: `translateY(${(1 - chip) * -20}px)`,
          opacity: chip,
        }}
      >
        {spec.caption}
      </div>
      <Window title="err_marker — zsh">
        <div style={{ height: LINE, color: PALETTE.text }}>
          <span style={{ color: PALETTE.prompt }}>❯ </span>
          <Typed text={spec.command} frame={frame} speed={TYPE_SPEED} />
        </div>
        <div style={{ height: 10 }} />
        {rows.map((cells, i) => (
          <Row key={i} cells={cells} index={i} frame={frame - typed} />
        ))}
      </Window>
    </AbsoluteFill>
  );
};

const Title: React.FC<{ frame: number; out: number }> = ({ frame, out }) => {
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 18 } });
  const fade = interpolate(frame, [out - FADE, out], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const sweep = interpolate(frame, [8, 34], [0, 10], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", opacity: fade }}>
      <div
        style={{
          fontFamily: FONT,
          fontSize: 76,
          fontWeight: 800,
          color: "#fff",
          letterSpacing: -2,
          transform: `scale(${0.9 + 0.1 * s})`,
          opacity: s,
          textShadow: "0 0 40px rgba(167,139,250,0.55)",
        }}
      >
        err_marker
      </div>
      <div style={{ fontFamily: FONT, fontSize: 40, color: PALETTE.error, height: 46, letterSpacing: 6 }}>
        {"^".repeat(Math.round(sweep))}
      </div>
      <div style={{ fontFamily: FONT, fontSize: 20, color: PALETTE.dim, marginTop: 10, opacity: s }}>
        mark the exact place · MoonBit · Unicode 18.0.0
      </div>
    </AbsoluteFill>
  );
};

const Outro: React.FC = () => {
  const frame = useCurrentFrame();
  const fade = interpolate(frame, [0, FADE], [0, 1], { extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", opacity: fade }}>
      <Window title="install">
        <div style={{ color: PALETTE.text }}>
          <span style={{ color: PALETTE.prompt }}>❯ </span>
          <Typed text="moon add KCN-judu/err_marker@0.2.0" frame={frame} speed={1.4} />
        </div>
      </Window>
      <div
        style={{
          marginTop: 26,
          fontFamily: FONT,
          fontSize: 18,
          color: PALETTE.dim,
          opacity: interpolate(frame, [30, 45], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
        }}
      >
        wasm · wasm-gc · js · native — same output, byte for byte
      </div>
    </AbsoluteFill>
  );
};

const Backdrop: React.FC = () => {
  const frame = useCurrentFrame();
  // A static backdrop keeps GIF frame differences small.
  const drift = 0 * frame;
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(900px 600px at ${70 + drift / 10}% -10%, rgba(167,139,250,0.22), transparent 60%),
          radial-gradient(700px 500px at 10% 110%, rgba(106,168,255,0.14), transparent 60%),
          linear-gradient(160deg, ${PALETTE.bg0}, ${PALETTE.bg1})`,
      }}
    >
      <div
        style={{
          position: "absolute",
          right: 70 + drift,
          top: 46,
          width: 70,
          height: 70,
          borderRadius: 35,
          boxShadow: "inset -14px -6px 0 0 #e9e3ff",
          opacity: 0.18,
        }}
      />
    </AbsoluteFill>
  );
};

export const Demo: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      <Backdrop />
      <Sequence durationInFrames={INTRO}>
        <Title frame={frame} out={INTRO} />
      </Sequence>
      {SCENES.map((spec, i) => (
        <Sequence key={spec.key} from={INTRO + i * SCENE} durationInFrames={SCENE}>
          <Scene spec={spec} />
        </Sequence>
      ))}
      <Sequence from={INTRO + SCENES.length * SCENE} durationInFrames={OUTRO}>
        <Outro />
      </Sequence>
    </AbsoluteFill>
  );
};
