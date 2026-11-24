/* Windows Forms test helpers: posting keys to a control of this program. */

using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Linq.Expressions;
using System.Runtime.CompilerServices;
using System.Threading;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;

namespace RingDotNet
{
	public static unsafe partial class Bridge
	{
		/* ---------------------------------------------------------------- keyboard (for tests)
		   Keys are posted to the window of a control of THIS program (PostMessage), so they go through the normal
		   Windows Forms key processing (dialog keys, PreviewKeyDown, KeyDown, KeyPress) and can never reach another application. */

		[DllImport("user32.dll")] private static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

		[DllImport("user32.dll")] private static extern uint MapVirtualKey(uint code, uint mapType);

		private const uint WM_KEYDOWN = 0x0100, WM_KEYUP = 0x0101, WM_CHAR = 0x0102;

		private static int KeyCode(string name)
		{
			Type keys = ResolveType("System.Windows.Forms.Keys, System.Windows.Forms");
			return (int)Convert.ChangeType(Enum.Parse(keys, name, true), typeof(int)) & 0xFFFF;
		}

		private static void PostKey(IntPtr hwnd, int vk, bool extended)
		{
			uint scan = MapVirtualKey((uint)vk, 0);
			long down = 1 | ((long)scan << 16) | (extended ? 1L << 24 : 0);
			long up = down | (1L << 30) | (1L << 31);
			PostMessage(hwnd, WM_KEYDOWN, (IntPtr)vk, (IntPtr)down);
			PostMessage(hwnd, WM_KEYUP, (IntPtr)vk, (IntPtr)up);
		}

		/* A key sequence as tokens: "{LEFT}", "a", " ", "{+}". Each token is posted alone and the form processes it before the next one,
		   because the message loop makes the WM_CHAR message of a key (like for the real keyboard) after the keys that are already queued. */
		private static List<object> KeyTokens(string sequence)
		{
			List<object> tokens = new RingList();
			for (int i = 0; i < sequence.Length; i++)
			{
				if (sequence[i] == '{')
				{
					int close = sequence.IndexOf('}', i + 1);
					if (close < 0) close = Math.Min(i + 2, sequence.Length - 1);
					tokens.Add(sequence.Substring(i, close - i + 1));
					i = close;
				}
				else
				{
					tokens.Add(sequence[i].ToString());
				}
			}
			return tokens;
		}

		private static void PostKeyToken(object control, string token)
		{
			IntPtr hwnd = (IntPtr)control.GetType().GetProperty("Handle").GetValue(control);
			Dictionary<string, string> special = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
			{
				{ "LEFT", "Left" }, { "RIGHT", "Right" }, { "UP", "Up" }, { "DOWN", "Down" }, { "ENTER", "Return" }, { "ESC", "Escape" },
				{ "BACKSPACE", "Back" }, { "BS", "Back" }, { "TAB", "Tab" }, { "DELETE", "Delete" }, { "HOME", "Home" }, { "END", "End" },
				{ "PGUP", "PageUp" }, { "PGDN", "PageDown" }, { "SPACE", "Space" }
			};
			HashSet<string> extended = new HashSet<string> { "Left", "Right", "Up", "Down", "Delete", "Home", "End", "PageUp", "PageDown" };
			if (token.Length > 3 && token[0] == '{' || (token.Length == 3 && token[0] == '{' && char.IsLetterOrDigit(token[1])))
			{
				string name = token.Substring(1, token.Length - 2);
				string key = special.TryGetValue(name, out string mapped) ? mapped : name;
				PostKey(hwnd, KeyCode(key), extended.Contains(key));
			}
			else
			{
				char c = token.Length == 3 && token[0] == '{' ? token[1] : token[0];
				if (c == ' ')
				{
					PostKey(hwnd, KeyCode("Space"), false);
				}
				else if (char.IsLetterOrDigit(c) && c < 128)
				{
					int vk = char.ToUpperInvariant(c);
					PostMessage(hwnd, WM_KEYDOWN, (IntPtr)vk, (IntPtr)1);
					PostMessage(hwnd, WM_KEYUP, (IntPtr)vk, (IntPtr)(1L | (1L << 30) | (1L << 31)));
				}
				else
				{
					PostMessage(hwnd, WM_CHAR, (IntPtr)c, (IntPtr)1);
				}
			}
		}
	}
}
