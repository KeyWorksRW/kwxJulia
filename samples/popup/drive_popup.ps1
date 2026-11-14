param([string]$FrameTitle, [int]$Repeat = 1, [string]$Mode = "simple")

Add-Type @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class W5 {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsWindowEnabled(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr w, StringBuilder l);
  [DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint msg, IntPtr w, IntPtr l);
}
"@

$script:out = New-Object 'System.Collections.Generic.List[string]'
function Say([string]$s) { $script:out.Add($s) }
function Flush() { [System.IO.File]::WriteAllText("C:\rwCode\wxLanguages\kwxJulia\samples\popup\drive_report.txt", ($script:out -join "`r`n")) }

function Txt([IntPtr]$h) {
  $sb = New-Object System.Text.StringBuilder 16384
  [void][W5]::SendMessageW($h, 0x000D, [IntPtr]16384, $sb)
  return $sb.ToString()
}
function Cls([IntPtr]$h) {
  $sb = New-Object System.Text.StringBuilder 256
  [void][W5]::GetClassNameW($h, $sb, 256)
  return $sb.ToString()
}
function KidList([IntPtr]$h) {
  $list = New-Object 'System.Collections.Generic.List[IntPtr]'
  $cb = [W5+EnumProc]{ param($k, $l) $list.Add($k); return $true }
  [void][W5]::EnumChildWindows($h, $cb, [IntPtr]::Zero)
  return ,$list
}
function FindText([IntPtr]$root, [string]$text) {
  foreach ($k in (KidList $root)) { if ((Txt $k) -eq $text) { return $k } }
  return [IntPtr]::Zero
}
function FindId([IntPtr]$root, [int]$id) {
  foreach ($k in (KidList $root)) { if ([W5]::GetDlgCtrlID($k) -eq $id) { return $k } }
  return [IntPtr]::Zero
}
function Dump([IntPtr]$root, [string]$tag) {
  $i = 0
  foreach ($k in (KidList $root)) {
    $t = (Txt $k) -replace "`r`n", "|"
    if ($t.Length -gt 200) { $t = $t.Substring(0,200) + "..." }
    Say ("  " + $tag + "[" + $i + "] hwnd=" + $k + " id=" + [W5]::GetDlgCtrlID($k) + " class=" + (Cls $k) + " text='" + $t + "'")
    $i = $i + 1
  }
}
function Tops([uint32]$p) {
  $script:wantPid = $p
  $list = New-Object 'System.Collections.Generic.List[IntPtr]'
  $cb = [W5+EnumProc]{
    param($h, $l)
    [uint32]$q = 0
    [void][W5]::GetWindowThreadProcessId($h, [ref]$q)
    if ($q -eq $script:wantPid -and [W5]::IsWindowVisible($h)) { $list.Add($h) }
    return $true
  }
  [void][W5]::EnumWindows($cb, [IntPtr]::Zero)
  return ,$list
}
function FindPopup([uint32]$p, [IntPtr]$exclude, [IntPtr]$exclude2) {
  foreach ($t in (Tops $p)) {
    if ($t -eq $exclude -or $t -eq $exclude2) { continue }
    if ((Cls $t) -eq "ConsoleWindowClass") { continue }
    if ((FindText $t "Press Me") -ne [IntPtr]::Zero) { return $t }
  }
  return [IntPtr]::Zero
}

$frame = [IntPtr]::Zero
$appPid = [uint32]0
$script:wantTitle = $FrameTitle
$cbF = [W5+EnumProc]{
  param($h, $l)
  if ([W5]::IsWindowVisible($h) -and (Txt $h) -eq $script:wantTitle) {
    $script:frame = $h
    [uint32]$q = 0
    [void][W5]::GetWindowThreadProcessId($h, [ref]$q)
    $script:appPid = $q
  }
  return $true
}
[void][W5]::EnumWindows($cbF, [IntPtr]::Zero)
if ($frame -eq [IntPtr]::Zero) { Say "FRAME NOT FOUND"; Flush; exit 1 }
Say "FRAME hwnd=$frame pid=$appPid"

$status = FindId $frame -31993
$log = FindId $frame -31991
$simple = FindId $frame 5016
$scrolled = FindId $frame 5017
Say ("IDS simple=" + $simple + " scrolled=" + $scrolled + " log=" + $log + " status=" + $status)
Say ("STATUS='" + (Txt $status) + "'")
Say ("LOG0='" + ((Txt $log) -replace "`r`n", "|") + "'")
Dump $frame "FRAME"

$button = if ($Mode -eq "scrolled") { $scrolled } else { $simple }

for ($i = 1; $i -le $Repeat; $i++) {
  [void][W5]::PostMessageW($button, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)
  Start-Sleep -Milliseconds 800
  $popup = FindPopup $appPid $frame ([IntPtr]::Zero)
  Say ("ITER" + $i + " popup=" + $popup + " frame-alive=" + [W5]::IsWindow($frame))
  if ($popup -ne [IntPtr]::Zero) {
    Dump $popup ("P" + $i)
    $press = FindText $popup "Press Me"
    Say ("ITER" + $i + " press-label='" + (Txt $press) + "'")
    if ($i -eq 1) {
      [void][W5]::PostMessageW($press, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)
      Start-Sleep -Milliseconds 400
      Say ("ITER" + $i + " press-after='" + (Txt $press) + "'")
    }
  }
  Say ("ITER" + $i + " log='" + ((Txt $log) -replace "`r`n", "|") + "'")
}

if ($Mode -eq "dialog") {
  [void][W5]::PostMessageW($frame, 0x0111, [IntPtr]5015, [IntPtr]::Zero)
  Start-Sleep -Milliseconds 900
  $dialog = [IntPtr]::Zero
  foreach ($t in (Tops $appPid)) {
    if ($t -eq $frame) { continue }
    if ((Cls $t) -eq "ConsoleWindowClass") { continue }
    if ((Txt $t) -eq "Test") { $dialog = $t }
  }
  Say ("DIALOG=" + $dialog + " frame-enabled=" + [W5]::IsWindowEnabled($frame))
  if ($dialog -ne [IntPtr]::Zero) {
    Dump $dialog "DLG"
    $db = FindId $dialog 5016
    [void][W5]::PostMessageW($db, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 800
    $dp = FindPopup $appPid $frame $dialog
    Say ("DIALOG-POPUP=" + $dp)
    if ($dp -ne [IntPtr]::Zero) { Dump $dp "DP" }
    $ok = FindId $dialog 5100
    [void][W5]::PostMessageW($ok, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 900
    Say ("DIALOG-AFTER-OK open=" + [W5]::IsWindow($dialog) + " frame-enabled=" + [W5]::IsWindowEnabled($frame))
  }
  Say ("LOG-DIALOG='" + ((Txt $log) -replace "`r`n", "|") + "'")
}

Flush
