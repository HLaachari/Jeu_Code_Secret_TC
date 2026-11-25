param([ValidateRange(1,99)][int]$NombrePostes = 0)
$ErrorActionPreference = 'Stop'
$kitRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modelePath = Join-Path $kitRoot 'MODELE_POSTE'
$sortiePath = Join-Path $kitRoot 'POSTES_GENERES'
if ($NombrePostes -eq 0) {
    $reponse = Read-Host 'Combien de postes faut-il preparer ? [20]'
    if ([string]::IsNullOrWhiteSpace($reponse)) { $NombrePostes = 20 }
    elseif ($reponse -match '^\d+$' -and [int]$reponse -ge 1 -and [int]$reponse -le 99) { $NombrePostes = [int]$reponse }
    else { throw 'Le nombre de postes doit etre compris entre 1 et 99.' }
}
if (-not (Test-Path -LiteralPath $modelePath -PathType Container)) { throw "Dossier modele introuvable : $modelePath" }
$resolvedKit = [System.IO.Path]::GetFullPath($kitRoot)
$resolvedOutput = [System.IO.Path]::GetFullPath($sortiePath)
if (-not $resolvedOutput.StartsWith($resolvedKit, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Chemin de sortie refuse.' }
if (Test-Path -LiteralPath $sortiePath) { Remove-Item -LiteralPath $sortiePath -Recurse -Force }
New-Item -ItemType Directory -Path $sortiePath | Out-Null
$alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
$utf8SansBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
function Get-Code([int]$poste) {
    return @(
        [string](($poste * 3 + 7) % 10), [string]$alphabet[($poste * 7 + 3) % 26],
        [string](($poste * 5 + 2) % 10), [string](($poste * 7 + 4) % 10),
        [string]$alphabet[($poste * 11 + 5) % 26], [string](($poste * 9 + 6) % 10),
        [string](($poste * 4 + 1) % 10)
    )
}
for ($poste = 1; $poste -le $NombrePostes; $poste++) {
    $destination = Join-Path $sortiePath ('POSTE_{0:D2}' -f $poste)
    Copy-Item -LiteralPath $modelePath -Destination $destination -Recurse
    Get-ChildItem -LiteralPath $destination -Filter '.garder' -File -Recurse | Remove-Item -Force
    $jeuJs = Join-Path $destination 'assets\jeu.js'
    $contenuJs = [System.IO.File]::ReadAllText($jeuJs, [System.Text.Encoding]::UTF8).Replace('__POSTE_ID__', [string]$poste)
    [System.IO.File]::WriteAllText($jeuJs, $contenuJs, $utf8SansBom)
    $code = Get-Code $poste
    $d1 = Join-Path $destination '01_Information_et_traitement'
    New-Item -ItemType Directory -Path $d1 -Force | Out-Null
    Set-Content (Join-Path $d1 'Traitement_automatique.txt') -Encoding UTF8 -Value @("MISSION 1 - POSTE $poste",'','Un traitement automatique est effectue par une machine.','',"FRAGMENT 1 : $($code[0])")
    Set-Content (Join-Path $d1 'Traitement_manuel.txt') -Encoding UTF8 -Value "Le traitement manuel est effectue par un etre humain. Ce fichier est un leurre."
    Set-Content (Join-Path $d1 'Information.txt') -Encoding UTF8 -Value "Une information est un ensemble de donnees ayant un sens. Ce fichier est un leurre."
    $d2 = Join-Path $destination '02_Structure_ordinateur\Unites'
    New-Item -ItemType Directory -Path $d2 -Force | Out-Null
    Set-Content (Join-Path $d2 'Unite_centrale_de_traitement_CPU.txt') -Encoding UTF8 -Value @("MISSION 2 - POSTE $poste",'','Le CPU effectue les calculs et execute les instructions.','',"FRAGMENT 2 : $($code[1])")
    Set-Content (Join-Path $d2 'Unite_de_stockage.txt') -Encoding UTF8 -Value "Cette unite conserve les informations. Ce fichier est un leurre."
    Set-Content (Join-Path $d2 'Unite_de_sortie.txt') -Encoding UTF8 -Value "Cette unite restitue les informations. Ce fichier est un leurre."
    $d3 = Join-Path $destination '03_Peripheriques\Entree'
    New-Item -ItemType Directory -Path $d3 -Force | Out-Null
    Set-Content (Join-Path $d3 'Clavier.txt') -Encoding UTF8 -Value @("MISSION 3 - POSTE $poste",'','Le clavier est un peripherique entree.','',"FRAGMENT 3 : $($code[2])")
    $d4 = Join-Path $destination '04_Composants_internes\Memoire'
    New-Item -ItemType Directory -Path $d4 -Force | Out-Null
    Set-Content (Join-Path $d4 'RAM_memoire_vive.txt') -Encoding UTF8 -Value @("MISSION 4 - POSTE $poste",'','La RAM est volatile.','',"FRAGMENT 4 : $($code[3])")
    Set-Content (Join-Path $d4 'ROM_memoire_morte.txt') -Encoding UTF8 -Value "La ROM est non volatile. Ce fichier est un leurre."
    $annee = 2022 + ($poste % 4)
    $service = @('Banque','Assurance','Entreprise')[$poste % 3]
    $d5 = Join-Path $destination "05_Logiciels_et_domaines\Gestion\Archives\$annee\$service"
    New-Item -ItemType Directory -Path $d5 -Force | Out-Null
    Set-Content (Join-Path $d5 "rapport_TRESOR-TC_POSTE_$poste.txt") -Encoding UTF8 -Value @("MISSION 5 - POSTE $poste",'',"FRAGMENT 5 : $($code[4])")
}
Write-Host ''
Write-Host "$NombrePostes postes ont ete crees dans :"
Write-Host $sortiePath
Write-Host 'Copiez un dossier POSTE different sur chaque ordinateur.'

