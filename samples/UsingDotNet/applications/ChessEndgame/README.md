# Chess end game: predict the result of a game with ML.NET

A white king and a white rook against a black king: how many moves does white need to win, or is it a draw? `data/chess.csv` has 28,056 positions with their results
(the end game data set of the UCI repository). The example trains many ML.NET algorithms on 70 percent of the positions, tests them on the other 30 percent, saves the
models, and uses a saved model to predict the result of a game.

Run the programs from this folder (the first run downloads ML.NET from nuget.org: `dotnet publish` and the class generator run by themselves):

| Program | What it does |
|---|---|
| `ring train.ring` | splits the data (70 / 30), trains 15 combinations of algorithm and features, tests them, saves every model in `models`, and ranks them. About a minute. `--quick` tries three of them on a seventh of the data. |
| `ring evaluate.ring` | loads the saved models and tests them again on the 30 percent: the accuracy of each, then the best one result by result. |
| `ring predict.ring a1 b3 c2` | the result of a position: the white king on a1, the white rook on b3, the black king on c2 (more positions: three squares for each). Without squares it shows positions of the test file with their real results. `--model=tree_engineered` uses another saved model. |
| `ring ChessEndgame.ring` | **the window**: drag the pieces on the board and the models answer; the data, the statistics, and the models (train and test them). |

The files: `chesslib.ring` (getting ML.NET, the split, the features, the algorithms), `ChessEndgame.csproj` (the packages), `data/chess.csv` (the data).
`train.ring` makes `data/train.csv`, `data/test.csv` and `models/`.

The page [Machine learning: the chess end game](../../../../docs/ml-chess.html) of the documentation explains it.
