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

# Définition du XAML avec thème INFORSUD Technologies
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Distribution Logiciels ISTechnologies D.D. d.demaere@inforsud-technologies.com"
        Height="800" Width="650"
        WindowStartupLocation="CenterScreen"
        Background="White"
        FontFamily="Segoe UI"
        Foreground="#2C3E50"
        MinHeight="600" MinWidth="550">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="220"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- En-tête avec logo et titre -->
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
                    <TextBlock Text="INFORSUD Technologies" FontSize="20" FontWeight="Bold" 
                               Foreground="White" VerticalAlignment="Center"/>
                </StackPanel>
                <TextBlock Text="Distribution Logiciels - Département Déploiement" 
                           FontSize="14" Foreground="#E3F2FD" HorizontalAlignment="Center"
                           Margin="0,5,0,0"/>
            </StackPanel>
        </Border>
        
        <!-- Zone de recherche et options -->
        <Border Grid.Row="1" Background="#F5F5F5" Padding="20,15" BorderBrush="#E0E0E0" BorderThickness="0,0,0,1">
            <StackPanel>
                <TextBlock Text="🔍 Rechercher un logiciel :" Margin="0,0,0,8" FontWeight="SemiBold" 
                           Foreground="#37474F" FontSize="13"/>
                <TextBox x:Name="SearchBox" Height="35" Margin="0,0,0,12" 
                         Background="White" Foreground="#2C3E50" FontSize="14"
                         BorderBrush="#1976D2" BorderThickness="2" Padding="10,8"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <CheckBox x:Name="SilentMode" Content="🔇 Installation silencieuse" 
                              IsChecked="True" FontWeight="SemiBold" Foreground="#37474F" Grid.Column="0"/>
                    <TextBlock x:Name="CountLabel" Text="0 logiciel(s) disponible(s)" 
                               VerticalAlignment="Center" Foreground="#757575" FontStyle="Italic" Grid.Column="1"/>
                </Grid>
            </StackPanel>
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
                <TextBlock Text="📋 Journal d'installation" FontWeight="Bold" 
                           Foreground="#37474F" VerticalAlignment="Center"/>
                <Border Background="#1976D2" CornerRadius="10" Padding="8,2" Margin="10,0,0,0">
                    <TextBlock x:Name="StatusLabel" Text="Prêt" Foreground="White" 
                               FontSize="11" FontWeight="SemiBold"/>
                </Border>
            </StackPanel>
            <Border Grid.Row="1" BorderBrush="#D0D0D0" BorderThickness="1" CornerRadius="4" 
                    Background="White">
                <TextBox x:Name="LogBox" Background="White" Foreground="#2C3E50"
                         FontFamily="Consolas" FontSize="11" IsReadOnly="True"
                         VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                         Padding="12" TextWrapping="Wrap" BorderThickness="0"/>
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

# Chargement de l'interface avec gestion d'erreur
try {
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    [System.Windows.MessageBox]::Show("Erreur lors du chargement de l'interface:`n$($_.Exception.Message)","Erreur", 'OK', 'Error')
    return
}

# Récupération des contrôles
$mainPanel    = $window.FindName("MainPanel")
$logBox       = $window.FindName("LogBox")
$searchBox    = $window.FindName("SearchBox")
$silentCheck  = $window.FindName("SilentMode")
$countLabel   = $window.FindName("CountLabel")
$statusLabel  = $window.FindName("StatusLabel")
$selectAllBtn = $window.FindName("SelectAllBtn")
$clearBtn     = $window.FindName("ClearBtn")
$installBtn   = $window.FindName("InstallBtn")

# Variables globales
$checkboxes = @()
$logFile = @()
$logPath = "$env:TEMP\ISTech_Distribution_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

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
    
    # Mise à jour du statut
    switch ($type) {
        "SUCCESS" { $statusLabel.Text = "Succès" }
        "ERROR"   { $statusLabel.Text = "Erreur" }
        "WARNING" { $statusLabel.Text = "Attention" }
        default   { $statusLabel.Text = "En cours..." }
    }
    
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
        # Créer le GroupBox pour chaque catégorie avec style INFORSUD
        $groupBox = New-Object Windows.Controls.GroupBox
        $groupBox.Header = "📁 $category"
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
        
        foreach ($software in ($logiciels[$category] | Sort-Object Nom)) {
            $searchText = $searchBox.Text.Trim()
            if (-not $searchText -or $software.Nom -like "*$searchText*") {
                $checkbox = New-Object Windows.Controls.CheckBox
                $checkbox.Content = $software.Nom
                $checkbox.Tag = $software.ID
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
    
    # Mettre à jour le compteur
    $countLabel.Text = "$totalCount logiciel(s) disponible(s)"
}

# Fonction d'installation des logiciels sélectionnés
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
    
    Write-Log "=== INFORSUD Technologies - Début d'installation ===" "INFO"
    Write-Log "Nombre de logiciels à installer: $($selectedSoftware.Count)" "INFO"
    Write-Log "Mode silencieux: $($silentCheck.IsChecked)" "INFO"
    Write-Log "Utilisateur: $env:USERNAME | Machine: $env:COMPUTERNAME" "INFO"
    Write-Log "=================================================" "INFO"
    
    $successCount = 0
    $errorCount = 0
    
    foreach ($checkbox in $selectedSoftware) {
        $softwareName = $checkbox.Content
        $softwareId = $checkbox.Tag
        
        Write-Log "🔄 Installation de '$softwareName' en cours..." "INFO"
        
        # Construction de la commande winget
        $wingetArgs = @("install", $softwareId, "--accept-source-agreements", "--accept-package-agreements")
        if ($silentCheck.IsChecked) {
            $wingetArgs += "--silent"
        }
        
        try {
            # Exécution de winget avec capture des erreurs
            $process = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput "$env:TEMP\winget_out.txt" -RedirectStandardError "$env:TEMP\winget_err.txt"
            
            if ($process.ExitCode -eq 0) {
                Write-Log "✅ '$softwareName' installé avec succès !" "SUCCESS"
                $successCount++
            } else {
                $errorOutput = if (Test-Path "$env:TEMP\winget_err.txt") { Get-Content "$env:TEMP\winget_err.txt" -Raw } else { "Erreur inconnue" }
                Write-Log "❌ Échec installation '$softwareName' (Code: $($process.ExitCode))" "ERROR"
                if ($errorOutput) { Write-Log "   Détail: $errorOutput" "ERROR" }
                $errorCount++
            }
        } catch {
            Write-Log "❌ Erreur système '$softwareName': $($_.Exception.Message)" "ERROR"
            $errorCount++
        }
        
        # Petite pause entre les installations
        Start-Sleep -Milliseconds 800
    }
    
    # Résumé final
    Write-Log "=================================================" "INFO"
    Write-Log "🏁 INSTALLATION TERMINÉE - INFORSUD Technologies" "INFO"
    Write-Log "✅ Réussites: $successCount | ❌ Échecs: $errorCount" "INFO"
    Write-Log "💾 Taux de succès: $([math]::Round(($successCount/($successCount+$errorCount))*100,1))%" "INFO"
    
    # Sauvegarde du fichier de log
    try {
        $logHeader = @"
=== INFORSUD TECHNOLOGIES - LOG D'INSTALLATION ===
Date: $(Get-Date -Format 'dd/MM/yyyy à HH:mm:ss')
Utilisateur: $env:USERNAME
Machine: $env:COMPUTERNAME
Département: Déploiement Digital (D.D.)
===================================================

"@
        ($logHeader + ($logFile -join "`n")) | Out-File -FilePath $logPath -Encoding UTF8
        Write-Log "📄 Log technique sauvegardé: $logPath" "SUCCESS"
    } catch {
        Write-Log "❌ Erreur sauvegarde log: $($_.Exception.Message)" "ERROR"
    }
    
    $installBtn.IsEnabled = $true
    $statusLabel.Text = if ($errorCount -eq 0) { "Terminé ✅" } else { "Terminé avec erreurs ⚠️" }
    
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
    Write-Log "✅ Tous les logiciels sélectionnés par l'utilisateur." "INFO"
})

# Gestionnaire pour désélectionner tout
$clearBtn.Add_Click({
    foreach ($cb in $script:checkboxes) {
        $cb.IsChecked = $false
    }
    Write-Log "🔄 Toutes les sélections effacées." "INFO"
})

# Gestionnaire pour le bouton d'installation
$installBtn.Add_Click({
    Start-SoftwareInstallation
})

# Gestionnaire de fermeture de fenêtre
$window.Add_Closing({
    if ($logFile.Count -gt 0 -and (Test-Path $logPath)) {
        $result = [System.Windows.MessageBox]::Show("Un rapport d'installation a été généré par INFORSUD Technologies.`n`nVoulez-vous l'ouvrir pour vérification ?", "Rapport disponible", 'YesNo', 'Question')
        if ($result -eq 'Yes') {
            Start-Process notepad.exe -ArgumentList $logPath
        }
    }
})

# Initialisation de l'interface
$statusLabel.Text = "Initialisation..."
Write-Log "🏢 INFORSUD Technologies - Distribution Logiciels D.D." "SUCCESS"
Write-Log "📊 Base de données chargée: $($logicielsCSV.Count) logiciels dans $($logiciels.Keys.Count) catégories" "INFO"
Write-Log "👤 Session utilisateur: $env:USERNAME sur $env:COMPUTERNAME" "INFO"
Write-Log "🚀 Système prêt pour le déploiement logiciel" "SUCCESS"
New-CategoryControls
$statusLabel.Text = "Prêt"

# Affichage de la fenêtre
$window.ShowDialog() | Out-Null