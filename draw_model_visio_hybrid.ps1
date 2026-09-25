$ErrorActionPreference = 'Stop'

$project = Split-Path -Parent $MyInvocation.MyCommand.Path
$figures = Join-Path $project 'figures'
$backgroundPath = Join-Path $figures 'p1_model_background_textless.png'
$visioPath = Join-Path $figures 'p1_model_hybrid_editable.vsdx'
$previewPath = Join-Path $figures 'p1_model_hybrid_editable.png'
$pdfPath = Join-Path $figures 'p1_model_hybrid_editable.pdf'

function Set-Cell($shape, [string]$cell, [string]$formula) {
    try { $shape.CellsU($cell).FormulaU = $formula }
    catch { throw "Could not set $cell to $formula : $_" }
}

function Add-Text($page, [double]$x1, [double]$y1, [double]$x2, [double]$y2,
                  [string]$value, [int]$pt = 16,
                  [string]$color = 'RGB(31,38,46)', [int]$align = 1,
                  [string]$font = 'SimSun', [string]$name = '') {
    $shape = $page.DrawRectangle($x1, $y1, $x2, $y2)
    Set-Cell $shape 'FillPattern' '0'
    Set-Cell $shape 'LinePattern' '0'
    $shape.Text = $value
    Set-Cell $shape 'Char.Size' "$pt pt"
    Set-Cell $shape 'Char.Color' $color
    if ($font -eq 'SimSun') { $font = '宋体' }
    $fontId = $script:document.Fonts.Item($font).ID
    Set-Cell $shape 'Char.Font' ([string]$fontId)
    Set-Cell $shape 'Para.HorzAlign' "$align"
    Set-Cell $shape 'VerticalAlign' '1'
    if ($name) { $shape.NameU = $name }
    return $shape
}

function Add-Line($page, [double]$x1, [double]$y1, [double]$x2, [double]$y2,
                  [string]$color, [string]$weight = '0.025 in',
                  [bool]$arrow = $false, [string]$name = '') {
    $shape = $page.DrawLine($x1, $y1, $x2, $y2)
    Set-Cell $shape 'LineColor' $color
    Set-Cell $shape 'LineWeight' $weight
    if ($arrow) { Set-Cell $shape 'EndArrow' '4' }
    if ($name) { $shape.NameU = $name }
    return $shape
}

$visio = $null
$document = $null
try {
    $visio = New-Object -ComObject Visio.Application
    $visio.Visible = $false
    $document = $visio.Documents.Add('')
    $page = $visio.ActivePage
    $page.Name = '问题一模型结构（可编辑标注）'
    Set-Cell $page.PageSheet 'PageWidth' '15 in'
    Set-Cell $page.PageSheet 'PageHeight' '10 in'

    $background = $page.Import($backgroundPath)
    $background.NameU = 'background_bitmap'
    Set-Cell $background 'Width' '15 in'
    Set-Cell $background 'Height' '10 in'
    Set-Cell $background 'PinX' '7.5 in'
    Set-Cell $background 'PinY' '5 in'
    $background.SendToBack()

    $ink = 'RGB(33,39,47)'
    $red = 'RGB(200,35,41)'
    $blue = 'RGB(18,94,188)'
    $green = 'RGB(24,124,73)'
    $orange = 'RGB(218,104,25)'

    # (a) Exploded cell artwork occupies the upper half of the bitmap.
    Add-Text $page 0.20 9.55 6.10 9.92 '（a）单电池分层结构' 22 $ink 0 'SimSun' 'title_a' | Out-Null
    $layerLabels = @(
        @{cn='阳极双极板'; en=''; x1=1.42; x2=3.08; cx=2.42},
        @{cn='阳极气体扩散层'; en='aGDL'; x1=3.05; x2=5.02; cx=4.30},
        @{cn='阳极催化层'; en='aCL'; x1=4.95; x2=6.55; cx=5.84},
        @{cn='质子交换膜'; en='PEM'; x1=6.72; x2=8.06; cx=7.36},
        @{cn='阴极催化层'; en='cCL'; x1=8.24; x2=9.94; cx=9.14},
        @{cn='阴极气体扩散层'; en='cGDL'; x1=9.96; x2=11.84; cx=10.83},
        @{cn='阴极双极板'; en=''; x1=11.80; x2=13.42; cx=12.30}
    )
    foreach ($layer in $layerLabels) {
        Add-Text $page $layer.x1 9.08 $layer.x2 9.37 $layer.cn 14 $ink 1 'SimSun' ("label_" + $layer.cn) | Out-Null
        if ($layer.en) {
            Add-Text $page $layer.x1 8.80 $layer.x2 9.08 $layer.en 15 $ink 1 'Times New Roman' ("abbr_" + $layer.en) | Out-Null
        }
        Add-Line $page $layer.cx 8.81 $layer.cx 8.64 $ink '0.012 in' | Out-Null
    }
    Add-Text $page 0.17 7.66 1.24 7.99 'H₂' 22 $red 1 'Times New Roman' 'hydrogen_label' | Out-Null
    Add-Line $page 1.27 7.80 1.94 7.80 $red '0.036 in' $true 'hydrogen_arrow' | Out-Null
    Add-Text $page 13.72 7.66 14.80 7.99 'O₂' 22 $blue 1 'Times New Roman' 'oxygen_label' | Out-Null
    Add-Line $page 13.70 7.80 13.02 7.80 $blue '0.036 in' $true 'oxygen_arrow' | Out-Null
    Add-Text $page 7.00 7.58 7.85 7.94 'H⁺' 20 $green 1 'Times New Roman' 'proton_label' | Out-Null
    Add-Line $page 6.95 7.28 8.04 7.28 $green '0.032 in' $true 'proton_arrow' | Out-Null
    Add-Text $page 8.47 6.37 10.38 6.65 '生成水 H₂O' 15 $blue 1 'SimSun' 'water_generation' | Out-Null
    $waterIce = Add-Text $page 10.51 6.37 11.95 6.65 '液水／冰' 15 $blue 1 'SimSun' 'water_ice'
    Set-Cell $waterIce 'FillPattern' '1'
    Set-Cell $waterIce 'FillForegnd' 'RGB(255,255,255)'
    Add-Line $page 2.83 6.04 12.14 6.04 $red '0.030 in' $true 'electron_external' | Out-Null
    Add-Line $page 2.83 6.98 2.83 6.04 $red '0.030 in' | Out-Null
    Add-Line $page 12.14 6.04 12.14 6.98 $red '0.030 in' $true | Out-Null
    Add-Text $page 5.52 5.81 9.55 6.11 '电子经外电路传输' 15 $red 1 'SimSun' 'electron_label' | Out-Null

    # (b) The five-layer colored strip remains raster; all explanations are native Visio text.
    Add-Text $page 0.20 5.16 8.20 5.53 '（b）一维求解区域（沿厚度 x 方向）' 21 $ink 0 'SimSun' 'title_b' | Out-Null
    $domainLabels = @(
        @{cn='阳极气体扩散层'; en='aGDL'; x1=1.82; x2=4.70},
        @{cn='阳极催化层'; en='aCL'; x1=4.70; x2=6.46},
        @{cn='质子交换膜'; en='PEM'; x1=6.46; x2=8.53},
        @{cn='阴极催化层'; en='cCL'; x1=8.53; x2=10.29},
        @{cn='阴极气体扩散层'; en='cGDL'; x1=10.29; x2=13.20}
    )
    foreach ($part in $domainLabels) {
        Add-Text $page $part.x1 4.39 $part.x2 4.67 $part.cn 14 $ink 1 'SimSun' ("domain_cn_" + $part.en) | Out-Null
        $mid = ($part.x1 + $part.x2) / 2
        $abbr = Add-Text $page ($mid-0.55) 3.49 ($mid+0.55) 3.86 $part.en 19 $ink 1 'Times New Roman' ("domain_abbr_" + $part.en)
        Set-Cell $abbr 'FillPattern' '1'
        Set-Cell $abbr 'FillForegnd' 'RGB(255,255,255)'
    }
    Add-Text $page 10.16 4.81 13.34 5.10 '阴极侧水／冰相变' 15 $blue 1 'SimSun' 'phase_change' | Out-Null
    Add-Line $page 2.20 2.99 12.99 2.99 $orange '0.029 in' $true 'heat_arrow' | Out-Null
    $heat = Add-Text $page 6.82 2.87 8.30 3.16 '热传导' 15 $orange 1 'SimSun' 'heat_label'
    Set-Cell $heat 'FillPattern' '1'
    Set-Cell $heat 'FillForegnd' 'RGB(255,255,255)'
    Add-Line $page 1.82 2.46 13.21 2.46 $ink '0.012 in' $false 'thickness_line' | Out-Null
    Add-Line $page 1.82 2.35 1.82 2.57 $ink '0.012 in' | Out-Null
    Add-Line $page 13.21 2.35 13.21 2.57 $ink '0.012 in' | Out-Null
    Add-Text $page 5.60 2.56 9.43 2.84 '总厚度 L = 326.7 μm' 16 $ink 1 'SimSun' 'thickness_label' | Out-Null
    Add-Line $page 13.22 2.46 13.66 2.46 $ink '0.018 in' $true 'x_axis' | Out-Null
    Add-Text $page 13.63 2.30 14.05 2.60 'x' 17 $ink 1 'Times New Roman' | Out-Null

    # (c) Bitmap grid is kept intact; counts and state variables remain editable.
    Add-Text $page 0.20 2.03 5.06 2.37 '（c）有限体积离散' 21 $ink 0 'SimSun' 'title_c' | Out-Null
    $gridGroups = @(
        @{name='aGDL'; count='6'; x1=1.32; x2=3.37},
        @{name='aCL'; count='13'; x1=3.37; x2=5.88},
        @{name='PEM'; count='19'; x1=5.88; x2=8.92},
        @{name='cCL'; count='19'; x1=8.92; x2=11.98},
        @{name='cGDL'; count='6'; x1=11.98; x2=13.72}
    )
    foreach ($group in $gridGroups) {
        Add-Text $page $group.x1 1.17 $group.x2 1.44 $group.count 17 $ink 1 'Times New Roman' ("count_" + $group.name) | Out-Null
    }
    Add-Text $page 3.96 0.74 11.03 1.05 '网格数 n = (6, 13, 19, 19, 6)，总计 N = 63' 16 $ink 1 'SimSun' 'grid_formula' | Out-Null
    Add-Text $page 2.67 0.27 12.34 0.60 '状态量：温度、氢氧浓度、液水量、冰量、阴极催化层含水量' 15 $ink 1 'SimSun' 'states' | Out-Null

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
        try { $document.Saved = $true; $document.Close() }
        catch { Write-Warning "Could not close document: $_" }
    }
    if ($visio) {
        try { $visio.Quit() }
        catch { Write-Warning "Could not close Visio: $_" }
    }
}
