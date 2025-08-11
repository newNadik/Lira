# Planet Lira Simulation

A SwiftUI-based idle simulation game prototype where a small alien colony — the **Liri** — settles and grows on the planet Lira.

## Overview

The simulation runs **fully automatically**. Each in-game day, the Liri explore, grow food, build, do science, and slowly increase their population. Progress can be influenced by real-world **HealthKit data** (steps, daylight, exercise, sleep), but the colony can survive even with zero input.

Currently, the simulation is in **DEV mode**:  
- 1 in-game day = 3 seconds  
- All health metrics default to zero

The app shows:
- **Colony Status** — population, beds, food, greenhouses, tech, exploration, build & science points
- **Build Queue** — planned constructions automatically worked on as build points accrue
- **Event Log** — daily updates on exploration, building progress, science breakthroughs, and population changes

## Features

- **Passive survival**: The colony will progress slowly even without player health data.
- **Exploration**: Steps increase exploration range, unlocking more plant varieties for food.
- **Food production**: Daylight improves greenhouse yield.
- **Construction**: Exercise speeds up building.
- **Science**: Sleep boosts research and tech.
- **Population growth**: Increases when food and housing are available.

## How to Run

1. Open `Lira.xcodeproj` in Xcode.
2. Build and run on macOS or iOS simulator.
3. Watch the colony progress — no user interaction required.

## Planned

- HealthKit integration.
- More building types and colony events.
- Persistent save/load.
- Visual representation of the colony map.

---

*Planet Lira* — a calm, self-growing world for your pocket.