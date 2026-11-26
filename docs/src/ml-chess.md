---
title: "Machine learning: the chess end game"
lead: Train ML.NET models on a white king and a white rook against a black king, test them on positions they have not seen, save them, and use them to predict the result of a game.
---

A white king and a white rook against a black king: is the game a draw, or in how many moves does white win? The data set has 28,056 positions with their results (the "chess end game" data of the UCI repository). The example `samples/UsingDotNet/machinelearning/ChessEndgame` trains **twelve combinations of algorithm and features** on 70 percent of the positions, tests them on the other 30 percent, saves every model, and uses a saved model to predict the result of a position. It is a program of Ring that uses ML.NET through RingDotNet: there is no C# in it.

The result of a position is one of eighteen words: `draw`, or `zero` to `sixteen`, the number of moves that white needs to win with the best play.

## Run it

```
cd samples/UsingDotNet/machinelearning/ChessEndgame
ring train.ring                 # split 70 / 30, train, test, save the models (about half a minute)
ring evaluate.ring              # load the saved models and test them again
ring predict.ring a1 b3 c2      # the result of a position: white king a1, white rook b3, black king c2
```

The first run downloads ML.NET (the packages of `ChessEndgame.csproj`) from nuget.org and makes the Ring classes of its DLLs; the next runs only load them. `ring train.ring --quick` tries three algorithms on a seventh of the data.

| Program | What it does |
|---|---|
| `train.ring` | splits the data, trains the algorithms, tests them, saves each model in `models`, ranks them |
| `evaluate.ring` | loads the saved models and tests them: the accuracy of each, then the best one result by result |
| `predict.ring` | loads a saved model (the best one, or `--model=tree_engineered`) and gives the result of the positions that you name |
| `chesslib.ring` | getting ML.NET, the split, the features and the algorithms, used by the three programs |

## 70 percent to train, 30 percent to test

A model must be tested on positions that it has not learned from, or its accuracy tells nothing: a model could remember every position it saw. `chessSplit()` shuffles the positions and writes `data/train.csv` (19,639 positions) and `data/test.csv` (8,417 positions). The shuffle uses a generator of numbers that is the same on every computer (`seed * 16807 mod 2147483647`), so the split is the same each time, and no position is in both files.

```ring
nSeed = 42
for nPlace = nRows to 2 step -1                     # a shuffle (Fisher and Yates)
	nSeed = (nSeed * 16807) % 2147483647
	nOther = 1 + floor(nSeed / 2147483647 * nPlace)
	cSwap = aRows[nPlace]
	aRows[nPlace] = aRows[nOther]
	aRows[nOther] = cSwap
next
nTrain = floor(nRows * 0.7)                         # the first 70 percent train, the rest test
```

## The features

The data gives the six squares: the file and the rank of each piece. `chessFeatures()` turns a position into numbers, and the example tries three sets of them:

| Set | What the algorithm reads |
|---|---|
| `squares` | the six numbers: the files a to h as 1 to 8, and the ranks |
| `onehot` | each of the six numbers as a one-hot vector (a 0 or a 1 for each of the 8 values: 48 numbers). A linear model cannot tell much from the number of a rank, but it can learn a weight for each square. |
| `engineered` | the six numbers and what a player sees at a glance: the distance between the kings, how near the black king is to the edge, the distance of the rook from each king, whether the white king guards the rook, whether the black king can take it, and whether the rook is on the file or the rank of the black king |

## The algorithms

ML.NET has algorithms for many classes (`MulticlassClassification.Trainers`), and binary algorithms that `OneVersusAll` turns into algorithms for many classes: it trains one model for each result, and the model with the highest score answers. Each trainer is one call, and the rest of the pipeline is the same:

```ring
oPipeline = oMl.Transforms.Conversion.callMethod("MapValueToKey",["Label","GameResult"])      # the result as a key
oPipeline = oPipeline.callMethod("Append",[chessFeaturePipeline(oMl,"engineered")])             # the features
oPipeline = oPipeline.callMethod("Append",[oMl.MulticlassClassification.Trainers.callMethod("LightGbm",["Label","Features"])])
oPipeline = oPipeline.callMethod("Append",[oMl.Transforms.Conversion.callMethod("MapKeyToValue",["PredictedResult","PredictedLabel"])])   # the answer as the word

oModel = oPipeline.callMethod("Fit",[oTrain])                                                    # learn from the training positions
aPredicted = chessColumn(oModel.Transform(oTest),"System.String","PredictedResult")             # answer for the test positions
```

These are the results of `ring train.ring` (the accuracy is the share of the 8,417 test positions whose result is exactly right; "within 1" also accepts a win that is one move off):

| Algorithm | Features | Accuracy | Within 1 |
|---|---|---|---|
| LightGBM (boosted trees) | engineered | **82.1%** | 95.7% |
| Boosted trees: FastTree (one versus all) | engineered | 80.6% | 95.2% |
| LightGBM (boosted trees) | squares | 80.6% | 95.7% |
| Decision tree (one versus all) | engineered | 60.3% | 82.0% |
| Random forest (one versus all) | engineered | 57.8% | 83.4% |
| Decision tree (one versus all) | squares | 45.7% | 69.2% |
| Logistic regression (L-BFGS) | onehot | 38.7% | 67.8% |
| Logistic regression (SDCA) | onehot | 37.1% | 65.0% |
| Linear model (SDCA, no calibration) | onehot | 35.8% | 62.1% |
| Averaged perceptron (one versus all) | onehot | 35.2% | 64.2% |
| Naive Bayes | onehot | 33.0% | 62.4% |
| Linear SVM (one versus all) | onehot | 28.1% | 60.0% |

What the numbers show:

- **Trees beat lines.** The result of a position depends on how the pieces are placed against each other, not on a weighted sum of squares: logistic regression stays below 40 percent, boosted trees reach 80 percent.
- **Boosting beats one tree.** A single decision tree gets 60 percent with the engineered features; trees that correct each other's mistakes (FastTree, LightGBM) get 80 percent. A forest of 100 trees that are trained independently gets about the same as one tree here (57.8 percent against 60.3).
- **The features matter.** The same single tree goes from 45.7 to 60.3 percent when it is given the distances, and LightGBM from 80.6 to 82.1.
- **Almost right is common.** The best model is wrong by one move for another 14 percent of the positions: 95.7 percent are right or one move off. `evaluate.ring` shows it result by result: every draw of the test positions is found, and no win is taken for a draw.
- **The numbers vary a little.** Trainers that use several threads (LightGBM, SDCA) do not give exactly the same numbers on every run.

## Save the models, and use them

Each model is saved with the schema of the data that trained it. A model file has the whole pipeline in it: the features, the trainer, and the answer as a word.

```ring
oMl.Model.callMethod("Save",[oModel,oTrain.getProp("Schema"),currentdir() + "/models/lightgbm_engineered.zip"])
```

`evaluate.ring` and `predict.ring` start from the files. `Load` answers a list: the model, and the schema that was saved with it.

```ring
aLoaded = oMl.Model.callMethod("Load",[currentdir() + "/models/lightgbm_engineered.zip"])
aPredicted = chessColumn(aLoaded[1].Transform(chessLoad(oMl,"data/positions.csv")),"System.String","PredictedResult")
```

For a position that you name, `predict.ring` writes a file with one line for it (the features that `chessFeatures()` makes, and a word in the column of the result, which the model ignores), and the model answers:

```
> ring predict.ring e4 e1 h8
the model: LightGBM (boosted trees) [engineered], the best of those that train.ring made

white king e4, white rook e1, black king h8:
  8 . . . . . . . k
  7 . . . . . . . .
  6 . . . . . . . .
  5 . . . . . . . .
  4 . . . . K . . .
  3 . . . . . . . .
  2 . . . . . . . .
  1 . . . . R . . .
    a b c d e f g h
  the model says: white wins in 9 moves
```

## The test of the example

`samples/UsingDotNet/tests/packages/pkgtest_mlnet_chess.ring` runs the three programs the way a user does: `train.ring --quick`, `evaluate.ring` and `predict.ring`. It checks the 70 / 30 split (the number of positions in each file, and that no position is in both), that the models are saved and ranked, that the saved model gives the accuracy that the training measured, and the answers for positions, for another model, and for positions that are not positions (two pieces on a square, kings that touch).
