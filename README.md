# Painter Tracer <!-- omit from toc -->

Remotely apply decals on surfaces using a tracer

## Table of Contents <!-- omit from toc -->

- [Description](#description)
  - [Features](#features)
  - [Rational](#rational)
  - [Remarks](#remarks)
- [Disclaimer](#disclaimer)
- [Pull Requests](#pull-requests)
- [Credits](#credits)

## Description

This adds the Painter Tracer, which spawns an entity that paints surfaces

### Features

- **Painter tracer entity**: An entity which paints decals using traces
- **Parameters**: Apply decals on an interval, with coloring and scaling
- **Custom decal support**: Decals from the Paint tool, or custom decal materials, may be used 
- **Stop Motion Helper support**: Use SMH to animate the entity to apply decals

### Rational

Previously, the method to animating decals involved using a flat plane prop (e.g. a plate model) and a decal attached to it and animating its position. There's additional setup in making this work:

1. Spawn a plate prop
2. Paint the plate prop with the desired decal.
3. Align the plate prop at the desired position. (This may require a precision tool such as Ragdoll Mover).
4. Keyframe at the desired position of the plate prop and the hidden position.
5. Hide the prop itself (using an invisible submaterial or color tool).

This tool reduces the setup to 3 steps:

1. Spawn the painter tracer wih desired decal material.
2. Point the entity at the desired position
3. Keyframe the painting state.

Furthermore, it spawns a new decal when its painting state is enabled. This prevents problems where either the Source Engine or another addon may clear decals (GMod removes decals at certain lighting conditions (source?), and Map Retexturizer run `r_cleardecals` at an interval).

### Remarks

- This entity supports changing its decal material directly, not with just the tool. You can keyframe the different materials with Stop Motion Helper.
- To apply decals on trigger, set the interval to a large value. 

## Disclaimer

## Pull Requests

When making a pull request, make sure to confine to the style seen throughout. Try to add types for new functions or data structures. I used the default [StyLua](https://github.com/JohnnyMorganz/StyLua) formatting style.
