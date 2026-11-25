using Microsoft.ML.Data;

namespace MlHelpers
{
	/* a row with two numbers that predict a number (regression): Label is what the model learns to predict */
	public class RegressionRow
	{
		public float F1 { get; set; }
		public float F2 { get; set; }
		public float Label { get; set; }
	}

	/* what a regression model predicts */
	public class RegressionPrediction
	{
		[ColumnName("Score")]
		public float Score { get; set; }
	}

	/* a row with two numbers that predict a yes or a no (classification) */
	public class ClassRow
	{
		public float F1 { get; set; }
		public float F2 { get; set; }
		public bool Label { get; set; }
	}

	/* what a classification model predicts: the class, the probability, and the raw score */
	public class ClassPrediction
	{
		[ColumnName("PredictedLabel")]
		public bool PredictedLabel { get; set; }
		public float Probability { get; set; }
		public float Score { get; set; }
	}

	/* a row with two numbers and no label (clustering) */
	public class PointRow
	{
		public float F1 { get; set; }
		public float F2 { get; set; }
	}

	/* the output column of the principal components */
	public class PcaOutput
	{
		[ColumnName("PCA")]
		public float[] Components { get; set; }
	}

	/* the cluster of a point and its distances to the centers */
	public class ClusterPrediction
	{
		[ColumnName("PredictedLabel")]
		public uint PredictedLabel { get; set; }
		[ColumnName("Score")]
		public float[] Distances { get; set; }
	}
}
