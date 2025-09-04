Add-Type -AssemblyName PresentationFramework

# --- Configuration des chemins ---
$jsonPath = ".\logiciels_inforsud.json"
$cachePath = ".\winget_cache.json"
$cacheMaxAge = 24 # heures

# Fonction pour créer le fichier JSON par défaut s'il n'existe pas
function New-DefaultJsonFile {
    $defaultData = @{
        metadata = @{
            version = "1.0"
            description = "Configuration logiciels INFORSUD Technologies"
            last_updated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        categories = @{
            "Navigateurs" = @(
                @{ nom = "Chrome"; id = "Google.Chrome"; description = "Navigateur web Google"; priority = 1 }
                @{ nom = "Firefox"; id = "Mozilla.Firefox.fr"; description = "Navigateur Mozilla Firefox"; priority = 2 }
                @{ nom = "Edge"; id = "Microsoft.Edge"; description = "Navigateur Microsoft Edge"; priority = 3 }
                @{ nom = "Opera"; id = "XP8CF6S8G2D5T6"; description = "Navigateur Opera"; priority = 4 }
                @{ nom = "Brave"; id = "XP8C9QZMS2PC1T"; description = "Navigateur Brave"; priority = 5 }
            )
            "Messagerie" = @(
                @{ nom = "Teams"; id = "Microsoft.Teams"; description = "Microsoft Teams"; priority = 1 }
                @{ nom = "Zoom"; id = "XP99J3KP4XZ4VV"; description = "Zoom Video Communications"; priority = 2 }
                @{ nom = "Discord"; id = "Discord.Discord"; description = "Discord"; priority = 3 }
                @{ nom = "Thunderbird"; id = "Mozilla.Thunderbird.fr"; description = "Client email Mozilla"; priority = 4 }
            )
            "Cloud" = @(
                @{ nom = "OneDrive"; id = "Microsoft.OneDrive"; description = "Stockage cloud Microsoft"; priority = 1 }
                @{ nom = "Google Drive"; id = "Google.GoogleDrive"; description = "Stockage cloud Google"; priority = 2 }
                @{ nom = "Dropbox"; id = "Dropbox.Dropbox"; description = "Stockage cloud Dropbox"; priority = 3 }
            )
            "Media" = @(
                @{ nom = "VLC"; id = "VideoLAN.VLC"; description = "Lecteur multimédia VLC"; priority = 1 }
                @{ nom = "Spotify"; id = "Spotify.Spotify"; description = "Streaming musical"; priority = 2 }
                @{ nom = "iTunes"; id = "Apple.iTunes"; description = "Lecteur Apple iTunes"; priority = 3 }
                @{ nom = "Audacity"; id = "Audacity.Audacity"; description = "Éditeur audio"; priority = 4 }
            )
            "Documents" = @(
                @{ nom = "Adobe Reader DC"; id = "XPDP273C0XHQH2"; description = "Lecteur PDF Adobe"; priority = 1 }
                @{ nom = "LibreOffice"; id = "TheDocumentFoundation.LibreOffice"; description = "Suite bureautique libre"; priority = 2 }
                @{ nom = "OpenOffice"; id = "Apache.OpenOffice"; description = "Suite bureautique Apache"; priority = 3 }
                @{ nom = "Foxit Reader"; id = "XPFCG5NRKXQPKT"; description = "Lecteur PDF Foxit"; priority = 4 }
            )
            "Utilitaires" = @(
                @{ nom = "Notepad++"; id = "Notepad++.Notepad++"; description = "Éditeur de texte avancé"; priority = 1 }
                @{ nom = "7-Zip"; id = "7zip.7zip"; description = "Gestionnaire d'archives"; priority = 2 }
                @{ nom = "TeamViewer"; id = "TeamViewer.TeamViewer"; description = "Accès distant"; priority = 3 }
                @{ nom = "AnyDesk"; id = "AnyDesk.AnyDesk"; description = "Bureau à distance"; priority = 4 }
                @{ nom = "KeePass"; id = "DominikReichl.KeePass"; description = "Gestionnaire de mots de passe"; priority = 5 }
                @{ nom = "PuTTY"; id = "PuTTY.PuTTY"; description = "Client SSH/Telnet"; priority = 6 }
                @{ nom = "WinSCP"; id = "WinSCP.WinSCP"; description = "Client SFTP/SCP"; priority = 7 }
            )
        }
    }
    
    $defaultData | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonPath -Encoding UTF8
    return $defaultData
}

# Fonction pour charger le cache WinGet
function Get-WinGetCache {
    if (Test-Path $cachePath) {
        $cacheFile = Get-Item $cachePath
        $ageHours = ((Get-Date) - $cacheFile.LastWriteTime).TotalHours
        
        if ($ageHours -lt $cacheMaxAge) {
            try {
                $cache = Get-Content $cachePath -Raw | ConvertFrom-Json
                Write-Log "📦 Cache WinGet chargé ($([math]::Round($ageHours, 1))h)" "INFO"
                return $cache
            } catch {
                Write-Log "⚠️ Cache corrompu, rechargement nécessaire" "WARNING"
            }
        } else {
            Write-Log "📦 Cache WinGet expiré ($([math]::Round($ageHours, 1))h > $cacheMaxAge h)" "INFO"
        }
    }
    return $null
}

# Fonction pour mettre à jour le cache WinGet
function Update-WinGetCache {
    Write-Log "🔄 Mise à jour du catalogue WinGet..." "INFO"
    
    try {
        # Récupération de la liste complète WinGet
        $wingetList = & winget search --accept-source-agreements 2>$null | 
                     Select-String -Pattern "^[A-Za-z0-9]" | 
                     ForEach-Object {
                         $line = $_.Line -split '\s{2,}'
                         if ($line.Count -ge 3) {
                             @{
                                 nom = $line[0].Trim()
                                 id = $line[1].Trim()
                                 source = if ($line.Count -gt 2) { $line[2].Trim() } else { "winget" }
                             }
                         }
                     } | Where-Object { $_.id -and $_.id -ne "Id" }
        
        $cacheData = @{
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            count = $wingetList.Count
            packages = $wingetList
        }
        
        $cacheData | ConvertTo-Json -Depth 3 | Out-File -FilePath $cachePath -Encoding UTF8
        Write-Log "✅ Cache WinGet mis à jour: $($wingetList.Count) packages" "SUCCESS"
        return $cacheData
        
    } catch {
        Write-Log "❌ Erreur lors de la mise à jour du cache: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Chargement des données JSON INFORSUD
if (-not (Test-Path $jsonPath)) {
    Write-Host "Création du fichier de configuration par défaut..." -ForegroundColor Yellow
    $jsonData = New-DefaultJsonFile
} else {
    try {
        $jsonData = Get-Content $jsonPath -Raw | ConvertFrom-Json
    } catch {
        [System.Windows.MessageBox]::Show("Erreur lors de la lecture du fichier JSON.`n$($_.Exception.Message)","Erreur", 'OK', 'Error')
        return
    }
}

# Chargement du cache WinGet
$wingetCache = Get-WinGetCache

# Définition du XAML avec interface améliorée
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Distribution Logiciels INFORSUD v4.0 - Hybrid JSON + WinGet"
        Height="900" Width="750"
        WindowStartupLocation="CenterScreen"
        Background="White"
        FontFamily="Segoe UI"
        Foreground="#2C3E50"
        MinHeight="700" MinWidth="600">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="200"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- En-tête -->
        <Border Grid.Row="0" Padding="20,15">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#1E88E5" Offset="0"/>
                    <GradientStop Color="#1976D2" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>
            <StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <TextBlock Text="🏢" FontSize="24" Margin="0,0,10,0" VerticalAlignment="Center"/>
                    <TextBlock Text="INFORSUD Technologies v4.0" FontSize="20" FontWeight="Bold" 
                               Foreground="White" VerticalAlignment="Center"/>
                </StackPanel>
                <TextBlock Text="Distribution Hybride: Catalogue JSON + WinGet Complet" 
                           FontSize="14" Foreground="#E3F2FD" HorizontalAlignment="Center"
                           Margin="0,5,0,0"/>
            </StackPanel>
        </Border>
        
        <!-- Zone de contrôles -->
        <Border Grid.Row="1" Background="#F5F5F5" Padding="20,15" BorderBrush="#E0E0E0" BorderThickness="0,0,0,1">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                
                <!-- Source de données -->
                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,12">
                    <TextBlock Text="📊 Source:" FontWeight="SemiBold" Foreground="#37474F" VerticalAlignment="Center" Margin="0,0,10,0"/>
                    <RadioButton x:Name="SourceInforsud" Content="Catalogue INFORSUD" IsChecked="True" 
                                 Margin="0,0,20,0" FontWeight="SemiBold" Foreground="#1976D2"/>
                    <RadioButton x:Name="SourceWinget" Content="Catalogue WinGet Complet" 
                                 Margin="0,0,20,0" FontWeight="SemiBold" Foreground="#1976D2"/>
                    <Button x:Name="RefreshCacheBtn" Content="🔄 Actualiser Cache" 
                            Padding="8,4" Background="#FFF3E0" Foreground="#F57C00" 
                            BorderBrush="#FFB74D" FontSize="11" FontWeight="SemiBold"/>
                </StackPanel>
                
                <!-- Recherche -->
                <StackPanel Grid.Row="1" Margin="0,0,0,12">
                    <TextBlock Text="🔍 Rechercher:" Margin="0,0,0,6" FontWeight="SemiBold" Foreground="#37474F"/>
                    <TextBox x:Name="SearchBox" Height="35" Background="White" Foreground="#2C3E50" 
                             FontSize="14" BorderBrush="#1976D2" BorderThickness="2" Padding="10,8"/>
                </StackPanel>
                
                <!-- Options et compteur -->
                <Grid Grid.Row="2">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <CheckBox x:Name="SilentMode" Content="🔇 Installation silencieuse" 
                              IsChecked="True" FontWeight="SemiBold" Foreground="#37474F" Grid.Column="0"/>
                    <TextBlock x:Name="CountLabel" Text="0 logiciel(s)" VerticalAlignment="Center" 
                               Foreground="#757575" FontStyle="Italic" Grid.Column="1" Margin="10,0"/>
                    <TextBlock x:Name="CacheStatus" Text="" VerticalAlignment="Center" 
                               Foreground="#4CAF50" FontSize="11" Grid.Column="2"/>
                </Grid>
            </Grid>
        </Border>
        
        <!-- Liste des logiciels -->
        <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" Background="#FAFAFA">
            <StackPanel x:Name="MainPanel" Margin="15,10" />
        </ScrollViewer>
        
        <!-- Zone de logs -->
        <Grid Grid.Row="3" Margin="15,10,15,5">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,8">
                <TextBlock Text="📋 Journal d'installation" FontWeight="Bold" Foreground="#37474F" VerticalAlignment="Center"/>
                <Border Background="#1976D2" CornerRadius="10" Padding="8,2" Margin="10,0,0,0">
                    <TextBlock x:Name="StatusLabel" Text="Prêt" Foreground="White" FontSize="11" FontWeight="SemiBold"/>
                </Border>
            </StackPanel>
            <Border Grid.Row="1" BorderBrush="#D0D0D0" BorderThickness="1" CornerRadius="4" Background="White">
                <TextBox x:Name="LogBox" Background="White" Foreground="#2C3E50" FontFamily="Consolas" 
                         FontSize="11" IsReadOnly="True" VerticalScrollBarVisibility="Auto" 
                         HorizontalScrollBarVisibility="Auto" Padding="12" TextWrapping="Wrap" BorderThickness="0"/>
            </Border>
        </Grid>
        
        <!-- Boutons d'action -->
        <Border Grid.Row="4" Background="#F8F9FA" Padding="15,12" BorderBrush="#E0E0E0" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <Button x:Name="SelectAllBtn" Content="☑️ Tout sélectionner" 
                        Margin="5" Padding="12,8" Background="White" Foreground="#37474F"
                        BorderBrush="#BDBDBD" FontWeight="SemiBold" FontSize="12"/>
                <Button x:Name="ClearBtn" Content="☐ Tout désélectionner" 
                        Margin="5" Padding="12,8" Background="White" Foreground="#37474F"
                        BorderBrush="#BDBDBD" FontWeight="SemiBold" FontSize="12"/>
                <Button x:Name="InstallBtn" Content="🚀 INSTALLER LA SÉLECTION" 
                        Margin="15,5,5,5" Padding="20,10" Background="#1976D2" Foreground="White"
                        BorderBrush="#1565C0" FontWeight="Bold" FontSize="13"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
"@

# Chargement de l'interface
try {
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    [System.Windows.MessageBox]::Show("Erreur lors du chargement de l'interface:`n$($_.Exception.Message)","Erreur", 'OK', 'Error')
    return
}

# Récupération des contrôles
$mainPanel = $window.FindName("MainPanel")
$logBox = $window.FindName("LogBox")
$searchBox = $window.FindName("SearchBox")
$silentCheck = $window.FindName("SilentMode")
$countLabel = $window.FindName("CountLabel")
$statusLabel = $window.FindName("StatusLabel")
$cacheStatus = $window.FindName("CacheStatus")
$selectAllBtn = $window.FindName("SelectAllBtn")
$clearBtn = $window.FindName("ClearBtn")
$installBtn = $window.FindName("InstallBtn")
$sourceInforsud = $window.FindName("SourceInforsud")
$sourceWinget = $window.FindName("SourceWinget")
$refreshCacheBtn = $window.FindName("RefreshCacheBtn")

# Variables globales
$checkboxes = @()
$script:detailedLog = @()
$logPath = "$env:TEMP\ISTech_Distribution_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Fonction de logging
function Write-Log {
    param (
        [string]$message,
        [string]$type = "INFO",
        [switch]$FileOnly
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $emoji = switch ($type) {
        "SUCCESS" { "✅" }
        "ERROR"   { "❌" }
        "WARNING" { "⚠️" }
        default   { "ℹ️" }
    }
    
    $formattedMessage = "[$timestamp] $emoji $message"
    $script:detailedLog += $formattedMessage
    
    if (-not $FileOnly) {
        $logBox.AppendText("$formattedMessage`n")
        $logBox.ScrollToEnd()
        
        switch ($type) {
            "SUCCESS" { $statusLabel.Text = "Succès" }
            "ERROR"   { $statusLabel.Text = "Erreur" }
            "WARNING" { $statusLabel.Text = "Attention" }
            default   { $statusLabel.Text = "En cours..." }
        }
        
        [System.Windows.Forms.Application]::DoEvents()
    }
}

# Fonction pour créer les contrôles de logiciels
function New-SoftwareControls {
    $mainPanel.Children.Clear()
    $script:checkboxes = @()
    $totalCount = 0
    
    $searchText = $searchBox.Text.Trim().ToLower()
    
    if ($sourceInforsud.IsChecked) {
        # Mode catalogue INFORSUD
        $sortedCategories = $jsonData.categories.PSObject.Properties.Name | Sort-Object
        
        foreach ($categoryName in $sortedCategories) {
            $category = $jsonData.categories.$categoryName
            $groupBox = New-Object Windows.Controls.GroupBox
            $groupBox.Header = "📁 $categoryName"
            $groupBox.Foreground = "#1976D2"
            $groupBox.Margin = '8,5,8,12'
            $groupBox.FontWeight = "SemiBold"
            $groupBox.FontSize = 13
            $groupBox.BorderBrush = "#1976D2"
            $groupBox.BorderThickness = 1
            $groupBox.Background = "White"
            
            $stackPanel = New-Object Windows.Controls.StackPanel
            $stackPanel.Margin = "12,8"
            
            $categoryHasVisibleItems = $false
            
            # Tri par priorité puis par nom
            $sortedSoftware = $category | Sort-Object priority, nom
            
            foreach ($software in $sortedSoftware) {
                if (-not $searchText -or 
                    $software.nom.ToLower().Contains($searchText) -or 
                    $software.id.ToLower().Contains($searchText) -or
                    ($software.description -and $software.description.ToLower().Contains($searchText))) {
                    
                    $checkbox = New-Object Windows.Controls.CheckBox
                    $tooltip = "$($software.nom)`nID: $($software.id)"
                    if ($software.description) {
                        $tooltip += "`nDescription: $($software.description)"
                    }
                    
                    $checkbox.Content = $software.nom
                    $checkbox.Tag = $software.id
                    $checkbox.ToolTip = $tooltip
                    $checkbox.Foreground = "#37474F"
                    $checkbox.Margin = "8,4"
                    $checkbox.FontSize = 12
                    $checkbox.FontWeight = "Normal"
                    
                    $stackPanel.Children.Add($checkbox)
                    $script:checkboxes += $checkbox
                    $categoryHasVisibleItems = $true
                    $totalCount++
                }
            }
            
            if ($categoryHasVisibleItems) {
                $groupBox.Content = $stackPanel
                $mainPanel.Children.Add($groupBox)
            }
        }
        
        $countLabel.Text = "$totalCount logiciel(s) INFORSUD"
        
    } else {
        # Mode catalogue WinGet complet
        if (-not $wingetCache -or -not $wingetCache.packages) {
            $noDataLabel = New-Object Windows.Controls.TextBlock
            $noDataLabel.Text = "⚠️ Cache WinGet non disponible. Cliquez sur 'Actualiser Cache' pour charger le catalogue complet."
            $noDataLabel.FontSize = 14
            $noDataLabel.Foreground = "#FF9800"
            $noDataLabel.TextWrapping = "Wrap"
            $noDataLabel.Margin = "20"
            $noDataLabel.HorizontalAlignment = "Center"
            $mainPanel.Children.Add($noDataLabel)
            $countLabel.Text = "0 logiciel(s) - Cache requis"
            return
        }
        
        # Grouper par première lettre pour un affichage organisé
        $filteredPackages = $wingetCache.packages | Where-Object {
            -not $searchText -or 
            $_.nom.ToLower().Contains($searchText) -or 
            $_.id.ToLower().Contains($searchText)
        }
        
        if ($searchText) {
            # Mode recherche : affichage en liste simple
            $groupBox = New-Object Windows.Controls.GroupBox
            $groupBox.Header = "🔍 Résultats de recherche WinGet ($($filteredPackages.Count))"
            $groupBox.Foreground = "#1976D2"
            $groupBox.Margin = '8,5,8,12'
            $groupBox.FontWeight = "SemiBold"
            $groupBox.FontSize = 13
            $groupBox.BorderBrush = "#1976D2"
            $groupBox.BorderThickness = 1
            $groupBox.Background = "White"
            
            $stackPanel = New-Object Windows.Controls.StackPanel
            $stackPanel.Margin = "12,8"
            
            # Limiter les résultats pour les performances
            $limitedResults = $filteredPackages | Select-Object -First 100
            
            foreach ($package in $limitedResults) {
                $checkbox = New-Object Windows.Controls.CheckBox
                $checkbox.Content = "$($package.nom) [$($package.source)]"
                $checkbox.Tag = $package.id
                $checkbox.ToolTip = "Nom: $($package.nom)`nID: $($package.id)`nSource: $($package.source)"
                $checkbox.Foreground = "#37474F"
                $checkbox.Margin = "8,4"
                $checkbox.FontSize = 12
                $checkbox.FontWeight = "Normal"
                
                $stackPanel.Children.Add($checkbox)
                $script:checkboxes += $checkbox
                $totalCount++
            }
            
            if ($limitedResults.Count -eq 100 -and $filteredPackages.Count -gt 100) {
                $moreLabel = New-Object Windows.Controls.TextBlock
                $moreLabel.Text = "... et $($filteredPackages.Count - 100) résultats supplémentaires (affinez votre recherche)"
                $moreLabel.FontStyle = "Italic"
                $moreLabel.Foreground = "#757575"
                $moreLabel.Margin = "8,4"
                $stackPanel.Children.Add($moreLabel)
            }
            
            $groupBox.Content = $stackPanel
            $mainPanel.Children.Add($groupBox)
            
        } else {
            # Mode navigation : message d'instruction
            $instructionLabel = New-Object Windows.Controls.TextBlock
            $instructionLabel.Text = "📝 Catalogue WinGet actif ($($wingetCache.packages.Count) packages disponibles)`n`n🔍 Utilisez la barre de recherche pour trouver des logiciels spécifiques.`n`nExemples de recherche :`n• 'chrome' pour les navigateurs Chrome`n• 'office' pour les suites bureautiques`n• 'visual' pour Visual Studio/Code`n• 'adobe' pour les produits Adobe"
            $instructionLabel.FontSize = 14
            $instructionLabel.Foreground = "#666"
            $instructionLabel.TextWrapping = "Wrap"
            $instructionLabel.Margin = "20"
            $instructionLabel.HorizontalAlignment = "Center"
            $mainPanel.Children.Add($instructionLabel)
        }
        
        $countLabel.Text = "$totalCount logiciel(s) WinGet"
    }
}

# Fonction d'installation
function Start-SoftwareInstallation {
    $installBtn.IsEnabled = $false
    $statusLabel.Text = "Installation en cours..."
    $selectedSoftware = $script:checkboxes | Where-Object { $_.IsChecked -eq $true }
    
    if (-not $selectedSoftware) {
        Write-Log "Aucun logiciel sélectionné pour l'installation." "WARNING"
        $installBtn.IsEnabled = $true
        $statusLabel.Text = "Prêt"
        return
    }
    
    Write-Log "=== INFORSUD Technologies v4.0 - Début d'installation ===" "INFO"
    Write-Log "Mode: $(if ($sourceInforsud.IsChecked) { 'Catalogue INFORSUD' } else { 'Catalogue WinGet' })" "INFO"
    Write-Log "Nombre de logiciels à installer: $($selectedSoftware.Count)" "INFO"
    Write-Log "Mode silencieux: $($silentCheck.IsChecked)" "INFO"
    Write-Log "=================================================" "INFO"
    
    $successCount = 0
    $errorCount = 0
    
    foreach ($checkbox in $selectedSoftware) {
        $softwareName = $checkbox.Content
        $softwareId = $checkbox.Tag
        
        Write-Log "🔄 Installation de '$softwareName' en cours..." "INFO"
        
        $wingetArgs = @("install", $softwareId, "--accept-source-agreements", "--accept-package-agreements")
        if ($silentCheck.IsChecked) {
            $wingetArgs += "--silent"
        }
        
        try {
            $process = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -Wait -PassThru -WindowStyle Hidden
            
            if ($process.ExitCode -eq 0) {
                Write-Log "✅ '$softwareName' installé avec succès !" "SUCCESS"
                $successCount++
            } else {
                Write-Log "❌ Échec installation '$softwareName' (Code: $($process.ExitCode))" "ERROR"
                $errorCount++
            }
        } catch {
            Write-Log "❌ Erreur système '$softwareName': $($_.Exception.Message)" "ERROR"
            $errorCount++
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    Write-Log "=================================================" "INFO"
    Write-Log "🏁 INSTALLATION TERMINÉE" "INFO"
    Write-Log "✅ Réussites: $successCount | ❌ Échecs: $errorCount" "INFO"
    Write-Log "💾 Taux de succès: $([math]::Round(($successCount/($successCount+$errorCount))*100,1))%" "INFO"
    
    # Sauvegarde du log
    try {
        $logHeader = @"
=== INFORSUD TECHNOLOGIES v4.0 - RAPPORT D'INSTALLATION ===
Date: $(Get-Date -Format 'dd/MM/yyyy à HH:mm:ss')
Utilisateur: $env:USERNAME
Machine: $env:COMPUTERNAME
Mode: $(if ($sourceInforsud.IsChecked) { 'Catalogue INFORSUD' } else { 'Catalogue WinGet' })
============================================================

"@
        ($logHeader + ($script:detailedLog -join "`n")) | Out-File -FilePath $logPath -Encoding UTF8
        Write-Log "📄 Rapport sauvegardé: $logPath" "SUCCESS"
    } catch {
        Write-Log "❌ Erreur sauvegarde log: $($_.Exception.Message)" "ERROR"
    }
    
    $installBtn.IsEnabled = $true
    $statusLabel.Text = if ($errorCount -eq 0) { "Terminé ✅" } else { "Terminé avec erreurs ⚠️" }
}

# Gestionnaires d'événements
$searchBox.Add_TextChanged({ New-SoftwareControls })

$sourceInforsud.Add_Checked({ New-SoftwareControls })
$sourceWinget.Add_Checked({ New-SoftwareControls })

$refreshCacheBtn.Add_Click({
    $refreshCacheBtn.IsEnabled = $false
    $refreshCacheBtn.Content = "🔄 Mise à jour..."
    
    $script:wingetCache = Update-WinGetCache
    
    if ($script:wingetCache) {
        $cacheStatus.Text = "Cache: $($script:wingetCache.count) packages"
        $cacheStatus.Foreground = "#4CAF50"
        if ($sourceWinget.IsChecked) {
            New-SoftwareControls
        }
    } else {
        $cacheStatus.Text = "Erreur cache"
        $cacheStatus.Foreground = "#F44336"
    }
    
    $refreshCacheBtn.IsEnabled = $true
    $refreshCacheBtn.Content = "🔄 Actualiser Cache"
})

$selectAllBtn.Add_Click({
    foreach ($cb in $script:checkboxes) {
        $cb.IsChecked = $true
    }
    Write-Log "✅ Tous les logiciels sélectionnés." "INFO"
})

$clearBtn.Add_Click({
    foreach ($cb in $script:checkboxes) {
        $cb.IsChecked = $false
    }
    Write-Log "🔄 Toutes les sélections effacées." "INFO"
})

$installBtn.Add_Click({
    Start-SoftwareInstallation
})

$window.Add_Closing({
    if ($script:detailedLog.Count -gt 0 -and (Test-Path $logPath)) {
        $result = [System.Windows.MessageBox]::Show("Un rapport d'installation a été généré.`n`nVoulez-vous l'ouvrir ?", "Rapport disponible", 'YesNo', 'Question')
        if ($result -eq 'Yes') {
            Start-Process notepad.exe -ArgumentList $logPath
        }
    }
})

# Initialisation
$statusLabel.Text = "Initialisation..."
Write-Log "🏢 INFORSUD Technologies v4.0 - Distribution Hybride" "SUCCESS"
Write-Log "📊 Catalogue INFORSUD: $($jsonData.categories.PSObject.Properties.Name.Count) catégories" "INFO"

if ($wingetCache) {
    Write-Log "📦 Cache WinGet: $($wingetCache.count) packages disponibles" "INFO"
    $cacheStatus.Text = "Cache: $($wingetCache.count) packages"
    $cacheStatus.Foreground = "#4CAF50"
} else {
    Write-Log "📦 Cache WinGet: Non disponible (utiliser 'Actualiser Cache')" "WARNING"
    $cacheStatus.Text = "Cache: Non chargé"
    $cacheStatus.Foreground = "#FF9800"
}

Write-Log "👤 Session: $env:USERNAME sur $env:COMPUTERNAME" "INFO"
Write-Log "🚀 Système prêt - Sélectionnez votre source de données" "SUCCESS"

New-SoftwareControls
$statusLabel.Text = "Prêt"

# Affichage de la fenêtre
$window.ShowDialog() | Out-Null