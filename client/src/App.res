//@module("./assets/rescript-logo.svg")
//external rescript: string = "default"

//@module("./assets/vite.svg")
//external vite: string = "default"

@val external fetch: string => promise<'response> = "fetch"

type response
@send external json: response => promise<JSON.t> = "json"

@react.component
let make = () => {

  //let initialLetters = [
  //      "A","B","C","D","E","F","G",
  //      "H","I","J","K","L","M","N",
  //      "O","P","Q","R","S","T","U"
  //    ]
  
  // Grid dimensions
      let gridRows = 20
      let gridCols = 20
    
      let (letters, setLetters) = React.useState(() => [])
      let (dragged, setDragged) = React.useState(() => None)
      let (grid, setGrid) = React.useState(() => Array.make(~length=gridRows * gridCols, None))
      let (loading, setLoading) = React.useState(() => true)

    // Fetch tiles from server on mount
      React.useEffect0(() => {
        let fetchTiles = async () => {
          try {
            let response = await fetch("http://localhost:8080/get_random_tiles?count=21")
            let json = await response->json
            
            // Parse the JSON array of strings
            let tiles = switch json->JSON.Decode.array {
            | Some(arr) => arr->Array.filterMap(JSON.Decode.string)
            | None => []
            }
            
            setLetters(_ => tiles)
            setLoading(_ => false)
          } catch {
          | _ => {
              Console.log("Failed to fetch tiles")
              setLoading(_ => false)
            }
          }
        }
        fetchTiles()->ignore
        None
      })



  let handleDragStart = letter => e => {
        //e->ReactEvent.Synthetic.preventDefault
        setDragged(_ => Some(letter))
      }
    
      let handleDrop = index => e => {
        e->ReactEvent.Synthetic.preventDefault
        
        switch dragged {
        | Some(letter) => {
            // Add letter to grid
            setGrid(prevGrid => {
              let newGrid = Array.copy(prevGrid)
              newGrid[index] = Some(letter)
              newGrid
            })
            
            // Remove letter from available letters
            setLetters(prevLetters => 
              prevLetters->Array.filter(l => l !== letter)
            )
            
            setDragged(_ => None)
          }
        | None => ()
        }
      }
    
      let handleDragOver = e => {
        e->ReactEvent.Synthetic.preventDefault
      }
    
      let handleRemoveFromGrid = (index, letter) => {
        // Remove from grid
        setGrid(prevGrid => {
          let newGrid = Array.copy(prevGrid)
          newGrid[index] = None
          newGrid
        })
        
        // Add back to letters
        setLetters(prevLetters => Array.concat(prevLetters, [letter]))
      }

  
      <div className="max-w-4xl mx-auto p-8 overflow-auto">
        <h2 className="text-2xl font-bold mb-4"> {"Available Letters"->React.string} </h2>
        <div className="flex gap-3 mb-8 flex-wrap min-h-20 p-4 bg-gray-100 rounded overflow-visible">
          {letters->Array.length > 0
            ? letters
              ->Array.map(letter =>
                <div
                  key=letter
                  draggable=true
                  onDragStart={handleDragStart(letter)}
                  className="cursor-move px-4 py-2 bg-blue-300 rounded shadow-md text-xl font-bold select-none hover:bg-blue-400"
                >
                  {React.string(letter)}
                </div>
              )
              ->React.array
            : <div className="text-gray-500"> {"No letters available"->React.string} </div>
          }
        </div>
    
<h2 className="text-2xl font-bold mb-4"> {"Grid"->React.string} </h2>
    <div className="inline-block border border-gray-400">
      <div style={ReactDOM.Style.make(~display="grid", ~gridTemplateColumns="repeat(20, 2rem)", ())}>
        {grid
          ->Array.mapWithIndex((item, index) =>
            <div
              key={Int.toString(index)}
              onDrop={handleDrop(index)}
              onDragOver={handleDragOver}
              className="w-8 h-8 border border-gray-300 flex items-center justify-center bg-white hover:bg-gray-50"
            >
              {switch item {
              | Some(letter) =>
                <div
                  onClick={_ => handleRemoveFromGrid(index, letter)}
                  className="cursor-pointer w-full h-full flex items-center justify-center bg-green-400 text-sm font-bold select-none hover:bg-red-400"
                  title="Click to remove"
                >
                  {React.string(letter)}
                </div>
              | None => React.null
              }}
            </div>
          )
          ->React.array}
      </div>
    </div>
        
        <p className="mt-4 text-sm text-gray-600">
          {"Drag letters to the grid. Click on placed letters to remove them."->React.string}
        </p>
      </div>

}

/*open Belt

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
  // Drag event handlers (Synthetic.t only)
  // ----------------------------
  
  
  let handleDragStart = (letter: string) => (e: ReactEvent.Synthetic.t) => {
    e->ReactEvent.Synthetic.preventDefault
    setDragged(_ => Some(letter))
  }

  let handleDragOver = (e: ReactEvent.Synthetic.t) =>
    e->ReactEvent.Synthetic.preventDefault

  let handleDrop = (r: int, c: int, e: ReactEvent.Synthetic.t) => {
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
          onDragStart={e => {
                        e->ReactEvent.Synthetic.preventDefault
                        setDragged(_ => Some(letter))
                      }}
          /*onDragStart={handleDragStart(letter)}*/
          className="cursor-move px-4 py-2 bg-blue-300 rounded shadow-md text-xl font-bold select-none"
        >
          {React.string(letter)}
        </div>
      )
      ->React.array}
    </div>

    /* Grid */
    <div
          className="grid gap-1"
                    
        >
        
      {grid
      ->Belt.Array.mapWithIndex((rowIdx, row) =>
        row
        ->Belt.Array.mapWithIndex((colIdx, cell) =>
          <div
                      key={`${Belt.Int.toString(rowIdx)}-${Belt.Int.toString(colIdx)}`}
                      onDragOver={e => e->ReactEvent.Synthetic.preventDefault}
                      onDrop={e => {
                        e->ReactEvent.Synthetic.preventDefault
                    
                        switch dragged {
                        | None => ()
                        | Some(letter) =>
                            setGrid(grid =>
                              grid
                              ->Belt.Array.mapWithIndex((r, row) =>
                                row
                                ->Belt.Array.mapWithIndex((c, cell) =>
                                  if r == rowIdx && c == colIdx {
                                    Some(letter)*/
                                 /*  } else {
                                    cell
                                  }
                                )
                              )
                            )
                            setDragged(_ => None)
                        }
                      }}
                      className="w-10 h-10 border border-gray-400 bg-white flex items-center justify-center"
                    >
                      {switch Belt.Array.get(grid, rowIdx) {
                      | None => React.null
                      | Some(row) =>
                          switch Belt.Array.get(row, colIdx) {
                          | None => React.null
                          | Some(letterOpt) =>
                              switch letterOpt {
                              | None => React.null
                              | Some(letter) => React.string(letter) // ✅ letter is string
                              }
                          }
                      }
                      }
                    </div>
        )
      )
      /*->Belt.Array.flatten*/
      ->Belt.Array.concatMany
      ->React.array}
    </div>
  </div>
}

let _ = make*/


