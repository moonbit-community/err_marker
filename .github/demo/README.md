# README demo

`../assets/demo.gif` is rendered from this
[Remotion](https://www.remotion.dev/) project. The animation only moves
things around: every line, marker, colour and column comes from the real
renderer.

1. `python3 capture.py` renders each scene with
   `Report::render(..., color=true)`, lays every line out with `@cursor`
   (grapheme clusters and display widths) and writes `src/scenes.json`, one
   cell per cluster. It adds two temporary test files and removes them again.
2. `npm ci` installs the pinned Remotion and React versions.
3. `npm run render` writes `out/demo.mp4` (960×540, 30 fps).
4. `npm run gif` converts it with ffmpeg into the README GIF (720 px, 15 fps,
   64 colours).

Scenes are listed in `capture.py` (what is rendered) and `src/Demo.tsx`
(command line and caption shown with it). Remotion has its own
[license](https://www.remotion.dev/license); this project only uses it to
produce the GIF.
