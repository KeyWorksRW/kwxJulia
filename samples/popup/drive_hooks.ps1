param([int]$AppPid)

Add-Type @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class W7 {
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
function Flush() { [System.IO.File]::WriteAllText("C:\rwCode\wxLanguages\kwxJulia\samples\popup\drive_hooks_report.txt", ($script:out -join "`r`n")) }

function Txt([IntPtr]$h) {
  $sb = New-Object System.Text.StringBuilder 65536
  [void][W7]::SendMessageW($h, 0x000D, [IntPtr]65536, $sb)
  return $sb.ToString()
}
function Cls([IntPtr]$h) {
  $sb = New-Object System.Text.StringBuilder 256
  [void][W7]::GetClassNameW($h, $sb, 256)
  return $sb.ToString()
}
function Kids([IntPtr]$h) {
  $list = New-Object 'System.Collections.Generic.List[IntPtr]'
  $cb = [W7+EnumProc]{ param($k, $l) $list.Add($k); return $true }
  [void][W7]::EnumChildWindows($h, $cb, [IntPtr]::Zero)
  return ,$list
}
function FindId([IntPtr]$root, [int]$id) {
  foreach ($k in (Kids $root)) { if ([W7]::GetDlgCtrlID($k) -eq $id) { return $k } }
  return [IntPtr]::Zero
}
function FindText([IntPtr]$root, [string]$text) {
  foreach ($k in (Kids $root)) { if ((Txt $k) -eq $text) { return $k } }
  return [IntPtr]::Zero
}
function Tops() {
  $list = New-Object 'System.Collections.Generic.List[IntPtr]'
  $cb = [W7+EnumProc]{
    param($h, $l)
    [uint32]$q = 0
    [void][W7]::GetWindowThreadProcessId($h, [ref]$q)
    if ($q -eq $script:AppPid -and [W7]::IsWindowVisible($h)) { $list.Add($h) }
    return $true
  }
  [void][W7]::EnumWindows($cb, [IntPtr]::Zero)
  return ,$list
}
function FindTop([string]$title) {
  foreach ($t in (Tops)) { if ((Txt $t) -eq $title) { return $t } }
  return [IntPtr]::Zero
}
function WaitPopup([IntPtr]$a, [IntPtr]$b, [int]$ms) {
  $deadline = [DateTime]::UtcNow.AddMilliseconds($ms)
  while ([DateTime]::UtcNow -lt $deadline) {
    foreach ($t in (Tops)) {
      if ($t -eq $a -or $t -eq $b) { continue }
      if ((FindText $t "Press Me") -ne [IntPtr]::Zero) { return $t }
    }
    Start-Sleep -Milliseconds 50
  }
  return [IntPtr]::Zero
}
function LogTail([IntPtr]$log, [int]$n) {
  $text = Txt $log
  $lines = $text -split "`r`n"
  $take = $lines | Select-Object -Last $n
  return ($take -join "|")
}

$script:AppPid = $AppPid

$frame = FindTop "Popup wxWidgets App"
if ($frame -eq [IntPtr]::Zero) { Say "FRAME NOT FOUND"; Flush; exit 1 }
Say ("FRAME hwnd=$frame pid=$AppPid")
$status = FindId $frame -31993
$log = FindId $frame -31991
Say ("IDS simple=" + (FindId $frame 5016) + " scrolled=" + (FindId $frame 5017) + " log=$log status=$status")
Say ("STATUS='" + (Txt $status) + "'")

# 1. simple popup: Popup() and Show(true) hooks must log.
[void][W7]::PostMessageW($frame, 0x0111, [IntPtr]5016, [IntPtr]::Zero)
Start-Sleep -Milliseconds 50
$p1 = WaitPopup $frame ([IntPtr]::Zero) 5000
Say ("P1 hwnd=$p1")
Say ("P1 LOG='" + (LogTail $log 8) + "'")

# 2. scrolled popup over it: old popup Dismiss -> Show(false); new -> Popup/Show(true).
[void][W7]::PostMessageW($frame, 0x0111, [IntPtr]5017, [IntPtr]::Zero)
Start-Sleep -Milliseconds 50
$p2 = WaitPopup $frame ([IntPtr]::Zero) 5000
Say ("P2 hwnd=$p2")
Say ("P2 LOG='" + (LogTail $log 12) + "'")

if ($p2 -ne [IntPtr]::Zero) {
  $press = FindText $p2 "Press Me"
  [void][W7]::PostMessageW($press, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)
  Start-Sleep -Milliseconds 50
  Say ("P2 press-label-now='" + (Txt $press) + "' pressed-found='" + (FindText $p2 "Pressed") + "'")
  Say ("P2 press LOG='" + (LogTail $log 6) + "'")

  # left-down inside the popup: exercises ProcessLeftDown hook.
  $lp = [IntPtr](3 -bor (3 -shl 16))
  [void][W7]::PostMessageW($p2, 0x0201, [IntPtr]1, $lp)
  Start-Sleep -Milliseconds 50
  [void][W7]::PostMessageW($p2, 0x0202, [IntPtr]0, $lp)
  Start-Sleep -Milliseconds 150
  Say ("P2 post-click LOG='" + (LogTail $log 6) + "'")
}

# 3. modal test dialog with its own popup.
[void][W7]::PostMessageW($frame, 0x0111, [IntPtr]5015, [IntPtr]::Zero)
Start-Sleep -Milliseconds 50
$dlg = [IntPtr]::Zero
$deadline = [DateTime]::UtcNow.AddMilliseconds(5000)
while ([DateTime]::UtcNow -lt $deadline -and $dlg -eq [IntPtr]::Zero) {
  $dlg = FindTop "Test"
  if ($dlg -eq [IntPtr]::Zero) { Start-Sleep -Milliseconds 50 }
}
Say ("DIALOG hwnd=$dlg frame-enabled=" + [W7]::IsWindowEnabled($frame))
if ($dlg -ne [IntPtr]::Zero) {
  [void][W7]::PostMessageW($dlg, 0x0111, [IntPtr]5016, [IntPtr]::Zero)
  Start-Sleep -Milliseconds 50
  $dp = WaitPopup $frame $dlg 5000
  Say ("DIALOG-POPUP hwnd=$dp")
  Say ("DIALOG LOG='" + (LogTail $log 8) + "'")
  $ok = FindId $dlg 5100
  Say ("DIALOG OK hwnd=$ok")
  [void][W7]::PostMessageW($ok, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)
  $deadline = [DateTime]::UtcNow.AddMilliseconds(5000)
  while ([DateTime]::UtcNow -lt $deadline -and [W7]::IsWindow($dlg)) { Start-Sleep -Milliseconds 50 }
  Say ("DIALOG-AFTER-OK open=" + [W7]::IsWindow($dlg) + " frame-enabled=" + [W7]::IsWindowEnabled($frame))
}

# 4. clean close.
[void][W7]::PostMessageW($frame, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
$deadline = [DateTime]::UtcNow.AddMilliseconds(5000)
while ([DateTime]::UtcNow -lt $deadline -and [W7]::IsWindow($frame)) { Start-Sleep -Milliseconds 50 }
Say ("CLOSE frame-alive=" + [W7]::IsWindow($frame))
Flush
