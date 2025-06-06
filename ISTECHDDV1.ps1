Add-Type -AssemblyName PresentationFramework

# --- Chemin du CSV ---
$csvPath = ".\logiciels.csv"
if (-not (Test-Path $csvPath)) {
    [System.Windows.MessageBox]::Show("Fichier logiciels.csv introuvable.`nPlace-le dans le même dossier que le script.","Erreur", 'OK', 'Error')
    return
}

# Lecture du CSV avec gestion d'erreur
try {
    $logicielsCSV = Import-Csv -Path $csvPath -Delimiter "," | Where-Object { $_.Nom -and $_.Id -and $_.Categorie }
} catch {
    [System.Windows.MessageBox]::Show("Erreur lors de la lecture du fichier CSV.`n$($_.Exception.Message)","Erreur", 'OK', 'Error')
    return
}

# Organiser les données par catégorie
$logiciels = @{}
foreach ($row in $logicielsCSV) {
    if (-not $logiciels.ContainsKey($row.Categorie)) {
        $logiciels[$row.Categorie] = @()
    }
    $logiciels[$row.Categorie] += @{ Nom = $row.Nom; ID = $row.Id }
}

# Définition du XAML amélioré
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="🚀 Installateur de Logiciels - WinGet"
        Height="750" Width="600"
        WindowStartupLocation="CenterScreen"
        Background="#1E1E1E"
        FontFamily="Segoe UI"
        Foreground="White"
        MinHeight="500" MinWidth="500">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="200"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- En-tête avec recherche et options -->
        <StackPanel Grid.Row="0" Margin="15,10">
            <TextBlock Text="🔍 Rechercher un logiciel :" Margin="0,0,0,5" FontWeight="Bold"/>
            <TextBox x:Name="SearchBox" Height="30" Margin="0,0,0,10" 
                     Background="#333" Foreground="White" FontSize="14"
                     BorderBrush="#555" BorderThickness="1"/>
            <StackPanel Orientation="Horizontal">
                <CheckBox x:Name="SilentMode" Content="🔇 Installation silencieuse" 
                          Margin="0,0,20,10" IsChecked="True" FontWeight="SemiBold"/>
                <TextBlock x:Name="CountLabel" Text="0 logiciel(s) disponible(s)" 
                           VerticalAlignment="Center" Opacity="0.7"/>
            </StackPanel>
        </StackPanel>
        
        <!-- Liste des logiciels -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="10,0">
            <StackPanel x:Name="MainPanel" />
        </ScrollViewer>
        
        <!-- Zone de logs -->
        <Grid Grid.Row="2" Margin="10">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="📋 Journal d'installation :" FontWeight="Bold" Margin="5,0,0,5"/>
            <Border Grid.Row="1" BorderBrush="#555" BorderThickness="1" CornerRadius="3">
                <TextBox x:Name="LogBox" Background="#252526" Foreground="White"
                         FontFamily="Consolas" FontSize="11" IsReadOnly="True"
                         VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                         Padding="8" TextWrapping="Wrap"/>
            </Border>
        </Grid>
        
        <!-- Boutons d'action -->
        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Center" Margin="10">
            <Button x:Name="SelectAllBtn" Content="☑️ Tout sélectionner" 
                    Margin="5" Padding="10,5" Background="#4A4A4A" Foreground="White"
                    BorderBrush="#666" FontWeight="SemiBold"/>
            <Button x:Name="ClearBtn" Content="☐ Tout désélectionner" 
                    Margin="5" Padding="10,5" Background="#4A4A4A" Foreground="White"
                    BorderBrush="#666" FontWeight="SemiBold"/>
            <Button x:Name="InstallBtn" Content="🚀 Installer la sélection" 
                    Margin="5" Padding="15,8" Background="#007ACC" Foreground="White"
                    BorderBrush="#0078D4" FontWeight="Bold" FontSize="14"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Chargement de l'interface
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Récupération des contrôles
$mainPanel    = $window.FindName("MainPanel")
$logBox       = $window.FindName("LogBox")
$searchBox    = $window.FindName("SearchBox")
$silentCheck  = $window.FindName("SilentMode")
$countLabel   = $window.FindName("CountLabel")
$selectAllBtn = $window.FindName("SelectAllBtn")
$clearBtn     = $window.FindName("ClearBtn")
$installBtn   = $window.FindName("InstallBtn")

# Variables globales
$checkboxes = @()
$logFile = @()
$logPath = "$env:TEMP\WinGet_Install_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Fonction pour loguer avec couleurs et horodatage
function Write-Log {
    param (
        [string]$message,
        [string]$type = "INFO" # INFO, SUCCESS, ERROR, WARNING
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $emoji = switch ($type) {
        "SUCCESS" { "✅" }
        "ERROR"   { "❌" }
        "WARNING" { "⚠️" }
        default   { "ℹ️" }
    }
    
    $formattedMessage = "[$timestamp] $emoji $message"
    $logBox.AppendText("$formattedMessage`n")
    $logBox.ScrollToEnd()
    $logFile += $formattedMessage
    
    # Mise à jour de l'interface
    [System.Windows.Forms.Application]::DoEvents()
}

# Fonction pour créer les cases à cocher par catégorie
function New-CategoryControls {
    $mainPanel.Children.Clear()
    $script:checkboxes = @()
    $totalCount = 0

    $sortedCategories = $logiciels.Keys | Sort-Object
    
    foreach ($category in $sortedCategories) {
        # Créer le GroupBox pour chaque catégorie
        $groupBox = New-Object Windows.Controls.GroupBox
        $groupBox.Header = "📁 $category"
        $groupBox.Foreground = "#E0E0E0"
        $groupBox.Margin = '5,5,5,10'
        $groupBox.FontWeight = "SemiBold"
        $groupBox.BorderBrush = "#555"
        
        $stackPanel = New-Object Windows.Controls.StackPanel
        $stackPanel.Margin = "10,5"
        
        $categoryHasVisibleItems = $false
        
        foreach ($software in ($logiciels[$category] | Sort-Object Nom)) {
            $searchText = $searchBox.Text.Trim()
            if (-not $searchText -or $software.Nom -like "*$searchText*") {
                $checkbox = New-Object Windows.Controls.CheckBox
                $checkbox.Content = $software.Nom
                $checkbox.Tag = $software.ID
                $checkbox.Foreground = "White"
                $checkbox.Margin = "5,3"
                $checkbox.FontSize = 13
                
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
    
    # Mettre à jour le compteur
    $countLabel.Text = "$totalCount logiciel(s) disponible(s)"
}

# Fonction d'installation des logiciels sélectionnés
function Start-SoftwareInstallation {
    $installBtn.IsEnabled = $false
    $selectedSoftware = $script:checkboxes | Where-Object { $_.IsChecked -eq $true }
    
    if (-not $selectedSoftware) {
        Write-Log "Aucun logiciel sélectionné pour l'installation." "WARNING"
        $installBtn.IsEnabled = $true
        return
    }
    
    Write-Log "Début de l'installation de $($selectedSoftware.Count) logiciel(s)..." "INFO"
    Write-Log "Mode silencieux: $($silentCheck.IsChecked)" "INFO"
    Write-Log "----------------------------------------" "INFO"
    
    $successCount = 0
    $errorCount = 0
    
    foreach ($checkbox in $selectedSoftware) {
        $softwareName = $checkbox.Content
        $softwareId = $checkbox.Tag
        
        Write-Log "Installation de '$softwareName' en cours..." "INFO"
        
        # Construction de la commande winget
        $wingetArgs = @("install", $softwareId, "--accept-source-agreements", "--accept-package-agreements")
        if ($silentCheck.IsChecked) {
            $wingetArgs += "--silent"
        }
        
        try {
            # Exécution de winget avec capture des erreurs
            $process = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\winget_out.txt" -RedirectStandardError "$env:TEMP\winget_err.txt"
            
            if ($process.ExitCode -eq 0) {
                Write-Log "'$softwareName' installé avec succès !" "SUCCESS"
                $successCount++
            } else {
                $errorOutput = if (Test-Path "$env:TEMP\winget_err.txt") { Get-Content "$env:TEMP\winget_err.txt" -Raw } else { "Erreur inconnue" }
                Write-Log "Échec de l'installation de '$softwareName' (Code: $($process.ExitCode))" "ERROR"
                if ($errorOutput) { Write-Log "Détail: $errorOutput" "ERROR" }
                $errorCount++
            }
        } catch {
            Write-Log "Erreur lors de l'installation de '$softwareName': $($_.Exception.Message)" "ERROR"
            $errorCount++
        }
        
        # Petite pause entre les installations
        Start-Sleep -Milliseconds 500
    }
    
    # Résumé final
    Write-Log "----------------------------------------" "INFO"
    Write-Log "Installation terminée !" "INFO"
    Write-Log "✅ Succès: $successCount | ❌ Échecs: $errorCount" "INFO"
    
    # Sauvegarde du fichier de log
    try {
        $logFile | Out-File -FilePath $logPath -Encoding UTF8
        Write-Log "📄 Log sauvegardé: $logPath" "SUCCESS"
    } catch {
        Write-Log "Erreur lors de la sauvegarde du log: $($_.Exception.Message)" "ERROR"
    }
    
    $installBtn.IsEnabled = $true
    
    # Nettoyage des fichiers temporaires
    Remove-Item "$env:TEMP\winget_out.txt" -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\winget_err.txt" -ErrorAction SilentlyContinue
}

# Gestionnaire d'événements pour la recherche
$searchBox.Add_TextChanged({
    New-CategoryControls
})

# Gestionnaire pour sélectionner tout
$selectAllBtn.Add_Click({
    foreach ($cb in $script:checkboxes) {
        $cb.IsChecked = $true
    }
    Write-Log "Tous les logiciels ont été sélectionnés." "INFO"
})

# Gestionnaire pour désélectionner tout
$clearBtn.Add_Click({
    foreach ($cb in $script:checkboxes) {
        $cb.IsChecked = $false
    }
    Write-Log "Toutes les sélections ont été effacées." "INFO"
})

# Gestionnaire pour le bouton d'installation
$installBtn.Add_Click({
    Start-SoftwareInstallation
})

# Gestionnaire de fermeture de fenêtre
$window.Add_Closing({
    if ($logFile.Count -gt 0 -and (Test-Path $logPath)) {
        $result = [System.Windows.MessageBox]::Show("Un fichier de log a été créé.`nVoulez-vous l'ouvrir ?", "Log disponible", 'YesNo', 'Question')
        if ($result -eq 'Yes') {
            Start-Process notepad.exe -ArgumentList $logPath
        }
    }
})

# Initialisation de l'interface
Write-Log "Application d'installation WinGet initialisée." "SUCCESS"
Write-Log "CSV chargé avec $($logicielsCSV.Count) logiciels dans $($logiciels.Keys.Count) catégories." "INFO"
New-CategoryControls

# Affichage de la fenêtre
$window.ShowDialog() | Out-Null