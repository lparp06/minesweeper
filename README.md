# FPGA Minesweeper

A hardware implementation of Minesweeper written in Verilog for an FPGA, with VGA graphics, game-state control, mine generation, flood-fill reveal logic, and seven-segment display output.

![Language](https://img.shields.io/badge/Language-Verilog-blue)
![Platform](https://img.shields.io/badge/Platform-FPGA-lightgrey)
![Focus](https://img.shields.io/badge/Focus-Digital%20Logic-green)

## Overview

This project implements Minesweeper as a fully hardware-based game system. The design uses modular Verilog components for game control, tile state management, random mine placement, adjacency calculation, VGA rendering, text rendering, start/end screens, and seven-segment display output.

The game is built around an 8x8 board with 10 mines. The first click is protected by generating the mine map only after the player selects an initial tile.

## Features

- 8x8 Minesweeper board with 10 mines
- Safe first-click mine generation
- VGA graphics output
- Start screen and end screen rendering
- Tile reveal and flag logic
- Flood-fill reveal for connected zero-adjacent tiles
- Adjacent-mine counting
- Win/loss detection
- Seven-segment display output
- Modular Verilog design

## Architecture

The design is split into separate modules for game logic, rendering, board state, input handling, and display output.

```text
                +----------------------+
Inputs -------->|   game_controller    |
KEY/SW          |  main game FSM       |
                +----------+-----------+
                           |
                           v
        +------------------+------------------+
        |                                     |
        v                                     v
+---------------+                    +----------------+
| mine generator|                    | adjacency FSM  |
+---------------+                    +----------------+
        |                                     |
        v                                     v
+------------------------------------------------------+
|                    render module                     |
| tile state, cursor, reveal/flag logic, colors         |
+--------------------------+---------------------------+
                           |
                           v
                    +-------------+
                    | VGA driver  |
                    +-------------+
