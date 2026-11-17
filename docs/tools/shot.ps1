# Starts a Ring program, captures its main window to a PNG and closes it.
#   powershell -File shot.ps1 -Dir <folder> -Script main.ring -Out out.png [-Delay 2500] [-Args "..."]
param(
	[string]$Dir,
	[string]$Script,
	[string]$Out,
	[int]$Delay = 2500,
	[string]$RingArgs = "",
	[string]$Ring = "B:\ring\bin\ring.exe",
	[string]$Bin = "B:\newpro\ringdotnet\bin"
)

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public static class ShotWin
{
	public delegate bool EnumProc(IntPtr h, IntPtr l);
	[DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
	[DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
	[DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
	[DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
	[DllImport("user32.dll")] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
	[DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
	[DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
	[DllImport("user32.dll")] public static extern uint GetDpiForSystem();
	[DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr h, int attr, out RECT r, int size);
	public static RECT Frame(IntPtr h) { RECT r; if (DwmGetWindowAttribute(h, 9, out r, 16) != 0) GetWindowRect(h, out r); return r; }
	[StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
	public static IntPtr Find(uint pid)
	{
		IntPtr best = IntPtr.Zero; long bestArea = 0;
		EnumWindows((h, l) =>
		{
			uint p; GetWindowThreadProcessId(h, out p);
			if (p != pid || !IsWindowVisible(h)) return true;
			StringBuilder cls = new StringBuilder(256); GetClassName(h, cls, 256);
			if (cls.ToString() == "ConsoleWindowClass" || cls.ToString().StartsWith("CASCADIA")) return true;
			RECT r; GetWindowRect(h, out r);
			long area = (long)(r.Right - r.Left) * (r.Bottom - r.Top);
			if (area > bestArea) { best = h; bestArea = area; }
			return true;
		}, IntPtr.Zero);
		return best;
	}
	public static RECT Rect(IntPtr h) { RECT r; GetWindowRect(h, out r); return r; }
}
"@

[ShotWin]::SetThreadDpiAwarenessContext([IntPtr](-4)) | Out-Null
$env:PATH = "$Bin;$env:PATH"
Remove-Item Env:RING_HOME -ErrorAction SilentlyContinue
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Ring
$psi.Arguments = ("`"$Script`" " + $RingArgs).Trim()
$psi.WorkingDirectory = $Dir
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$proc = [System.Diagnostics.Process]::Start($psi)
$h = [IntPtr]::Zero
$deadline = (Get-Date).AddSeconds(25)
while ($h -eq [IntPtr]::Zero -and (Get-Date) -lt $deadline -and -not $proc.HasExited)
{
	Start-Sleep -Milliseconds 300
	$h = [ShotWin]::Find([uint32]$proc.Id)
}
if ($h -eq [IntPtr]::Zero)
{
	Write-Output "NOWINDOW $Script"
	if (-not $proc.HasExited) { $proc.Kill() }
	exit 1
}
Start-Sleep -Milliseconds $Delay
$h = [ShotWin]::Find([uint32]$proc.Id)
$r = [ShotWin]::Rect($h)
$w = $r.Right - $r.Left
$ht = $r.Bottom - $r.Top
# the Ring process is DPI unaware: its window is drawn at the logical size and scaled by Windows
$scale = [ShotWin]::GetDpiForSystem() / 96.0
$w = [int][Math]::Ceiling($w / $scale)
$ht = [int][Math]::Ceiling($ht / $scale)
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$dc = $g.GetHdc()
$ok = [ShotWin]::PrintWindow($h, $dc, 2)
$g.ReleaseHdc($dc)
$g.Dispose()
New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null
$f = [ShotWin]::Frame($h)
$crop = New-Object System.Drawing.Rectangle ([int](($f.Left - $r.Left) / $scale)), ([int](($f.Top - $r.Top) / $scale)), ([int](($f.Right - $f.Left) / $scale)), ([int](($f.Bottom - $f.Top) / $scale))
if ($crop.Right -gt $w) { $crop.Width = $w - $crop.X }
if ($crop.Bottom -gt $ht) { $crop.Height = $ht - $crop.Y }
$cropped = $bmp.Clone($crop, $bmp.PixelFormat)
$cropped.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$cropped.Dispose()
$bmp.Dispose()
$w = $crop.Width
$ht = $crop.Height
if (-not $proc.HasExited) { $proc.Kill() }
Write-Output "OK $Out ${w}x${ht}"
