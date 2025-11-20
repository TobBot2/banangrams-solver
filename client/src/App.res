@module("./assets/rescript-logo.svg")
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


  /*let fenLink = "https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation"

  <div className="p-6">
    // Header
    <h1 className="text-3xl font-semibold"> {"Chess Move Suggester"->React.string} </h1>
    <p>
      {React.string("Please input your current chessboard state (in ")}
      <a className="text-blue-600 hover:underline" href=fenLink> {React.string("FEN Format")} </a>
      {React.string("), the color to move (white or black), and the AI difficulty level (1 to 3).")}
    </p>
    <br />
    <h2 className="text-xl font-semibold"> {React.string("Sample boards:")} </h2>
    <p>
      {React.string("Default board: rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR (White to move)")}
    </p>
    <p>
      {React.string("Board with one possible move: 7k/3n1KRP/6P1/8/8/8/8/4r3 (White to move)")}
    </p>
    <br />
    // Create form, most of the logic is in components/Form.res
    <div className="flex">
      /*<Form />*/
    </div>
    <br />
  </div> */

}
