param(
  [Parameter(Mandatory=$true)][string]$InputPath,
  [Parameter(Mandatory=$true)][string]$OutputPath,
  [int]$Colors = 0,
  [int]$MaxRuns = 250000
)

$ErrorActionPreference = 'Stop'
$inv = [System.Globalization.CultureInfo]::InvariantCulture

function Fail([string]$msg) {
  if (Test-Path -LiteralPath $OutputPath) { Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue }
  Write-Output ("FAILURE: " + $msg)
  exit 1
}

# ---------- read source ----------
$rawLines = Get-Content -LiteralPath $InputPath -Encoding UTF8
if ($null -eq $rawLines -or $rawLines.Count -lt 2) { Fail ("malformed XPM " + $InputPath + " - file too short") }

$quoted = New-Object System.Collections.Generic.List[string]
foreach ($ln in $rawLines) {
  $t = $ln.Trim()
  if ($t.StartsWith('"')) {
    $i = $t.IndexOf('"')
    $j = $t.LastIndexOf('"')
    if ($j -le $i) { Fail ("malformed XPM " + $InputPath + " - unbalanced quote") }
    $quoted.Add($t.Substring($i + 1, $j - $i - 1))
  }
}
if ($quoted.Count -lt 2) { Fail ("malformed XPM " + $InputPath + " - no quoted data lines") }

$hdr = @($quoted[0].Trim() -split '\s+')
if ($hdr.Count -lt 4) { Fail ("malformed XPM " + $InputPath + " - bad header line") }
$W       = [int]$hdr[0]
$H       = [int]$hdr[1]
$nColors = [int]$hdr[2]
$cpp     = [int]$hdr[3]
if ($W -le 0 -or $H -le 0 -or $cpp -le 0) { Fail ("malformed XPM " + $InputPath + " - non-positive dimensions") }
if ($quoted.Count -lt (1 + $nColors + $H)) { Fail ("malformed XPM " + $InputPath + " - declared pixel lines != height") }

# ---------- named X11 colours ----------
$named = @{
  'black'='#000000'; 'white'='#FFFFFF'; 'red'='#FF0000'; 'green'='#00FF00'; 'blue'='#0000FF'
  'yellow'='#FFFF00'; 'cyan'='#00FFFF'; 'magenta'='#FF00FF'; 'gray'='#BEBEBE'; 'grey'='#BEBEBE'
  'darkgray'='#A9A9A9'; 'darkgrey'='#A9A9A9'; 'lightgray'='#D3D3D3'; 'lightgrey'='#D3D3D3'
}

function Convert-Colour([string]$val, [int]$lineNo, [string]$path) {
  if ($null -eq $val -or $val -eq '') { Fail ("malformed XPM " + $path + " - missing colour value at line " + $lineNo) }
  if ($val -eq 'None' -or $val -eq 'none' -or $val -eq 'NONE') { return $null }
  if ($val.StartsWith('#')) {
    $hex = $val.Substring(1)
    if ($hex.Length -eq 3) {
      $r = [Convert]::ToInt32($hex.Substring(0,1) + $hex.Substring(0,1), 16)
      $g = [Convert]::ToInt32($hex.Substring(1,1) + $hex.Substring(1,1), 16)
      $b = [Convert]::ToInt32($hex.Substring(2,1) + $hex.Substring(2,1), 16)
      return ('#{0:X2}{1:X2}{2:X2}' -f $r, $g, $b)
    }
    elseif ($hex.Length -eq 6) {
      return ('#' + $hex.ToUpperInvariant())
    }
    elseif ($hex.Length -eq 12) {
      $r = [Convert]::ToInt32($hex.Substring(0,4), 16) -shl 0
      $g = [Convert]::ToInt32($hex.Substring(4,4), 16)
      $b = [Convert]::ToInt32($hex.Substring(8,4), 16)
      $r = [int][math]::Round($r * 255.0 / 65535.0)
      $g = [int][math]::Round($g * 255.0 / 65535.0)
      $b = [int][math]::Round($b * 255.0 / 65535.0)
      return ('#{0:X2}{1:X2}{2:X2}' -f $r, $g, $b)
    }
    else {
      Fail ("malformed XPM " + $path + " - unsupported hex colour length at line " + $lineNo)
    }
  }
  $low = $val.ToLowerInvariant()
  if ($named.ContainsKey($low)) { return $named[$low] }
  Fail ('unresolved XPM colour "' + $val + '" at line ' + $lineNo + ' - supply an RGB value')
}

# ---------- palette ----------
$palette = @{}
for ($k = 0; $k -lt $nColors; $k++) {
  $line = $quoted[1 + $k]
  if ($line.Length -lt $cpp) { Fail ("malformed XPM " + $InputPath + " - colour line shorter than cpp") }
  $key  = $line.Substring(0, $cpp)
  $rest = $line.Substring($cpp)
  $toks = @($rest -split '\s+' | Where-Object { $_ -ne '' })
  $val = $null
  $found = $false
  for ($t = 0; $t -lt ($toks.Count - 1); $t++) {
    if ($toks[$t] -eq 'c') { $val = $toks[$t + 1]; $found = $true; break }
  }
  if (-not $found) { Fail ("malformed XPM " + $InputPath + " - colour line without 'c' key: " + $line) }
  $palette[$key] = Convert-Colour $val (2 + $k) $InputPath
}

# ---------- pixel grid ----------
$grid = New-Object 'object[]' $H
for ($y = 0; $y -lt $H; $y++) {
  $pline = $quoted[1 + $nColors + $y]
  $need = $W * $cpp
  if ($pline.Length -lt $need) { Fail ("malformed XPM " + $InputPath + " - pixel line " + ($y + 1) + " shorter than width") }
  $row = New-Object 'object[]' $W
  for ($x = 0; $x -lt $W; $x++) {
    $pk = $pline.Substring($x * $cpp, $cpp)
    if (-not $palette.ContainsKey($pk)) {
      Fail ("malformed XPM " + $InputPath + " - pixel char outside palette at row " + ($y + 1) + " col " + ($x + 1))
    }
    $row[$x] = $palette[$pk]
  }
  $grid[$y] = $row
}

# ---------- horizontal runs ----------
$runs = 0
for ($y = 0; $y -lt $H; $y++) {
  $x = 0
  while ($x -lt $W) {
    $c = $grid[$y][$x]
    $s = $x
    while ($x -lt $W -and (($null -eq $grid[$y][$x] -and $null -eq $c) -or ($null -ne $c -and $null -ne $grid[$y][$x] -and $grid[$y][$x] -eq $c))) { $x++ }
    if ($null -ne $c) { $runs++ }
  }
}

if ($Colors -le 0 -and $runs -gt $MaxRuns) {
  Fail ("" + $runs + " runs exceed MAX_RUNS (" + $MaxRuns + ") - rerun with MODE: quantize COLORS: 64")
}

# ---------- vertical merge ----------
$rects = New-Object System.Collections.Generic.List[object]
$open  = @{}
for ($y = 0; $y -lt $H; $y++) {
  $newOpen = @{}
  $x = 0
  while ($x -lt $W) {
    $c = $grid[$y][$x]
    if ($null -eq $c) { $x++; continue }
    $s = $x
    while ($x -lt $W -and $grid[$y][$x] -eq $c -and $null -ne $grid[$y][$x]) { $x++ }
    $len = $x - $s
    $key = ('' + $s + '|' + $len + '|' + $c)
    if ($open.ContainsKey($key)) {
      $idx = $open[$key]
      $rects[$idx].h = $rects[$idx].h + 1
      $newOpen[$key] = $idx
    }
    else {
      $rects.Add([pscustomobject]@{ x = $s; y = $y; w = $len; h = 1; c = $c })
      $newOpen[$key] = $rects.Count - 1
    }
  }
  $open = $newOpen
}

# ---------- assert bounds ----------
foreach ($r in $rects) {
  if (($r.x + $r.w) -gt $W -or ($r.y + $r.h) -gt $H -or $r.x -lt 0 -or $r.y -lt 0) {
    Fail ("internal bounds violation at " + $r.x + "," + $r.y)
  }
}

# ---------- emit SVG ----------
$sb = New-Object System.Text.StringBuilder
$src = [System.IO.Path]::GetFileName($InputPath)
[void]$sb.AppendLine('<svg xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="full" width="' + $W + '" height="' + $H + '" viewBox="0 0 ' + $W + ' ' + $H + '" shape-rendering="crispEdges">')
[void]$sb.AppendLine('<!-- source: ' + $src + ' -->')
foreach ($r in $rects) {
  [void]$sb.AppendLine('<rect x="' + $r.x + '" y="' + $r.y + '" width="' + $r.w + '" height="' + $r.h + '" fill="' + $r.c + '"/>')
}
[void]$sb.AppendLine('</svg>')

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutputPath, $sb.ToString(), $utf8)

$coloursUsed = @($rects | ForEach-Object { $_.c } | Sort-Object -Unique).Count
Write-Output ("runs: " + $runs)
Write-Output ("rects: " + $rects.Count)
Write-Output ("colors: " + $coloursUsed)
Write-Output ("dims: " + $W + "x" + $H)
