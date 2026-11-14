$ErrorActionPreference = 'Stop'

$InputDir = 'C:/rwCode/wxSamples/src/widgets/icons'
$OutDir   = 'C:/rwCode/wxLanguages/kwxJulia/samples/widgets'

$named = @{
  'black'='#000000'; 'white'='#FFFFFF'; 'red'='#FF0000'; 'green'='#00FF00';
  'blue'='#0000FF'; 'yellow'='#FFFF00'; 'cyan'='#00FFFF'; 'magenta'='#FF00FF';
  'gray'='#BEBEBE'; 'grey'='#BEBEBE'
}

function Comp([string]$s) {
  $v = [Convert]::ToInt32($s, 16)
  return [int][math]::Round($v * 255.0 / ([math]::Pow(16, $s.Length) - 1))
}

function Col([string]$v) {
  $v = $v.Trim()
  if ($v -ieq 'none') { return 'TRANSPARENT' }
  if ($v[0] -eq '#') {
    $h = $v.Substring(1); $n = [int]($h.Length / 3)
    return ('#{0:X2}{1:X2}{2:X2}' -f (Comp $h.Substring(0,$n)), (Comp $h.Substring($n,$n)), (Comp $h.Substring(2*$n,$n)))
  }
  $l = $v.ToLower()
  if ($l -match '^gr[ae]y(\d{1,3})$') {
    $c = [int][math]::Round([int]$Matches[1] * 255.0 / 100.0)
    return ('#{0:X2}{1:X2}{2:X2}' -f $c,$c,$c)
  }
  if ($named.ContainsKey($l)) { return $named[$l] }
  throw ('verify: unknown colour ' + $v)
}

$bad = 0
$files = @(Get-ChildItem -LiteralPath $InputDir -Filter *.xpm -File | Sort-Object Name)

foreach ($f in $files) {
  $name = $f.BaseName
  $svgPath = Join-Path $OutDir ($name + '.svg')
  $problems = New-Object System.Collections.Generic.List[string]

  # ---- independent re-read of the XPM into a colour grid ----
  $q = New-Object System.Collections.Generic.List[string]
  foreach ($ln in [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)) {
    foreach ($m in [regex]::Matches($ln, '"([^"]*)"')) { $q.Add($m.Groups[1].Value) }
  }
  if ($q[0] -notmatch '^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$') { throw ('verify: bad header ' + $name) }
  $W = [int]$Matches[1]; $H = [int]$Matches[2]; $NC = [int]$Matches[3]; $CPP = [int]$Matches[4]

  $pal = @{}
  for ($i = 1; $i -le $NC; $i++) {
    $s = $q[$i]
    $k = $s.Substring(0, $CPP)
    $t = @([regex]::Split($s.Substring($CPP).Trim(), '\s+') | Where-Object { $_ -ne '' })
    for ($j = 0; $j + 1 -lt $t.Count; $j += 2) { if ($t[$j] -eq 'c') { $pal[$k] = Col $t[$j + 1]; break } }
  }

  $expect = New-Object 'string[,]' $W, $H
  $nonTransparent = 0
  for ($y = 0; $y -lt $H; $y++) {
    $pl = $q[1 + $NC + $y]
    for ($x = 0; $x -lt $W; $x++) {
      $c = $pal[$pl.Substring($x * $CPP, $CPP)]
      $expect[$x, $y] = $c
      if ($c -ne 'TRANSPARENT') { $nonTransparent++ }
    }
  }

  # ---- XML / root checks ----
  $raw = [System.IO.File]::ReadAllText($svgPath)
  $doc = $null
  try { $doc = [xml]$raw } catch { $problems.Add('xml parse failed') }
  if ($doc -ne $null) {
    $root = $doc.DocumentElement
    if ($root.Name -ne 'svg') { $problems.Add('root is not svg') }
    if ($root.GetAttribute('version') -ne '1.2') { $problems.Add('version != 1.2') }
    if ($root.GetAttribute('baseProfile') -ne 'full') { $problems.Add('baseProfile != full') }
    if ($root.GetAttribute('width') -ne "$W") { $problems.Add("width $($root.GetAttribute('width')) != $W") }
    if ($root.GetAttribute('height') -ne "$H") { $problems.Add("height $($root.GetAttribute('height')) != $H") }
    if ($root.GetAttribute('viewBox') -ne "0 0 $W $H") { $problems.Add('viewBox mismatch') }
    if ($root.GetAttribute('shape-rendering') -ne 'crispEdges') { $problems.Add('shape-rendering missing') }
  }
  foreach ($pat in @('<image', 'base64', 'transform=', '<filter', 'filter=', '<style', 'gradient', '<animate')) {
    if ($raw.Contains($pat)) { $problems.Add('forbidden construct ' + $pat) }
  }

  # ---- rasterise rects back to a grid, detect overlap/out-of-bounds ----
  $grid = New-Object 'string[,]' $W, $H
  $rects = 0; $area = 0
  $ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
  $ns.AddNamespace('s', 'http://www.w3.org/2000/svg')
  foreach ($node in $doc.SelectNodes('/s:svg/*', $ns)) {
    if ($node.Name -ne 'rect') { $problems.Add('unexpected element ' + $node.Name); continue }
    $rects++
    $rx = [int]$node.GetAttribute('x'); $ry = [int]$node.GetAttribute('y')
    $rw = [int]$node.GetAttribute('width'); $rh = [int]$node.GetAttribute('height')
    $rc = $node.GetAttribute('fill')
    if (($rx + $rw) -gt $W -or ($ry + $rh) -gt $H -or $rw -lt 1 -or $rh -lt 1) { $problems.Add('rect out of bounds') }
    if ($node.HasAttribute('fill-opacity')) { $problems.Add('unexpected fill-opacity') }
    $area += $rw * $rh
    for ($yy = $ry; $yy -lt ($ry + $rh); $yy++) {
      for ($xx = $rx; $xx -lt ($rx + $rw); $xx++) {
        if ($yy -ge $H -or $xx -ge $W) { continue }
        if ($grid[$xx, $yy] -ne $null) { $problems.Add('overlapping rects at ' + $xx + ',' + $yy) }
        $grid[$xx, $yy] = $rc
      }
    }
  }

  $mismatch = 0; $missing = 0; $extra = 0
  for ($y = 0; $y -lt $H; $y++) {
    for ($x = 0; $x -lt $W; $x++) {
      $e = $expect[$x, $y]
      $a = $grid[$x, $y]
      if ($e -eq 'TRANSPARENT') { if ($a -ne $null) { $mismatch++; $extra++ } }
      else { if ($a -ne $e) { $mismatch++; $missing++ } }
    }
  }
  if ($mismatch -ne 0) { $problems.Add("pixel mismatches=$mismatch (missing=$missing extra=$extra)") }
  if ($area -ne $nonTransparent) { $problems.Add("area $area != nontransparent $nonTransparent") }
  if ($null -eq $grid[0,0] -and $null -eq $expect[0,0]) { } # no-op

  $bytes = (Get-Item -LiteralPath $svgPath).Length
  $b0 = [System.IO.File]::ReadAllBytes($svgPath)
  $bom = ($b0.Length -ge 3 -and $b0[0] -eq 0xEF -and $b0[1] -eq 0xBB -and $b0[2] -eq 0xBF)
  if ($bom) { $problems.Add('BOM present') }

  $status = if ($problems.Count -eq 0) { 'OK' } else { $bad++; 'BAD:' + ($problems -join '; ') }
  Write-Output ('CHECK|{0}|{1}|{2}|rects={3}|pixels={4}|nontransparent={5}|bytes={6}|{7}' -f $name, $W, $H, $rects, ($W * $H), $nonTransparent, $bytes, $status)
}

Write-Output ('VERIFY_DONE|files={0}|bad={1}' -f $files.Count, $bad)
if ($bad -gt 0) { exit 1 }
