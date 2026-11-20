using System;
using System.Runtime.InteropServices;
using System.Text;

namespace Tutorial.Native
{
    // Ring cannot declare a function of a native DLL, because the bridge calls members that .NET already knows.
    // C# can: [DllImport] says in which DLL the function is, and the public methods below give the functions to Ring.
    public static class Win32
    {
        [DllImport("kernel32.dll")]
        private static extern int MulDiv(int number, int numerator, int denominator);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern IntPtr CharUpperW(IntPtr text);

        [DllImport("user32.dll")]
        private static extern int GetSystemMetrics(int index);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern uint GetEnvironmentVariableW(string name, StringBuilder buffer, uint size);

        [StructLayout(LayoutKind.Sequential)]
        private struct MemoryStatus
        {
            public uint Length;
            public uint MemoryLoad;
            public ulong TotalPhysical;
            public ulong AvailablePhysical;
            public ulong TotalPageFile;
            public ulong AvailablePageFile;
            public ulong TotalVirtual;
            public ulong AvailableVirtual;
            public ulong AvailableExtendedVirtual;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool GlobalMemoryStatusEx(ref MemoryStatus status);

        // numbers in, a number out: (number * numerator) / denominator, rounded
        public static int Scale(int number, int numerator, int denominator)
        {
            return MulDiv(number, numerator, denominator);
        }

        // a text in, a text out: the function changes the text itself, so it gets a copy in native memory
        public static string UpperCase(string text)
        {
            IntPtr copy = Marshal.StringToHGlobalUni(text);
            try
            {
                CharUpperW(copy);
                return Marshal.PtrToStringUni(copy);
            }
            finally
            {
                Marshal.FreeHGlobal(copy);
            }
        }

        // 0 is the width of the screen in pixels, 1 is the height
        public static int ScreenSize(int which)
        {
            return GetSystemMetrics(which);
        }

        // a function that fills a buffer: the text of an environment variable, or "" when there is none
        public static string Variable(string name)
        {
            StringBuilder buffer = new StringBuilder(32768);
            uint length = GetEnvironmentVariableW(name, buffer, (uint)buffer.Capacity);
            return length == 0 ? "" : buffer.ToString();
        }

        // a function that fills a structure: the physical memory of the computer in megabytes
        public static long MemoryMegabytes()
        {
            MemoryStatus status = new MemoryStatus();
            status.Length = (uint)Marshal.SizeOf(typeof(MemoryStatus));
            if (!GlobalMemoryStatusEx(ref status))
                throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            return (long)(status.TotalPhysical / (1024 * 1024));
        }
    }
}
