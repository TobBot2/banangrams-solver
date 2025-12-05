@val external fetch: string => promise<'response> = "fetch"

@val external fetchOptions: (string, 'options) => promise<'response> = "fetch"

type response
@send external json: response => promise<JSON.t> = "json"

@val external alert: string => unit = "window.alert"


@react.component
let make = () => {
  
  // Grid dimensions
      let gridRows = 31
      let gridCols = 21
    
      let (letters, setLetters) = React.useState(() => [])
      let (dragged, setDragged) = React.useState(() => None)
      //let (grid, setGrid) = React.useState(() => Array.make(~length=gridRows * gridCols, None))
      //let (grid, setGrid) = React.useState(() => Array.make(~length=gridRows * gridCols, None:<option(string, string)>))
      let (grid, setGrid) = React.useState(() => {
  let emptyCell: option<(string, string)> = None
  Array.make(~length=gridRows * gridCols, emptyCell)
})
      let (loading, setLoading) = React.useState(() => true)
      let (hintWord, setHintWord) = React.useState(() => None)


    //helper function to get coordinates instead of index
    let indexToCoord = index => {
  let row = index / gridCols
  let col = mod(index, gridCols)
  let centerRow = gridRows / 2
  let centerCol = gridCols / 2
  let x = col - centerCol
  let y = centerRow - row  // Subtract to make y positive going up
  (x, y)
}

let sendBoardToServer = async grid => {
  try {
    let boardMap = grid
      ->Array.mapWithIndex((item, index) => {
        switch item {
        | Some((letter, _id)) => {  // Destructure and ignore the id
            let (x, y) = indexToCoord(index)
            let key = Int.toString(x) ++ "," ++ Int.toString(y)
            Some((key, letter))  // Only use the letter
          }
        | None => None
        }
      })
      ->Array.filterMap(x => x)
      ->Array.reduce(Js.Dict.empty(), (dict, (key, letter)) => {
        Js.Dict.set(dict, key, JSON.Encode.string(letter))
        dict
      })
    
    // Convert to JSON format
    let json_data = boardMap->JSON.Encode.object->JSON.stringify
     
    let options = {
      "method": "POST",
      "headers": {"Content-Type": "application/json"},
      "body": json_data
    }
    
    let response = await fetchOptions("http://localhost:8080/validate", options)
    let json = await response->json

     let status = response["status"]
    if status >= 200 && status < 300 {
      alert("✓ Board is valid!")
    } else {
      // Extract error message if available
      switch json->JSON.Decode.string {
      | Some(msg) => alert("✗ " ++ msg)
      | None => alert("✗ Validation failed")
      }
    }
    Console.log("Board submitted successfully")
    ()
  } catch {
  | _ => alert("✗ Failed to validate board")
  }
}


let handleValidate = () => {
  sendBoardToServer(grid)->ignore
}

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
            
            let tilesWithIds = tiles->Array.mapWithIndex((letter, idx) => 
        (letter, Int.toString(idx))
      )

            setLetters(_ => tilesWithIds)
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


// Fetch tiles from server on first visit only
/*React.useEffect0(() => {
  let storage = Webapi.Dom.Window.localStorage(Webapi.Dom.window)
  let stored = storage->Webapi.Dom.Storage.getItem("letters")

  switch stored {
  | Some(jsonStr) =>
      // Parse stored tiles and use them
      let savedTiles = jsonStr->JSON.parseAny->Belt.Option.flatMap(json =>
        JSON.Decode.array(json)->Belt.Option.map(arr =>
          arr->Array.filterMap(JSON.Decode.string)->Array.mapWithIndex((letter, idx) => (letter, Int.toString(idx)))
        )
      )->Belt.Option.getWithDefault([])

      setLetters(_ => savedTiles)
      setLoading(_ => false)

  | None =>
      // No saved letters → fetch from server once
      let fetchTiles = async () => {
        try {
          let response = await fetch("http://localhost:8080/get_random_tiles?count=21")
          let json = await response->json

          let tiles = switch json->JSON.Decode.array {
          | Some(arr) => arr->Array.filterMap(JSON.Decode.string)
          | None => []
          }

          let tilesWithIds =
            tiles->Array.mapWithIndex((letter, idx) => (letter, Int.toString(idx)))

          // Save to localStorage so refresh won't fetch again
          Web.Storage.localStorage->Web.Storage.setItem("letters", JSON.stringify(tiles))

          setLetters(_ => tilesWithIds)
        } catch {
        | _ =>
            Console.log("Failed to fetch tiles")
        }
        setLoading(_ => false)
      }
      fetchTiles()->ignore
  }

  None
})*/


let fetchMoreTiles = async () => {
  try {
    let response = await fetch("http://localhost:8080/get_random_tiles?count=3") // or whatever count
    let json = await response->json
    
    let tiles = switch json->JSON.Decode.array {
    | Some(arr) => arr->Array.filterMap(JSON.Decode.string)
    | None => []
    }
    
    // Add new tiles to existing ones
    setLetters(prev => {
      let maxId = prev->Array.reduce(0, (max, (_, id)) => {
        let idNum = Int.fromString(id)->Option.getOr(0)
        max > idNum ? max : idNum
      })
      
      let newTiles = tiles->Array.mapWithIndex((letter, idx) => 
        (letter, Int.toString(maxId + idx + 1))
      )
      
      Array.concat(prev, newTiles)
    })
  } catch {
  | _ => Console.log("Failed to fetch more tiles")
  }
}
    
  let handleHint = async () => {
  try {
    let response = await fetch("http://localhost:8080/hint")
    let json = await response->json
    
    // Assuming the server returns a word string
    let word = switch json->JSON.Decode.string {
    | Some(w) => w
    | None => ""
    }
    
    setHintWord(_ => Some(word))
  } catch {
  | _ => {
      Console.log("Failed to fetch hint")
      setHintWord(_ => None)
    }
  }
}





  let handleDragStart = tileWithId => e => {
        //e->ReactEvent.Synthetic.preventDefault
        setDragged(_ => Some(tileWithId))
      }

  let handleRemoveFromGrid = (index, (letter, id)) => {
        setGrid(prevGrid => {
          let newGrid = Array.copy(prevGrid)
          newGrid[index] = None
          newGrid
        })
        
        // Add back to letters
        setLetters(prevLetters => Array.concat(prevLetters, [(letter, id)]))
      }
    
  let handleDrop = index => e => {
        e->ReactEvent.Synthetic.preventDefault
        
        switch dragged {
        | Some((letter, id)) => {
            // Add letter to grid
            setGrid(prevGrid => {
              let newGrid = Array.copy(prevGrid)
              switch newGrid[index] {
              | Some(Some((letter_old, id_old))) => 
                  setLetters(prevLetters => Array.concat(prevLetters, [(letter_old, id_old)]))
              | Some(None) => ()
              | None => ()
              }
              newGrid[index] = Some((letter, id))
              newGrid
            })
            
            // Remove letter from available letters
            setLetters(prevLetters => 
              prevLetters->Array.filter(((_, tileId)) => tileId !== id)
            )
            
            setDragged(_ => None)
          }
        | None => ()
        }
      }
    
      let handleDragOver = e => {
        e->ReactEvent.Synthetic.preventDefault
      }
    
      

  
      <div className="max-w-4xl mx-auto p-8 pt-120 overflow-auto">
        //<h2 className="text-2xl font-bold mb-4"> {"Available Letters"->React.string} </h2>
        <div className="flex items-center justify-between mb-4">
            <div>
    <h2 className="text-2xl font-bold"> {"Available Letters"->React.string} </h2>
    {switch hintWord {
    | Some(word) => 
      <p className="text-sm text-blue-600 mt-1">
        {("Hint: " ++ word)->React.string}
      </p>
    | None => React.null
    }}
    <p className="text-sm text-blue-600 mt-1">
        {"Please place your first letter in the middle of the board (on the blue grid cell)"->React.string}
    </p>
  </div>
  <div className="flex gap-2">
    <button 
      onClick={_ => handleHint()->ignore}
      className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
      {"Hint"->React.string}
    </button>
    <button 
      onClick={_ => fetchMoreTiles()->ignore}
      className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
      {"Dump"->React.string}
    </button>
    <button 
      onClick={_ => handleValidate()->ignore}
      className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
      {"Validate"->React.string}
    </button>
  </div>
</div>
        <div className="flex gap-3 mb-8 flex-wrap min-h-20 p-4 bg-gray-100 rounded overflow-visible">
          {letters->Array.length > 0
            ? letters
              ->Array.mapWithIndex((letter, index) =>{
               let (actual_letter, id) = letter
                <div
                  key={actual_letter ++ "-" ++ Int.toString(index)}
                  draggable=true
                  onDragStart={handleDragStart(letter)}
                  className="cursor-move px-4 py-2 bg-blue-300 rounded shadow-md text-xl font-bold select-none hover:bg-blue-400"
                >
                  {React.string(actual_letter)}
                </div>
          })
              ->React.array
            : <div className="text-gray-500"> {"No letters available"->React.string} </div>
          }
        </div>
    
<h2 className="text-2xl font-bold mb-4"> {"Grid"->React.string} </h2>
    <div className="inline-block border border-gray-400">
      <div style={ReactDOM.Style.make(~display="grid", ~gridTemplateColumns="repeat(21, 2rem)", ())}>
        {grid
          ->Array.mapWithIndex((item, index) => {
            let centerIndex = (gridRows * gridCols) / 2
            let isCenter = index === centerIndex
            let bgColor = isCenter ? "bg-blue-200" : "bg-white"
            <div
              key={Int.toString(index)}
              onDrop={handleDrop(index)}
              onDragOver={handleDragOver}
              className={("w-8 h-8 border border-gray-300 flex items-center justify-center hover:bg-gray-50 " ++ bgColor )}
            >
              {switch item {
              | Some(item) =>{
                let (actual_letter, id) = item
                <div
                  onClick={_ => handleRemoveFromGrid(index, item)}
                  className="cursor-pointer w-full h-full flex items-center justify-center bg-green-400 text-sm font-bold select-none hover:bg-red-400"
                  title="Click to remove"
                >
                  {React.string(actual_letter)}
                </div> }
              | None => React.null
              }}
            </div>
         } )
          ->React.array}
      </div>
    </div>
        
        <p className="mt-4 text-sm text-gray-600">
          {"Drag letters to the grid. Click on placed letters to remove them."->React.string}
        </p>
      </div>

}