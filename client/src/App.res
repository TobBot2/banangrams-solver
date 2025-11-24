/*@module("./assets/rescript-logo.svg")
external rescript: string = "default"

@module("./assets/vite.svg")
external vite: string = "default"

@react.component
let make = () => {
  
  let (count, setCount) = React.useState(() => 0)
  
  <div className="max-w-200">
    <div className="flex justify-evenly items-center">
      <img src={vite} alt={"Vite logo"} className="h-24" />
      <img src={rescript} alt={"ReScript logo"} className="h-24" />
    </div>
    <h1 className="text-6xl m-16 font-semibold text-center"> {"Vite + ReScript"->React.string} </h1>
    <Button onClick={_ => setCount(count => count + 1)}>
      {React.string(`count is ${count->Int.toString}`)}
    </Button>
    <p className="my-6 text-center">
      {React.string("Edit ")}
      <code className="bg-stone-100 font-mono rounded"> {React.string("src/App.res")} </code>
      {React.string(" and save to test Fast Refresh.")}
    </p>
    <p className="text-center font-thin text-stone-400">
      {React.string("Learn more about ")}
      <a
        href="https://rescript-lang.org/" target="_blank" className="text-blue-500 hover:underline">
        {React.string("ReScript")}
        {React.string(".")}
      </a>
    </p>
  </div>

}*/

/*open Belt
open ReactEvent

@react.component
let make = () => {
  // ----------------------------
  // Letter Bar (21 letters)
  // ----------------------------
  let initialLetters = [
    "A","B","C","D","E","F","G",
    "H","I","J","K","L","M","N",
    "O","P","Q","R","S","T","U"
  ]

  let (letters, _setLetters) = React.useState(() => initialLetters)

  // ----------------------------
  // Grid dimensions
  // ----------------------------
  let rows = 10
  let cols = 10

  // ----------------------------
  // Initialize grid: array<array<option<string>>>
  // ----------------------------
  let (grid, setGrid) =
    React.useState(() =>
      Array.make(
        rows,
        Array.make(cols, None)
      )
    )

  // ----------------------------
  // Track which letter is being dragged
  // ----------------------------
  let (dragged, setDragged) = React.useState(() => None)

  // Drag start
let handleDragStart = (letter: string) => (_e: ReactEvent.Synthetic.t) =>
  setDragged(_ => Some(letter))

  // Allow dropping
  let handleDragOver = (_e: ReactEvent.Synthetic.t) =>
    _e->ReactEvent.Synthetic.preventDefault

  // Drop into a grid cell
let handleDrop = (r: int, c: int) => (_e: ReactEvent.Synthetic.t) => {
  _e->ReactEvent.Synthetic.preventDefault
  switch dragged {
  | None => ()
  | Some(letter) =>
      setGrid(grid =>
        grid
        ->Array.mapWithIndex((rowIdx, row) =>
          row
          ->Array.mapWithIndex((colIdx, cell) =>
            if rowIdx == r && colIdx == c {
              Some(letter)
            } else {
              cell
            }
          )
        )
      )
      setDragged(_ => None)
  }
}

  /* ================================
     Render UI
     ================================ */

  <div className="p-8">

    /* ================================
        TOP DRAGGABLE LETTER BAR
        ================================ */
    <div className="flex gap-3 mb-8 flex-wrap">
      {letters
      ->Array.map(letter =>
        <div
          key=letter
          draggable=true
          onDragStart={handleDragStart(letter)}
          className="cursor-move px-4 py-2 bg-blue-300 rounded shadow-md text-xl font-bold select-none"
        >
          {React.string(letter)}
        </div>
      )
      ->React.array}
    </div>

    {/* ================================
        THE GRID
        ================================ */}
    <div
      className="grid gap-1"
      style={ReactDOM.Style.make(
        ~gridTemplateColumns=`repeat(${cols}, 40px)`,
        ~gridTemplateRows=`repeat(${rows}, 40px)`,
        (),
      )}
    >
      {grid
      ->Array.mapi((rowIdx, row) =>
        row
        ->Array.mapi((colIdx, cell) =>
          <div
            key={`${rowIdx}-${colIdx}`}
            onDragOver={handleDragOver}
            onDrop={handleDrop(rowIdx, colIdx)}
            className="w-10 h-10 border border-gray-400 bg-white flex items-center justify-center"
          >
            {switch cell {
            | None => React.null
            | Some(letter) => React.string(letter)
            }}
          </div>
        )
      )
      ->Array.concatMany
      ->React.array}
    </div>
  </div>
}*/
open Belt

@react.component
let make = () => {
  // ----------------------------
  // Top letters (21 tiles)
  // ----------------------------
  let initialLetters = [
    "A","B","C","D","E","F","G",
    "H","I","J","K","L","M","N",
    "O","P","Q","R","S","T","U"
  ]

  let (letters, _setLetters) = React.useState(() => initialLetters)

  // ----------------------------
  // Grid dimensions
  // ----------------------------
  let rows = 10
  let cols = 10

  // ----------------------------
  // Grid state: array<array<option<string>>>
  // ----------------------------
  let (grid, setGrid) =
    React.useState(() =>
      Array.make(rows, Array.make(cols, None))
    )

  // ----------------------------
  // Dragged letter state
  // ----------------------------
  let (dragged, setDragged) = React.useState(() => None)

  // ----------------------------
  // Drag event handlers
  // ----------------------------
  let handleDragStart = (letter: string) => (e: ReactEvent.Synthetic.t) => {
    e->ReactEvent.Synthetic.preventDefault
    setDragged(_ => Some(letter))
  }

  let handleDragOver = (e: ReactEvent.Synthetic.t) =>
    e->ReactEvent.Synthetic.preventDefault

  let handleDrop = (r: int, c: int) => (e: ReactEvent.Synthetic.t) => {
    e->ReactEvent.Synthetic.preventDefault
    switch dragged {
    | None => ()
    | Some(letter) =>
        setGrid(grid =>
          grid
          ->Belt.Array.mapWithIndex((rowIdx, row) =>
            row
            ->Belt.Array.mapWithIndex((colIdx, cell) =>
              if rowIdx == r && colIdx == c {
                Some(letter)
              } else {
                cell
              }
            )
          )
        )
        setDragged(_ => None)
    }
  }

  // ----------------------------
  // Render
  // ----------------------------
  <div className="p-8">

    /* Top draggable letters */
    <div className="flex gap-3 mb-8 flex-wrap">
      {letters
      ->Array.map(letter =>
        <div
          key=letter
          draggable=true
          onDragStart={handleDragStart(letter)}
          className="cursor-move px-4 py-2 bg-blue-300 rounded shadow-md text-xl font-bold select-none"
        >
          {React.string(letter)}
        </div>
      )
      ->React.array}
    </div>

    {/* Grid */}
    <div
      className="grid gap-1"
      style={ReactDOM.Style.make(
        ~gridTemplateColumns=`repeat(${cols}, 40px)`,
        ~gridTemplateRows=`repeat(${rows}, 40px)`,
        (),
      )}
    >
      {grid
      ->Belt.Array.mapWithIndex((rowIdx, row) =>
        row
        ->Belt.Array.mapWithIndex((colIdx, cell) =>
          <div
            key={`${rowIdx}-${colIdx}`}
            onDragOver={handleDragOver}
            onDrop={handleDrop(rowIdx, colIdx)}
            className="w-10 h-10 border border-gray-400 bg-white flex items-center justify-center"
          >
            {switch cell {
            | None => React.null
            | Some(letter) => React.string(letter)
            }}
          </div>
        )
      )
      ->Belt.Array.flatten
      ->React.array}
    </div>
  </div>
}



