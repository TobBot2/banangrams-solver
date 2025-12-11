@val external fetch: string => promise<'response> = "fetch"
@val external fetchOptions: (string, 'options) => promise<'response> = "fetch"

type response
@send external json: response => promise<JSON.t> = "json"
@val external alert: string => unit = "window.alert"

@react.component
let make = () => {
  let gridRows = 31
  let gridCols = 31
  
  let (playerId, setPlayerId) = React.useState(() => None)
  let (letters, setLetters) = React.useState(() => [])
  let (dragged, setDragged) = React.useState(() => None)
  let (grid, setGrid) = React.useState(() => {
    let emptyCell: option<(string, string)> = None
    Array.make(~length=gridRows * gridCols, emptyCell)
  })
  let (loading, setLoading) = React.useState(() => true)
  let (hintWord, setHintWord) = React.useState(() => None)
  let (tilesRemaining, setTilesRemaining) = React.useState(() => 0)

  // Use ref because it updates synchronously, unlike state
  let joinInitiated = React.useRef(false)

  let indexToCoord = index => {
    let row = index / gridCols
    let col = mod(index, gridCols)
    let centerRow = gridRows / 2
    let centerCol = gridCols / 2
    let x = col - centerCol
    let y = centerRow - row
    (x, y)
  }

  // Join game on mount
  React.useEffect0(() => {
    if !joinInitiated.current {
      joinInitiated.current = true 
    let joinGame = async () => {
  try {
    let options = {
      "method": "POST",
      "headers": {"Content-Type": "application/json"},
    }
    
    let response = await fetchOptions("http://localhost:8080/join", options)
    let json = await response->json
    
    // Decode to object/dict
    switch json->Js.Json.decodeObject {
    | Some(obj) => {
        // Extract fields safely
        let playerId = switch obj->Js.Dict.get("playerId") {
        | Some(val) => val->Js.Json.decodeString
        | None => None
        }
        
        let tiles = switch obj->Js.Dict.get("tiles") {
        | Some(val) => switch val->Js.Json.decodeArray {
          | Some(arr) => arr->Array.filterMap(item => Js.Json.decodeString(item))
          | None => []
          }
        | None => []
        }
        
        let remaining = switch obj->Js.Dict.get("tilesRemaining") {
        | Some(val) => switch val->Js.Json.decodeNumber {
          | Some(n) => Float.toInt(n)
          | None => 0
          }
        | None => 0
        }
        
        switch playerId {
        | Some(id) => {
            let tilesWithIds = tiles->Array.mapWithIndex((letter, idx) => 
              (letter, Int.toString(idx))
            )
            
            setPlayerId(_ => Some(id))
            setLetters(_ => tilesWithIds)
            setTilesRemaining(_ => remaining)
            setLoading(_ => false)
          }
        | None => {
            Console.log("Missing playerId in response")
            setLoading(_ => false)
            joinInitiated.current = false
          }
        }
      }
    | None => {
        Console.log("Failed to decode JSON object")
        setLoading(_ => false)
        joinInitiated.current = false
      }
    }
  } catch {
  | exn => {
      Console.log2("Failed to join game:", exn)
      setLoading(_ => false)
      joinInitiated.current = false
    }
  }
}
  joinGame()->ignore  // Call the async function and ignore the promise
    }
    None  // Return None for cleanup
  })

  // Poll for game state updates every 2 seconds
React.useEffect0(() => {
  let pollGameState = async () => {
    try {
      let response = await fetch("http://localhost:8080/game_state")
      let json = await response->json
      
      switch json->Js.Json.decodeObject {
      | Some(obj) => {
          let remaining = switch obj->Js.Dict.get("tilesRemaining") {
          | Some(val) => switch val->Js.Json.decodeNumber {
            | Some(n) => Float.toInt(n)
            | None => tilesRemaining  // Keep current value on error
            }
          | None => tilesRemaining
          }
          setTilesRemaining(_ => remaining)
        }
      | None => ()
      }
    } catch {
    | _ => Console.log("Failed to fetch game state")
    }
  }
  
  // Poll every 2 seconds
  let intervalId = Js.Global.setInterval(() => {
    pollGameState()->ignore
  }, 2000)

  
  // Cleanup
  Some(() => Js.Global.clearInterval(intervalId))
})

let buildBoardMap = grid =>
  grid
  ->Array.mapWithIndex((item, index) => {
      switch item {
      | Some((letter, _id)) => {
          let (x, y) = indexToCoord(index)
          let key = Int.toString(x) ++ "," ++ Int.toString(y)
          Some((key, JSON.Encode.string(letter)))
        }
      | None => None
      }
    })
  ->Array.filterMap(x => x)
  ->Array.reduce(Js.Dict.empty(), (dict, (key, encoded)) => {
      Js.Dict.set(dict, key, encoded)
      dict
    })

let buildRack = letters =>
  letters->Array.map(((letter, _id)) => JSON.Encode.string(letter))

/* Build a JSON payload with variable fields */
let buildPayload = (playerId, ~board=?, ~rack=?) => {
  let payload = Js.Dict.empty()
  Js.Dict.set(payload, "playerId", JSON.Encode.string(playerId))
  switch board {
  | Some(b) => Js.Dict.set(payload, "board", JSON.Encode.object(b))
  | None => ()
  }
  switch rack {
  | Some(r) => Js.Dict.set(payload, "rack", JSON.Encode.array(r))
  | None => ()
  }
  payload->JSON.Encode.object->JSON.stringify
}

/* POST helper */
let postJson = (url, body) => {
  let options = {
    "method": "POST",
    "headers": {"Content-Type": "application/json"},
    "body": body,
  }
  fetchOptions(url, options)
}

let handleHint = async () => {
  switch playerId {
  | None => alert("Not connected to game")
  | Some(id) => {
      try {
        let board = buildBoardMap(grid)
        let rack = buildRack(letters)
        let options = buildPayload(id, ~board=board, ~rack=rack)

        let response = await postJson("http://localhost:8080/hint", options)
        let json = await response->json

        let word =
          switch json->JSON.Decode.string {
          | Some(w) => w
          | None => ""
          }

        setHintWord(_ => Some(word))
      } catch {
      | _ =>
        Console.log("Failed to fetch hint")
        setHintWord(_ => None)
      }
    }
  }
}

let handleValidate = async () => {
  switch playerId {
  | None => alert("Not connected to game")
  | Some(id) => {
      try {
        let board = buildBoardMap(grid)
        let rack = buildRack(letters)
        let options = buildPayload(id, ~board=board, ~rack=rack)

        let response = await postJson("http://localhost:8080/validate", options)
        let json = await response->json

        let status = response["status"]
        if status >= 200 && status < 300 {
          alert("✓ Board is valid!")
        } else {
          switch json->JSON.Decode.string {
          | Some(msg) => alert("✗ " ++ msg)
          | None => alert("✗ Validation failed")
          }
        }
      } catch {
      | _ => alert("✗ Failed to validate board")
      }
    }
  }
}

/*let handleValidate = () => {
  sendBoardToServer(grid)->ignore
}*/

/*
  let sendBoardToServer = async grid => {
    switch playerId {
    | None => alert("Not connected to game")
    | Some(id) => {
        try {
          let boardMap = grid
            ->Array.mapWithIndex((item, index) => {
              switch item {
              | Some((letter, _id)) => {
                  let (x, y) = indexToCoord(index)
                  let key = Int.toString(x) ++ "," ++ Int.toString(y)
                  Some((key, letter))
                }
              | None => None
              }
            })
            ->Array.filterMap(x => x)
            ->Array.reduce(Js.Dict.empty(), (dict, (key, letter)) => {
              Js.Dict.set(dict, key, JSON.Encode.string(letter))
              dict
            })
          
          let payload = Js.Dict.empty()
          Js.Dict.set(payload, "playerId", JSON.Encode.string(id))
          Js.Dict.set(payload, "board", JSON.Encode.object(boardMap))
          
          let json_data = payload->JSON.Encode.object->JSON.stringify
          
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
            switch json->JSON.Decode.string {
            | Some(msg) => alert("✗ " ++ msg)
            | None => alert("✗ Validation failed")
            }
          }
        } catch {
        | _ => alert("✗ Failed to validate board")
        }
      }
    }
  }

  let handleValidate = () => {
    sendBoardToServer(grid)->ignore
  }*/

  let fetchMoreTiles = async () => {
  switch playerId {
  | None => Console.log("No player ID")
  | Some(id) => {
      try {
        let payload = Js.Dict.empty()
        Js.Dict.set(payload, "playerId", JSON.Encode.string(id));
        Js.Dict.set(payload, "count", JSON.Encode.int(3));
        
        let json_data = payload->JSON.Encode.object->JSON.stringify
        
        let options = {
          "method": "POST",
          "headers": {"Content-Type": "application/json"},
          "body": json_data
        }
        
        let response = await fetchOptions("http://localhost:8080/draw_tiles", options)
        let json = await response->json
        
        // Decode to object/dict
        switch json->Js.Json.decodeObject {
        | Some(obj) => {
            let tiles = switch obj->Js.Dict.get("tiles") {
            | Some(val) => switch val->Js.Json.decodeArray {
              | Some(arr) => arr->Array.filterMap(item => Js.Json.decodeString(item))
              | None => []
              }
            | None => []
            }
            
            let remaining = switch obj->Js.Dict.get("tilesRemaining") {
            | Some(val) => switch val->Js.Json.decodeNumber {
              | Some(n) => Float.toInt(n)
              | None => 0
              }
            | None => 0
            }

            setLetters(prevLetters => {
              let maxId = prevLetters
                ->Array.map(((_, id)) => {
                  switch Int.fromString(id) {
                  | Some(n) => n
                  | None => 0
                  }
                })
                ->Array.reduce(0, (acc, n) => max(acc, n))
              
              let newTilesWithIds = tiles->Array.mapWithIndex((letter, idx) => 
                (letter, Int.toString(maxId + idx + 1))
              )
              
              Array.concat(prevLetters, newTilesWithIds)
            })
            
            /*let tilesWithIds = tiles->Array.mapWithIndex((letter, idx) => 
              (letter, Int.toString(idx))
            )

            
            setLetters(_ => tilesWithIds)*/
            setTilesRemaining(_ => remaining)
          }
        | None => Console.log("Failed to decode JSON object")
        }
      } catch {
      | exn => Console.log2("Failed to draw tiles:", exn)
      }
    }
  }
}

/*
  let handleHint = async () => {
  switch playerId {
  | None => alert("Not connected to game")
  | Some(id) => {
      try {
        // Build board map from grid (same as validation)
        let boardMap = grid
          ->Array.mapWithIndex((item, index) => {
            switch item {
            | Some((letter, _id)) => {
                let (x, y) = indexToCoord(index)
                let key = Int.toString(x) ++ "," ++ Int.toString(y)
                Some((key, letter))
              }
            | None => None
            }
          })
          ->Array.filterMap(x => x)
          ->Array.reduce(Js.Dict.empty(), (dict, (key, letter)) => {
            Js.Dict.set(dict, key, JSON.Encode.string(letter))
            dict
          })
        
        // Build rack from letters
        let rack = letters->Array.map(((letter, _id)) => JSON.Encode.string(letter))
        
        let payload = Js.Dict.empty()
        Js.Dict.set(payload, "playerId", JSON.Encode.string(id))
        Js.Dict.set(payload, "board", JSON.Encode.object(boardMap))
        Js.Dict.set(payload, "rack", JSON.Encode.array(rack))
        
        let json_data = payload->JSON.Encode.object->JSON.stringify
        
        let options = {
          "method": "POST",
          "headers": {"Content-Type": "application/json"},
          "body": json_data
        }
        
        let response = await fetchOptions("http://localhost:8080/hint", options)
        let json = await response->json
        
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
  }
}*/
  let handleDragStart = tileWithId => e => {
    setDragged(_ => Some(tileWithId))
  }

  let handleRemoveFromGrid = (index, (letter, id)) => {
    setGrid(prevGrid => {
      let newGrid = Array.copy(prevGrid)
      newGrid[index] = None
      newGrid
    })
    
    setLetters(prevLetters => Array.concat(prevLetters, [(letter, id)]))
  }

  let handleDrop = index => e => {
    e->ReactEvent.Synthetic.preventDefault
    
    switch dragged {
    | Some((letter, id)) => {
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

  if loading {
    <div className="max-w-4xl mx-auto p-8 text-center">
      <p className="text-xl"> {"Joining game..."->React.string} </p>
    </div>
  } else {
    <div className="max-w-4xl mx-auto p-8 pt-150 overflow-auto">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-2xl font-bold"> 
            {"Available Letters"->React.string}
          </h2>
          {switch playerId {
          | Some(id) => 
            <p className="text-xs text-gray-500 mt-1">
              {("Player: " ++ id)->React.string}
            </p>
          | None => React.null
          }}
          {switch hintWord {
          | Some(word) => 
            <p className="text-sm text-blue-600 mt-1">
              {("Hint: " ++ word)->React.string}
            </p>
          | None => React.null
          }}
          <p className="text-sm text-gray-600 mt-1">
            {("Tiles remaining in bag: " ++ Int.toString(tilesRemaining))->React.string}
          </p>
          <p className="text-sm text-blue-600 mt-1">
            {"Place your first letter in the middle (blue cell)"->React.string}
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
            {"Draw 3"->React.string}
          </button>
          <button 
            onClick={_ => handleValidate()->ignore}
            className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600">
            {"Validate"->React.string}
          </button>
        </div>
      </div>
      
      <div className="flex gap-3 mb-8 flex-wrap min-h-20 p-4 bg-gray-100 rounded overflow-visible">
        {letters->Array.length > 0
          ? letters
            ->Array.mapWithIndex((letter, index) => {
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
        <div style={ReactDOM.Style.make(~display="grid", ~gridTemplateColumns="repeat(31, 2rem)", ())}>
          {grid
            ->Array.mapWithIndex((item, index) => {
              let centerIndex = (gridRows * gridCols) / 2
              let isCenter = index === centerIndex
              let bgColor = isCenter ? "bg-blue-200" : "bg-white"
              let (x, y) = indexToCoord(index)
              let showLabel = x === 0 || y === 0
              <div
                key={Int.toString(index)}
                onDrop={handleDrop(index)}
                onDragOver={handleDragOver}
                className={("relative w-8 h-8 border border-gray-300 flex items-center justify-center hover:bg-gray-50 " ++ bgColor )}
              >
                 //{showLabel ? 
                 // <div className="absolute inset-0 flex items-center justify-center text-xs text-gray-400 font-semibold pointer-events-none">
                 //   {React.string(x === 0 ? Int.toString(y) : Int.toString(x))}
                 // </div>
                //: React.null}
                {switch item {
                | Some(item) => {
                    let (actual_letter, id) = item
                    <div
                      onClick={_ => handleRemoveFromGrid(index, item)}
                      className="cursor-pointer w-full h-full flex items-center justify-center bg-green-400 text-sm font-bold select-none hover:bg-red-400"
                      title="Click to remove"
                    >
                      {React.string(actual_letter)}
                    </div>
                  }
                | None => //React.null
                {showLabel ? 
                  <div className="absolute inset-0 flex items-center justify-center text-xs text-gray-400 font-semibold pointer-events-none">
                    {React.string(x === 0 ? Int.toString(y) : Int.toString(x))}
                  </div>
                : React.null}
                }}
              </div>
            })
            ->React.array}
        </div>
      </div>
      
      <p className="mt-4 text-sm text-gray-600">
        {"Drag letters to the grid. Click placed letters to remove them."->React.string}
      </p>
    </div>
  }
}