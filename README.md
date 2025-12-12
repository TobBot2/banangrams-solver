# banangrams-solver
Bananagrams Game  written in ocaml for hopkins functional programming class fall 2025

Project Design link: https://docs.google.com/document/d/1F4gcTCWEiJhd27H_4lRM_LxGZDrJ8e0fNBV_dhFGWs4/edit?tab=t.0

Initial Project Idea Link: https://docs.google.com/document/d/1Odw2qfVwJuNVmxbHsGIP7VlJnVNOziIS_UsfSz4bqUQ/edit?usp=sharing


A multiplayer Bananagrams game implementation with an OCaml backend and ReScript frontend.

Completed Features

Backend: Fully functional

Generic library (Tile, Word, Board modules using functors)
Game validation logic with dictionary checking
Word extraction and board connectivity validation
Server functionality with Dream web framework
Multiplayer support with player state management
Tile bag distribution 
Solver implementation


Frontend: Fully operational

ReScript-based interactive UI
Drag-and-drop tile placement
Board validation
Rack management
Multi-player game mode


Tests: Comprehensive unit tests for core modules
Build System: Dune build configured and working

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

Backend

OCaml (≥ 4.14)
Dune (≥ 3.0)
opam packages:
Node.js installed
npm
opam packages: core dream yojson ppx_jane bisect_ppx ounit2 lwt

Build Steps

1. Build the Backend
From the project root (bananagrams-solver/): dune build 

Running the Game
You need three separate terminals:
1. Terminal 1: Frontend Build (from the client folder: cd client)
cd client

First time only:
npm install

Then run:
npm run res:dev    # Development mode with hot reload
OR
npm run res:build  # Production build

2. Terminal 2: Frontend Dev Server (from the client folder: cd client)
cd client
npm run dev
This will output a localhost address (e.g., http://localhost:5173).
Note: The game runs on this address, NOT localhost:8080.

3. Terminal 3: Backend Server
./_build/default/server/server.exe

Play the Game
Open the localhost address from Terminal 2 in your browser and start playing!

Contributors
Malavika Nair, Lulu Grubb, Trevor Black 