# ADR-0004: Tauri + Three.js for the desktop mascot

- **Status:** accepted
- **Date:** 2026-10-14

## Context
I need a transparent, frameless, always-on-top window on Windows that renders an animated 3D mascot.

## Decision
Use Tauri 2 (Rust shell + system WebView2) with Three.js for rendering and a `.glb` model.

## Consequences
- Small binary (a few MB) and low RAM use compared to Electron.
- Web stack for the UI (TypeScript + Three.js), with Rust only for window/tray/hotkey glue.
- Requires the Rust toolchain to build.
- The mascot is my own original low-poly design, so there are no licensing issues.

## Alternatives considered
- **Electron**: more examples online, but ~100+ MB and heavier on RAM.
- **Godot**: better animation tooling, but further from the web stack I want to show.
