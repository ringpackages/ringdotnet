/* Helpers for drawing many pixels at once. The bridge does not reference System.Drawing (it is not on every system), so the Bitmap, the Color and the other types are found by
   name. A bitmap of 32 bits for each pixel (the usual one) is written with one copy of the memory of the picture (LockBits); any other bitmap is written pixel by pixel
   with a call of SetPixel that is compiled once into a delegate. Either way the picture is one call from Ring. */

using System;
using System.Collections.Concurrent;
using System.Linq.Expressions;
using System.Reflection;
using System.Runtime.InteropServices;

namespace RingDotNet
{
	public static class DrawingHelpers
	{
		private const int Format32bppArgb = 0x26200A;
		private const int ImageLockModeWriteOnly = 2;

		private static readonly ConcurrentDictionary<Type, Action<object, int, int, int, int, int>> Writers = new ConcurrentDictionary<Type, Action<object, int, int, int, int, int>>();
		private static readonly ConcurrentDictionary<Type, Bulk> Bulks = new ConcurrentDictionary<Type, Bulk>();

		/* what a bulk write needs from System.Drawing, found once for the type of the bitmap */
		private sealed class Bulk
		{
			public PropertyInfo PixelFormat;
			public ConstructorInfo Rectangle;
			public MethodInfo LockBits;
			public MethodInfo UnlockBits;
			public PropertyInfo Scan0;
			public PropertyInfo Stride;
			public Type LockMode;
			public Type PixelFormatType;
		}

		private static Type ResolveColor(Type bitmapType)
		{
			Type color = bitmapType.Assembly.GetType("System.Drawing.Color") ?? Type.GetType("System.Drawing.Color, System.Drawing.Primitives");
			if (color == null) throw new TypeLoadException("System.Drawing.Color was not found");
			return color;
		}

		/* a delegate that does bitmap.SetPixel(x, y, Color.FromArgb(r, g, b)) for the type of the bitmap */
		private static Action<object, int, int, int, int, int> WriterFor(Type bitmapType)
		{
			return Writers.GetOrAdd(bitmapType, type =>
			{
				Type colorType = ResolveColor(type);
				MethodInfo fromArgb = colorType.GetMethod("FromArgb", new[] { typeof(int), typeof(int), typeof(int) });
				MethodInfo setPixel = type.GetMethod("SetPixel", new[] { typeof(int), typeof(int), colorType });
				if (fromArgb == null || setPixel == null) throw new MissingMethodException("The type " + type.FullName + " has no SetPixel(int, int, Color)");
				ParameterExpression bitmap = Expression.Parameter(typeof(object), "bitmap");
				ParameterExpression x = Expression.Parameter(typeof(int), "x");
				ParameterExpression y = Expression.Parameter(typeof(int), "y");
				ParameterExpression r = Expression.Parameter(typeof(int), "r");
				ParameterExpression g = Expression.Parameter(typeof(int), "g");
				ParameterExpression b = Expression.Parameter(typeof(int), "b");
				Expression call = Expression.Call(Expression.Convert(bitmap, type), setPixel, x, y, Expression.Call(fromArgb, r, g, b));
				return Expression.Lambda<Action<object, int, int, int, int, int>>(call, bitmap, x, y, r, g, b).Compile();
			});
		}

		/* the types and members of a bulk write, or null when this system does not have them (the pixels are then written one by one) */
		private static Bulk BulkFor(Type bitmapType)
		{
			return Bulks.GetOrAdd(bitmapType, type =>
			{
				try
				{
					Assembly drawing = type.Assembly;
					Type rectangle = Type.GetType("System.Drawing.Rectangle, System.Drawing.Primitives") ?? drawing.GetType("System.Drawing.Rectangle");
					Type lockMode = drawing.GetType("System.Drawing.Imaging.ImageLockMode");
					Type pixelFormat = drawing.GetType("System.Drawing.Imaging.PixelFormat");
					Type data = drawing.GetType("System.Drawing.Imaging.BitmapData");
					if (rectangle == null || lockMode == null || pixelFormat == null || data == null) return null;
					Bulk bulk = new Bulk
					{
						PixelFormat = type.GetProperty("PixelFormat"),
						Rectangle = rectangle.GetConstructor(new[] { typeof(int), typeof(int), typeof(int), typeof(int) }),
						LockBits = type.GetMethod("LockBits", new[] { rectangle, lockMode, pixelFormat }),
						UnlockBits = type.GetMethod("UnlockBits", new[] { data }),
						Scan0 = data.GetProperty("Scan0"),
						Stride = data.GetProperty("Stride"),
						LockMode = lockMode,
						PixelFormatType = pixelFormat
					};
					return bulk.PixelFormat != null && bulk.Rectangle != null && bulk.LockBits != null && bulk.UnlockBits != null && bulk.Scan0 != null && bulk.Stride != null ? bulk : null;
				}
				catch (Exception)
				{
					return null;
				}
			});
		}

		/* Sets a rectangle of the bitmap from one text of 3 bytes for each pixel (red, green, blue), row after row: the pixel x, y first, then the pixel x + 1, y ...
		   The rectangle must be inside of the bitmap. */
		public static void SetPixels(object bitmap, int x, int y, int width, int height, byte[] rgb)
		{
			if (bitmap == null) throw new ArgumentNullException("bitmap");
			if (width < 0 || height < 0) throw new ArgumentException("The width and the height must not be negative");
			if ((long)width * height * 3 != rgb.Length) throw new ArgumentException("The text must have 3 bytes for each pixel of the rectangle (" + width + " x " + height + " pixels need " + (long)width * height * 3 + " bytes, the text has " + rgb.Length + ")");
			Type type = bitmap.GetType();
			Bulk bulk = BulkFor(type);
			if (bulk != null && width > 0 && height > 0 && Convert.ToInt32(bulk.PixelFormat.GetValue(bitmap)) == Format32bppArgb)
			{
				WriteBulk(bulk, bitmap, x, y, width, height, rgb);
				return;
			}
			Action<object, int, int, int, int, int> write = WriterFor(type);
			int at = 0;
			for (int row = 0; row < height; row++)
			{
				for (int column = 0; column < width; column++)
				{
					write(bitmap, x + column, y + row, rgb[at], rgb[at + 1], rgb[at + 2]);
					at += 3;
				}
			}
		}

		/* the whole rectangle is locked, filled in the byte order of the picture (blue, green, red, alpha) and unlocked */
		private static void WriteBulk(Bulk bulk, object bitmap, int x, int y, int width, int height, byte[] rgb)
		{
			object rectangle = bulk.Rectangle.Invoke(new object[] { x, y, width, height });
			object data = bulk.LockBits.Invoke(bitmap, new object[] { rectangle, Enum.ToObject(bulk.LockMode, ImageLockModeWriteOnly), Enum.ToObject(bulk.PixelFormatType, Format32bppArgb) });
			try
			{
				IntPtr scan0 = (IntPtr)bulk.Scan0.GetValue(data);
				int stride = (int)bulk.Stride.GetValue(data);
				byte[] row = new byte[width * 4];
				int at = 0;
				for (int line = 0; line < height; line++)
				{
					for (int i = 0; i < row.Length; i += 4)
					{
						row[i] = rgb[at + 2];
						row[i + 1] = rgb[at + 1];
						row[i + 2] = rgb[at];
						row[i + 3] = 255;
						at += 3;
					}
					Marshal.Copy(row, 0, IntPtr.Add(scan0, line * stride), row.Length);
				}
			}
			finally
			{
				bulk.UnlockBits.Invoke(bitmap, new object[] { data });
			}
		}
	}
}
