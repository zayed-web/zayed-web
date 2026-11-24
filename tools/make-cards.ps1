<#
  Generates the profile's SVG cards (dark + light) from tools/cards.json.
  Usage (from repo root):  pwsh ./tools/make-cards.ps1
  Add a game: append an entry to "games" in cards.json, re-run, then add its <picture> block to README.md.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$data = Get-Content (Join-Path $PSScriptRoot 'cards.json') -Raw | ConvertFrom-Json
$out  = Join-Path $root 'assets'
New-Item -ItemType Directory -Force $out | Out-Null

$themes = @{
  dark  = @{ bg='#0F1117'; panel='#151A2B'; border='#2A3350'; title='#E6EBFF'; text='#C0CAF5'; muted='#565F89'
             chipBg='#1F2538'; chipText='#C0CAF5'; accent='#7AA2F7'; accent2='#BB9AF7'
             status=@{ 'In development'='#E0AF68'; 'On hold'='#8A93B8'; 'Released'='#9ECE6A'; 'Prototype'='#7DCFFF' } }
  light = @{ bg='#FFFFFF'; panel='#F6F7FB'; border='#DCE0EE'; title='#1A1D26'; text='#2E3448'; muted='#6B7394'
             chipBg='#E9ECF7'; chipText='#2E3448'; accent='#2F5FD0'; accent2='#7046D6'
             status=@{ 'In development'='#A86A0C'; 'On hold'='#5F6785'; 'Released'='#3F7F1E'; 'Prototype'='#1A7FA6' } }
}
$font = 'Segoe UI, Inter, Helvetica, Arial, sans-serif'
function Esc([string]$s) { [System.Security.SecurityElement]::Escape($s) }
function Wrap([string]$s, [int]$max) {
  $lines = @(); $cur = ''
  foreach ($w in $s -split ' ') {
    if (($cur.Length + $w.Length + 1) -gt $max -and $cur) { $lines += $cur; $cur = $w } else { $cur = ($cur + ' ' + $w).Trim() }
  }
  if ($cur) { $lines += $cur }; $lines
}
function ChipWidth([string]$s) { [int]([Math]::Ceiling($s.Length * 8.6) + 28) }
function Chips($chips, $x, $y, $t) {
  $sb = ''
  foreach ($c in $chips) {
    $w = ChipWidth $c
    $sb += "<rect x='$x' y='$y' width='$w' height='30' rx='15' fill='$($t.chipBg)' stroke='$($t.border)'/>"
    $sb += "<text x='$($x + $w/2)' y='$($y + 20)' text-anchor='middle' font-family='$font' font-size='15' font-weight='600' fill='$($t.chipText)'>$(Esc $c)</text>"
    $x += $w + 10
  }
  $sb
}

foreach ($name in $themes.Keys) {
  $t = $themes[$name]
  foreach ($g in $data.games) {
    $lines = @(Wrap $g.pitch 92)
    $h = 150 + 28 * $lines.Count
    $sc = $t.status[$g.status]; if (-not $sc) { $sc = $t.muted }
    $sw = ChipWidth $g.status
    $pitch = ''; $y = 104
    foreach ($l in $lines) { $pitch += "<text x='48' y='$y' font-family='$font' font-size='19' fill='$($t.text)'>$(Esc $l)</text>"; $y += 28 }
    $svg = @"
<svg xmlns='http://www.w3.org/2000/svg' width='1200' height='$h' viewBox='0 0 1200 $h' role='img' aria-labelledby='t d'>
<title id='t'>$(Esc $g.name) ($(Esc $g.status))</title><desc id='d'>$(Esc $g.pitch)</desc>
<defs><linearGradient id='a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='$($t.accent2)'/><stop offset='1' stop-color='$($t.accent)'/></linearGradient></defs>
<rect x='1' y='1' width='1198' height='$($h-2)' rx='14' fill='$($t.panel)' stroke='$($t.border)' stroke-width='2'/>
<rect x='1' y='1' width='8' height='$($h-2)' rx='4' fill='url(#a)'/>
<text x='48' y='62' font-family='$font' font-size='32' font-weight='800' fill='$($t.title)'>$(Esc $g.name)</text>
<rect x='$(1200 - 40 - $sw)' y='34' width='$sw' height='32' rx='16' fill='none' stroke='$sc' stroke-width='2'/>
<circle cx='$(1200 - 40 - $sw + 16)' cy='50' r='5' fill='$sc'/>
<text x='$(1200 - 40 - $sw/2 + 6)' y='56' text-anchor='middle' font-family='$font' font-size='15' font-weight='700' fill='$sc'>$(Esc $g.status)</text>
$pitch
$(Chips $g.chips 48 ($h - 56) $t)
</svg>
"@
    Set-Content -LiteralPath (Join-Path $out "card-$($g.id)-$name.svg") -Value $svg -Encoding utf8NoBOM
  }
  # tech stack row
  $total = ($data.stack | ForEach-Object { (ChipWidth $_) + 10 } | Measure-Object -Sum).Sum - 10
  $x0 = [int]((1200 - $total) / 2)
  $stack = "<svg xmlns='http://www.w3.org/2000/svg' width='1200' height='40' viewBox='0 0 1200 40' role='img' aria-label='Tech stack: $(Esc ($data.stack -join ', '))'><title>Tech stack: $(Esc ($data.stack -join ', '))</title>$(Chips $data.stack $x0 5 $t)</svg>"
  Set-Content -LiteralPath (Join-Path $out "stack-$name.svg") -Value $stack -Encoding utf8NoBOM
}
Get-ChildItem $out -Filter *.svg | ForEach-Object { [xml](Get-Content $_.FullName -Raw) | Out-Null; "ok  $($_.Name)" }
