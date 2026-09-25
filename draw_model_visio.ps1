$ErrorActionPreference = 'Stop'

$project = Split-Path -Parent $MyInvocation.MyCommand.Path
$figureDir = Join-Path $project 'figures'
$visioPath = Join-Path $figureDir 'p1_model_structure_3d_editable.vsdx'
$previewPath = Join-Path $figureDir 'p1_model_structure_3d_editable.png'
$pdfPath = Join-Path $figureDir 'p1_model_structure_3d_editable.pdf'

function Set-Cell($shape, [string]$name, [string]$formula) {
    $shape.CellsU($name).FormulaU = $formula
}

function Add-Rect($page, [double]$x1, [double]$y1, [double]$x2, [double]$y2,
                  [string]$fill, [string]$stroke = 'RGB(70,75,82)',
                  [string]$weight = '0.014 in', [string]$name = '') {
    $shape = $page.DrawRectangle($x1, $y1, $x2, $y2)
    Set-Cell $shape 'FillForegnd' $fill
    Set-Cell $shape 'LineColor' $stroke
    Set-Cell $shape 'LineWeight' $weight
    if ($name) { $shape.NameU = $name }
    return $shape
}

function Add-Text($page, [double]$x1, [double]$y1, [double]$x2, [double]$y2,
                  [string]$value, [int]$pt = 11, [string]$color = 'RGB(33,43,54)',
                  [int]$align = 1, [string]$name = '') {
    $shape = $page.DrawRectangle($x1, $y1, $x2, $y2)
    Set-Cell $shape 'FillPattern' '0'
    Set-Cell $shape 'LinePattern' '0'
    $shape.Text = $value
    Set-Cell $shape 'Char.Size' "$pt pt"
    Set-Cell $shape 'Char.Color' $color
    Set-Cell $shape 'Para.HorzAlign' "$align"
    Set-Cell $shape 'VerticalAlign' '1'
    if ($name) { $shape.NameU = $name }
    return $shape
}

function Add-Line($page, [double]$x1, [double]$y1, [double]$x2, [double]$y2,
                  [string]$color = 'RGB(70,75,82)', [string]$weight = '0.025 in',
                  [bool]$arrow = $false, [bool]$dash = $false, [string]$name = '') {
    $shape = $page.DrawLine($x1, $y1, $x2, $y2)
    Set-Cell $shape 'LineColor' $color
    Set-Cell $shape 'LineWeight' $weight
    if ($arrow) { Set-Cell $shape 'EndArrow' '4' }
    if ($dash) { Set-Cell $shape 'LinePattern' '2' }
    if ($name) { $shape.NameU = $name }
    return $shape
}

function Add-Poly($page, [double[]]$points, [string]$fill,
                  [string]$stroke = 'RGB(70,75,82)', [string]$weight = '0.012 in',
                  [string]$name = '') {
    try { $shape = $page.DrawPolyline($points, 0) }
    catch { throw "Polyline ${name} with $($points -join ',') failed: $_" }
    Set-Cell $shape 'FillForegnd' $fill
    Set-Cell $shape 'LineColor' $stroke
    Set-Cell $shape 'LineWeight' $weight
    if ($name) { $shape.NameU = $name }
    return $shape
}

function Add-Oval($page, [double]$x1, [double]$y1, [double]$x2, [double]$y2,
                  [string]$fill, [string]$stroke = 'RGB(70,75,82)', [string]$name = '') {
    $shape = $page.DrawOval($x1, $y1, $x2, $y2)
    Set-Cell $shape 'FillForegnd' $fill
    Set-Cell $shape 'LineColor' $stroke
    Set-Cell $shape 'LineWeight' '0.006 in'
    if ($name) { $shape.NameU = $name }
    return $shape
}

function Add-ExplodedLayer($page, [string]$code, [double]$x, [double]$width,
                           [string]$front, [string]$top, [string]$side,
                           [string]$texture = '') {
    $bottom = 6.87
    $height = 1.43
    $skew = 0.17
    $depthX = 0.18
    $depthY = 0.13
    $right = $x + $width
    $upper = $bottom + $height
    $edge = 'RGB(74,84,94)'
    Add-Poly $page ([double[]]@($x,$upper, ($x+$depthX),($upper+$depthY), ($right+$depthX),($upper+$skew+$depthY), $right,($upper+$skew), $x,$upper)) $top $edge '0.013 in' ("${code}_top") | Out-Null
    Add-Poly $page ([double[]]@($right,($bottom+$skew), ($right+$depthX),($bottom+$skew+$depthY), ($right+$depthX),($upper+$skew+$depthY), $right,($upper+$skew), $right,($bottom+$skew))) $side $edge '0.013 in' ("${code}_side") | Out-Null
    Add-Poly $page ([double[]]@($x,$bottom, $right,($bottom+$skew), $right,($upper+$skew), $x,$upper, $x,$bottom)) $front $edge '0.015 in' ("${code}_front") | Out-Null
    if ($texture -eq 'ribs') {
        for ($i = 0; $i -lt 6; $i++) {
            $yy = $bottom + 0.22 + $i * 0.19
            Add-Line $page ($x+0.10) $yy ($right-0.08) ($yy+$skew*0.70) 'RGB(35,40,46)' '0.032 in' | Out-Null
        }
    }
    if ($texture -eq 'porous' -or $texture -eq 'catalyst') {
        $dots = @(
            @(0.13,0.18),@(0.31,0.22),@(0.52,0.16),@(0.73,0.25),@(0.86,0.17),
            @(0.22,0.39),@(0.43,0.43),@(0.66,0.37),@(0.82,0.48),
            @(0.12,0.59),@(0.32,0.64),@(0.55,0.56),@(0.75,0.66),
            @(0.20,0.82),@(0.44,0.79),@(0.65,0.86),@(0.84,0.77)
        )
        $dotColor = if ($texture -eq 'porous') { 'RGB(73,85,96)' } else { 'RGB(195,141,55)' }
        $d = if ($texture -eq 'porous') { 0.065 } else { 0.043 }
        $j = 0
        foreach ($p in $dots) {
            $cx = $x + $p[0] * $width
            $cy = $bottom + $p[1] * $height + $p[0] * $skew
            Add-Oval $page ($cx-$d/2) ($cy-$d/2) ($cx+$d/2) ($cy+$d/2) $dotColor $dotColor ("${code}_grain_$j") | Out-Null
            $j++
        }
    }
    if ($texture -eq 'membrane') {
        Add-Poly $page ([double[]]@(($x+0.17),($bottom+0.05), ($x+0.29),($bottom+0.07), ($x+0.29),($upper+0.03), ($x+0.17),($upper+0.01), ($x+0.17),($bottom+0.05))) 'RGB(212,234,251)' 'RGB(212,234,251)' '0.004 in' ("${code}_highlight") | Out-Null
    }
}

$visio = $null
$document = $null
try {
    $visio = New-Object -ComObject Visio.Application
    $visio.Visible = $false
    $document = $visio.Documents.Add('')
    $page = $visio.ActivePage
    $page.Name = '问题一模型结构'
    Set-Cell $page.PageSheet 'PageWidth' '16 in'
    Set-Cell $page.PageSheet 'PageHeight' '10 in'

    $ink = 'RGB(34,48,62)'
    $gray = 'RGB(100,112,123)'
    $plate = 'RGB(77,84,93)'
    $gdl = 'RGB(191,203,211)'
    $cl = 'RGB(238,195,92)'
    $pem = 'RGB(155,196,231)'
    $red = 'RGB(198,65,63)'
    $blue = 'RGB(36,114,183)'
    $green = 'RGB(31,135,91)'
    $orange = 'RGB(221,117,42)'

    Add-Text $page 0.65 9.47 15.3 9.9 '（a）单电池分层结构与主要输运过程' 20 $ink 0 'panel_a_title' | Out-Null
    Add-Line $page 0.65 9.38 15.3 9.38 'RGB(196,205,213)' '0.014 in' | Out-Null

    $layers = @(
        @{ code='anode_plate'; name='阳极双极板'; short=''; x=1.00; w=0.72; front='RGB(74,78,83)'; top='RGB(125,130,135)'; side='RGB(38,42,47)'; texture='ribs' },
        @{ code='aGDL'; name='阳极气体扩散层'; short='aGDL'; x=2.20; w=1.38; front='RGB(187,196,200)'; top='RGB(228,234,236)'; side='RGB(126,139,148)'; texture='porous' },
        @{ code='aCL'; name='阳极催化层'; short='aCL'; x=4.05; w=1.14; front='RGB(231,190,98)'; top='RGB(249,221,153)'; side='RGB(187,139,60)'; texture='catalyst' },
        @{ code='PEM'; name='质子交换膜'; short='PEM'; x=5.68; w=1.40; front='RGB(149,192,231)'; top='RGB(209,231,249)'; side='RGB(101,151,197)'; texture='membrane' },
        @{ code='cCL'; name='阴极催化层'; short='cCL'; x=7.58; w=1.14; front='RGB(231,190,98)'; top='RGB(249,221,153)'; side='RGB(187,139,60)'; texture='catalyst' },
        @{ code='cGDL'; name='阴极气体扩散层'; short='cGDL'; x=9.18; w=1.38; front='RGB(187,196,200)'; top='RGB(228,234,236)'; side='RGB(126,139,148)'; texture='porous' },
        @{ code='cathode_plate'; name='阴极双极板'; short=''; x=11.08; w=0.72; front='RGB(74,78,83)'; top='RGB(125,130,135)'; side='RGB(38,42,47)'; texture='ribs' }
    )
    foreach ($layer in $layers) {
        Write-Output "Drawing $($layer.code)"
        Add-ExplodedLayer $page $layer.code $layer.x $layer.w $layer.front $layer.top $layer.side $layer.texture
        $label = if ($layer.short) { "$($layer.name)`n$($layer.short)" } else { $layer.name }
        Add-Text $page ($layer.x-0.25) 8.70 ($layer.x+$layer.w+0.35) 9.16 $label 10 $ink 1 ("label_" + $layer.code) | Out-Null
    }
    Add-Text $page 2.38 7.42 3.37 7.76 'H₂' 16 $red | Out-Null
    Add-Text $page 4.17 7.42 5.08 7.76 'H⁺' 15 $red | Out-Null
    Add-Text $page 5.97 7.42 6.85 7.76 'H⁺' 15 $green | Out-Null
    Add-Text $page 7.72 7.42 8.56 7.76 'H₂O' 13 $blue | Out-Null
    Add-Text $page 9.46 7.42 10.30 7.76 'O₂' 16 $blue | Out-Null
    Add-Text $page 9.43 8.03 10.02 8.29 '液水' 10 $blue | Out-Null
    Add-Text $page 10.02 7.86 10.49 8.14 '冰' 11 $blue | Out-Null

    Add-Line $page 0.37 7.55 0.95 7.55 $red '0.038 in' $true $false 'hydrogen_in' | Out-Null
    Add-Text $page 0.22 7.86 0.99 8.14 'H₂入口' 10 $red | Out-Null
    Add-Line $page 12.42 7.55 11.85 7.55 $blue '0.038 in' $true $false 'oxygen_in' | Out-Null
    Add-Text $page 11.76 7.86 12.53 8.14 'O₂入口' 10 $blue | Out-Null
    Add-Line $page 5.16 6.62 7.62 6.62 $green '0.030 in' $true $false 'proton_transport' | Out-Null
    Add-Text $page 5.62 6.66 7.12 6.92 '质子传导' 10 $green | Out-Null
    Add-Line $page 1.35 6.17 11.45 6.17 $red '0.030 in' $true $false 'electron_path' | Out-Null
    Add-Line $page 1.35 6.82 1.35 6.17 $red '0.030 in' $false | Out-Null
    Add-Line $page 11.50 6.17 11.50 6.82 $red '0.030 in' $true | Out-Null
    Add-Text $page 4.70 5.92 8.28 6.20 '电子经外电路传输' 10 $red | Out-Null

    Add-Text $page 12.74 8.28 15.28 8.61 '低温阴极过程' 13 $ink | Out-Null
    Add-Oval $page 12.81 7.95 12.96 8.10 $blue $blue 'water_icon' | Out-Null
    Add-Text $page 13.05 7.88 15.25 8.17 '催化层产水' 11 $blue 0 | Out-Null
    Add-Line $page 12.82 7.62 13.00 7.62 $blue '0.014 in' | Out-Null
    Add-Line $page 12.91 7.53 12.91 7.71 $blue '0.014 in' | Out-Null
    Add-Line $page 12.85 7.56 12.97 7.68 $blue '0.014 in' | Out-Null
    Add-Line $page 12.85 7.68 12.97 7.56 $blue '0.014 in' | Out-Null
    Add-Text $page 13.05 7.48 15.25 7.77 '液水／冰相变' 11 $blue 0 | Out-Null
    Add-Oval $page 12.83 7.14 12.98 7.29 $orange $orange 'pore_icon' | Out-Null
    Add-Text $page 13.05 7.08 15.25 7.37 '结冰影响孔隙输运' 11 $orange 0 | Out-Null

    Add-Text $page 0.65 5.48 15.3 5.93 '（b）一维求解区域（沿厚度 x 方向）' 20 $ink 0 'panel_b_title' | Out-Null
    Add-Line $page 0.65 5.39 15.3 5.39 'RGB(196,205,213)' '0.014 in' | Out-Null
    $domain = @(
        @{ name='aGDL'; x1=1.0; x2=3.9; fill=$gdl },
        @{ name='aCL'; x1=3.9; x2=5.8; fill=$cl },
        @{ name='PEM'; x1=5.8; x2=9.0; fill=$pem },
        @{ name='cCL'; x1=9.0; x2=10.9; fill=$cl },
        @{ name='cGDL'; x1=10.9; x2=13.8; fill=$gdl }
    )
    foreach ($part in $domain) {
        Add-Rect $page $part.x1 4.10 $part.x2 4.91 $part.fill 'RGB(77,88,98)' '0.018 in' ("domain_" + $part.name) | Out-Null
        Add-Text $page $part.x1 4.31 $part.x2 4.69 $part.name 16 $ink | Out-Null
    }
    Add-Line $page 1.00 3.86 13.80 3.86 $orange '0.034 in' $true $false 'heat_transport' | Out-Null
    Add-Text $page 5.72 3.63 9.02 3.92 '热传导' 11 $orange | Out-Null
    Add-Line $page 1.00 3.38 13.80 3.38 $gray '0.015 in' $false $false 'total_thickness' | Out-Null
    Add-Line $page 1.00 3.27 1.00 3.49 $gray '0.015 in' | Out-Null
    Add-Line $page 13.80 3.27 13.80 3.49 $gray '0.015 in' | Out-Null
    Add-Text $page 5.46 3.04 9.30 3.36 '总厚度 L = 326.7 μm' 13 $ink | Out-Null
    Add-Line $page 13.81 3.38 14.65 3.38 $ink '0.02 in' $true | Out-Null
    Add-Text $page 14.62 3.22 15.03 3.55 'x' 14 $ink | Out-Null
    Add-Text $page 9.92 5.02 13.80 5.30 '阴极侧：产水、水／冰相变' 11 $blue | Out-Null

    Add-Text $page 0.65 2.47 15.3 2.90 '（c）有限体积离散' 20 $ink 0 'panel_c_title' | Out-Null
    Add-Line $page 0.65 2.39 15.3 2.39 'RGB(196,205,213)' '0.014 in' | Out-Null
    $start = 1.00
    $width = 12.8 / 63.0
    $parts = @(
        @{ name='aGDL'; count=6; fill=$gdl },
        @{ name='aCL'; count=13; fill=$cl },
        @{ name='PEM'; count=19; fill=$pem },
        @{ name='cCL'; count=19; fill=$cl },
        @{ name='cGDL'; count=6; fill=$gdl }
    )
    $idx = 0
    foreach ($part in $parts) {
        $partStart = $start + $idx * $width
        for ($i = 0; $i -lt $part.count; $i++) {
            $x1 = $start + $idx * $width
            $x2 = $x1 + $width
            Add-Rect $page $x1 1.50 $x2 2.08 $part.fill 'RGB(64,76,88)' '0.007 in' ("cell_{0:d2}" -f ($idx + 1)) | Out-Null
            $idx++
        }
        $partEnd = $start + $idx * $width
        Add-Text $page $partStart 2.10 $partEnd 2.32 $part.name 10 $ink | Out-Null
        Add-Text $page $partStart 1.15 $partEnd 1.43 ([string]$part.count) 12 $ink | Out-Null
        Add-Line $page $partStart 1.45 $partEnd 1.45 $gray '0.011 in' | Out-Null
    }
    Add-Text $page 3.55 0.72 11.28 1.06 '网格数 n = (6, 13, 19, 19, 6)，总计 N = 63' 13 $ink | Out-Null
    Add-Text $page 2.17 0.22 12.68 0.58 '状态量：温度、氢氧浓度、液水量、冰量、阴极催化层含水量' 11 $gray | Out-Null

    $document.SaveAs($visioPath)
    $page.Export($previewPath)
    $document.ExportAsFixedFormat(1, $pdfPath, 1, 0)
    Write-Output "VSDX: $visioPath"
    Write-Output "Preview: $previewPath"
    Write-Output "PDF: $pdfPath"
    Write-Output "Shapes: $($page.Shapes.Count)"
}
finally {
    if ($document) {
        try {
            $document.Saved = $true
            $document.Close()
        }
        catch { Write-Warning "Could not close Visio document: $_" }
    }
    if ($visio) {
        try { $visio.Quit() }
        catch { Write-Warning "Could not close Visio: $_" }
    }
}
