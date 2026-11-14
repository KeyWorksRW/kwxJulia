param([int]$TargetPid)

Add-Type @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class Win {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr w, StringBuilder l);
  [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint msg, IntPtr w, IntPtr l);
}
"@

function Get-Text([IntPtr]$h) {
  $sb = New-Object System.Text.StringBuilder 4096
  [void][Win]::SendMessageW($h, 0x000D, [IntPtr]4096, $sb)
  return $sb.ToString()
}

function Get-Class([IntPtr]$h) {
  $sb = New-Object System.Text.StringBuilder 256
  [void][Win]::GetClassNameW($h, $sb, 256)
  return $sb.ToString()
}

$tops = New-Object System.Collections.ArrayList
$all = New-Object System.Collections.ArrayList
$cb = [Win+EnumProc]{
  param($h, $l)
  [uint32]$p = 0
  [void][Win]::GetWindowThreadProcessId($h, [ref]$p)
  [void]$all.Add(("{0}|{1}|{2}" -f $p, $h, (Get-Class $h)))
  if ($p -eq $TargetPid -and [Win]::IsWindowVisible($h)) { [void]$tops.Add($h) }
  return $true
}
[void][Win]::EnumWindows($cb, [IntPtr]::Zero)

Write-Output "TOPLEVEL count=$($tops.Count)"
Write-Output "ALLVISIBLE count=$($all.Count)"
$all | Select-Object -First 40 | ForEach-Object { Write-Output "  $($_) title='$(Get-Text ([IntPtr]($_ -split '\|')[1]))'" }
foreach ($t in $tops) {
  Write-Output ("TOP hwnd={0} class={1} title='{2}'" -f $t, (Get-Class $t), (Get-Text $t))
  $kids = New-Object System.Collections.ArrayList
  $cb2 = [Win+EnumProc]{
    param($h, $l)
    [void]$kids.Add($h)
    return $true
  }
  [void][Win]::EnumChildWindows($t, $cb2, [IntPtr]::Zero)
  foreach ($k in $kids) {
    $cls = Get-Class $k
    $id = [Win]::GetDlgCtrlID($k)
    $txt = Get-Text $k
    $txt = $txt -replace "`r`n", "|"
    if ($txt.Length -gt 120) { $txt = $txt.Substring(0,120) + "..." }
    Write-Output ("  CHILD hwnd={0} id={1} class={2} text='{3}'" -f $k, $id, $cls, $txt)
  }
}
