# banangrams-solver
Bananagrams Game  written in ocaml for hopkins functional programming class fall 2025

Project Design link: https://docs.google.com/document/d/1F4gcTCWEiJhd27H_4lRM_LxGZDrJ8e0fNBV_dhFGWs4/edit?tab=t.0

Initial Project Idea Link: https://docs.google.com/document/d/1Odw2qfVwJuNVmxbHsGIP7VlJnVNOziIS_UsfSz4bqUQ/edit?usp=sharing


A multiplayer Bananagrams game implementation with an OCaml backend and ReScript frontend.

Project Status
WORKING:
Backend: Most backend functionality is complete and running
    Generic library (Tile, Word, Board modules using functors)
    Game validation logic
    Server functionality (server.ml)

Frontend: Basic game interface is working
Integration: Frontend and backend communicate successfully
Tests: Unit tests for Tile, Word, and Board modules
Build system: Dune build configured and working

In Progress

Solver: Fully written but not yet integrated into the main codebase, also still testing
Multiplayer: Working on making it a proper two-player game, using the feedback from the inital submission. Multiplayer mode will be designed by including player state management and a /join endpoint so players can join the game
Frontend improvements: Several known issues being addressed. On webpage reload (without reloading the server), the tiles reload but the tile_bag does not. This will be useful for multiplayer so the tile bag does not reset if one player reloads their game, but local persistence for the tile rack has to be implemented so new tiles are not returned on every reload. Also, there are still edge cases when the "Dump" button is hit multiple times.

Project Structure
Generic Library
The core game logic is built using a generic library design:

Tile: Generic tile module (functor-based)
Word: Generic word module (works with any tile type)
Board: Generic board module 

These modules are instantiated with char values in the application layer.
Application Layer

bananagram/: Instantiates generic modules for the game
server/: Main server entry point (server.ml)
Frontend: ReScript-based UI


Build & Run 
Prerequisites

OCaml and Dune installed
Node.js installed
opam packages: core, dream, ppx_jane, bisect_ppx

Build Steps

Build the project (do this first): dune build
Run Unit tests (optional): dune test

Running the Game
You need three separate terminals:
1. Terminal 1: Frontend Build (from the client folder: cd client)
# First time only:
npm install

# Then run one of: 
npm run res:dev    # For development
# OR
npm run res:build  # For production build

2. Terminal 2: Frontend Dev Server (from the client folder: cd client)
npm run dev
This will output a localhost address (e.g., http://localhost:5173).
Note: The game runs on this address, NOT localhost:8080.

Terminal 3: Backend Server
./_build/default/server/server.exe

Play the Game
Open the localhost address from Terminal 2 in your browser and start playing!

Future Work

Complete solver integration
Finish two-player game
Frontend polish and bug fixes
Expand test coverage. After looking at previous examples, we'll be focusing on robust library testing instead of frontend testing / server testing, because the server by default has some error handling, and outcomes can be tested by using the frontend. However, we will have tests for server utils.

Contributors
Malavika Nair, Lulu Grubb, Trevor Black 