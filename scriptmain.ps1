Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Configuration et chemins
$xmlPath = ".\logiciels.xml"
$logPath = "$env:TEMP\WinGet_Installer_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Vérification du fichier XML
if (-not (Test-Path $xmlPath)) {
    [System.Windows.MessageBox]::Show("❌ Fichier logiciels.xml introuvable !`n`nCréez le fichier avec la structure :`n<logiciels>`n  <categorie nom='Navigateurs'>`n    <logiciel nom='Chrome' id='Google.Chrome'/>`n  </categorie>`n</logiciels>", "Erreur Configuration", 'OK', 'Error')
    return
}

# Lecture du fichier XML
try {
    [xml]$configXML = Get-Content -Path $xmlPath -Encoding UTF8
    Write-Host "✅ Configuration XML chargée avec succès"
} catch {
    [System.Windows.MessageBox]::Show("❌ Erreur lecture XML :`n$($_.Exception.Message)", "Erreur XML", 'OK', 'Error')
    return
}

# Interface WPF moderne avec Material Design
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="🚀 Installateur Automatique - WinGet Enterprise"
        Height="800" Width="1100" MinHeight="600" MinWidth="800"
        WindowStartupLocation="CenterScreen"
        Background="White"
        FontFamily="Segoe UI"
        WindowState="Maximized">
    
    <Window.Resources>
        <Style x:Key="ModernButton" TargetType="Button">
            <Setter Property="Background" Value="#2196F3"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#1976D2"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <Style x:Key="ModernTextBox" TargetType="TextBox">
            <Setter Property="Background" Value="#F5F5F5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border Background="{TemplateBinding Background}" 
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ScrollViewer x:Name="PART_ContentHost"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <Style x:Key="CategoryHeader" TargetType="TextBlock">
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="#1976D2"/>
            <Setter Property="Margin" Value="0,15,0,8"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="80"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="250"/>
        </Grid.RowDefinitions>
        
        <!-- Header moderne avec dégradé -->
        <Border Grid.Row="0">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                    <GradientStop Color="#1976D2" Offset="0"/>
                    <GradientStop Color="#42A5F5" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>
            
            <Grid Margin="20,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="🚀" FontSize="28" VerticalAlignment="Center" Margin="0,0,10,0"/>
                    <StackPanel>
                        <TextBlock Text="Installateur de Logiciels" FontSize="22" FontWeight="Bold" Foreground="White"/>
                        <TextBlock x:Name="StatusText" Text="Prêt à déployer" FontSize="12" Foreground="#E3F2FD"/>
                    </StackPanel>
                </StackPanel>
                
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="🔍" FontSize="16" Foreground="White" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <TextBox x:Name="SearchBox" Style="{StaticResource ModernTextBox}"
                             Width="250" Height="35" VerticalAlignment="Center"
                             Text="Rechercher un logiciel..."/>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- Zone principale avec logiciels -->
        <Border Grid.Row="1" Background="White" Margin="10,10,10,5">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="200"/>
                </Grid.ColumnDefinitions>
                
                <!-- Liste des logiciels -->
                <ScrollViewer Grid.Column="0" VerticalScrollBarVisibility="Auto" Margin="10">
                    <StackPanel x:Name="SoftwarePanel"/>
                </ScrollViewer>
                
                <!-- Panneau de contrôle -->
                <Border Grid.Column="1" Background="#F8F9FA" CornerRadius="8" Margin="5" Padding="15">
                    <StackPanel>
                        <TextBlock Text="⚙️ Contrôles" Style="{StaticResource CategoryHeader}" HorizontalAlignment="Center"/>
                        
                        <CheckBox x:Name="SilentMode" Content="🔇 Installation silencieuse" 
                                  IsChecked="True" Margin="0,10" FontWeight="SemiBold"/>
                        
                        <Separator Margin="0,10"/>
                        
                        <TextBlock Text="📊 Sélection" FontWeight="Bold" Margin="0,0,0,8"/>
                        <TextBlock x:Name="CountLabel" Text="0 logiciel(s) sélectionné(s)" 
                                   FontSize="12" Foreground="#666" Margin="0,0,0,10"/>
                        
                        <Button x:Name="SelectAllBtn" Content="☑️ Tout sélectionner" 
                                Style="{StaticResource ModernButton}" Background="#4CAF50"/>
                        <Button x:Name="ClearBtn" Content="☐ Tout désélectionner" 
                                Style="{StaticResource ModernButton}" Background="#FF9800"/>
                        
                        <Separator Margin="0,15"/>
                        
                        <Button x:Name="InstallBtn" Content="🚀 LANCER L'INSTALLATION" 
                                Style="{StaticResource ModernButton}" Background="#F44336"
                                Height="45" FontSize="14" FontWeight="Bold"/>
                        
                        <Separator Margin="0,15"/>
                        
                        <TextBlock Text="📋 Actions" FontWeight="Bold" Margin="0,0,0,8"/>
                        <Button x:Name="RefreshBtn" Content="🔄 Actualiser" 
                                Style="{StaticResource ModernButton}" Background="#9E9E9E"/>
                        <Button x:Name="OpenLogBtn" Content="📄 Ouvrir les logs" 
                                Style="{StaticResource ModernButton}" Background="#607D8B"/>
                    </StackPanel>
                </Border>
            </Grid>
        </Border>
        
        <!-- Zone de logs avec onglets -->
        <Border Grid.Row="2" Background="#263238" Margin="10,5,10,10" CornerRadius="8">
            <Grid Margin="10">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                
                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,8">
                    <TextBlock Text="📋 Journal d'Installation" FontSize="14" FontWeight="Bold" 
                               Foreground="White" VerticalAlignment="Center"/>
                    <TextBlock x:Name="LogCount" Text="" FontSize="12" Foreground="#B0BEC5" 
                               Margin="10,0,0,0" VerticalAlignment="Center"/>
                </StackPanel>
                
                <TextBox Grid.Row="1" x:Name="LogBox" 
                         Background="#37474F" Foreground="#E8F5E8" 
                         FontFamily="Consolas" FontSize="12"
                         IsReadOnly="True" TextWrapping="Wrap"
                         VerticalScrollBarVisibility="Auto"
                         BorderThickness="0"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# Chargement de l'interface
try {
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Host "❌ Erreur chargement interface : $_" -ForegroundColor Red
    return
}

# Récupération des contrôles
$softwarePanel = $window.FindName("SoftwarePanel")
$logBox = $window.FindName("LogBox")
$searchBox = $window.FindName("SearchBox")
$silentCheck = $window.FindName("SilentMode")
$countLabel = $window.FindName("CountLabel")
$statusText = $window.FindName("StatusText")
$selectAllBtn = $window.FindName("SelectAllBtn")
$clearBtn = $window.FindName("ClearBtn")
$installBtn = $window.FindName("InstallBtn")
$refreshBtn = $window.FindName("RefreshBtn")
$openLogBtn = $window.FindName("OpenLogBtn")
$logCount = $window.FindName("LogCount")

# Variables globales
$script:allCheckboxes = @()
$script:logEntries = @()

# Fonction de logging avancée
function Write-InstallLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $emoji = @{
        "Info" = "ℹ️"
        "Success" = "✅"
        "Warning" = "⚠️"
        "Error" = "❌"
    }[$Type]
    
    $logEntry = "[$timestamp] $emoji $Message"
    $script:logEntries += $logEntry
    
    $logBox.AppendText("$logEntry`n")
    $logBox.ScrollToEnd()
    $logCount.Text = "($($script:logEntries.Count) entrées)"
    
    # Mise à jour du statut
    switch ($Type) {
        "Success" { $statusText.Text = "✅ $Message" }
        "Error" { $statusText.Text = "❌ Erreur détectée" }
        "Warning" { $statusText.Text = "⚠️ Attention requise" }
        default { $statusText.Text = $Message }
    }
    
    # Sauvegarde dans le fichier
    Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    
    [System.Windows.Forms.Application]::DoEvents()
}

# Fonction pour créer l'interface des logiciels
function Build-SoftwareInterface {
    $softwarePanel.Children.Clear()
    $script:allCheckboxes = @()
    
    Write-InstallLog "🔄 Construction de l'interface..." -Type "Info"
    
    foreach ($category in $configXML.logiciels.categorie) {
        # En-tête de catégorie avec design moderne
        $categoryHeader = New-Object System.Windows.Controls.Border
        $categoryHeader.Background = [System.Windows.Media.Brushes]::LightBlue
        $categoryHeader.CornerRadius = 6
        $categoryHeader.Padding = "12,8"
        $categoryHeader.Margin = "0,10,0,5"
        
        $headerText = New-Object System.Windows.Controls.TextBlock
        $headerText.Text = "📁 $($category.nom) ($($category.logiciel.Count) logiciels)"
        $headerText.FontWeight = "Bold"
        $headerText.FontSize = 16
        $headerText.Foreground = [System.Windows.Media.Brushes]::DarkBlue
        
        $categoryHeader.Child = $headerText
        $softwarePanel.Children.Add($categoryHeader)
        
        # Grille pour les logiciels de cette catégorie
        $grid = New-Object System.Windows.Controls.Grid
        $grid.Margin = "20,5,0,10"
        
        # Créer les colonnes (3 colonnes pour un affichage compact)
        for ($i = 0; $i -lt 3; $i++) {
            $column = New-Object System.Windows.Controls.ColumnDefinition
            $column.Width = "*"
            $grid.ColumnDefinitions.Add($column)
        }
        
        $row = 0
        $col = 0
        
        foreach ($software in $category.logiciel) {
            if ($col -eq 0) {
                # Nouvelle ligne
                $rowDef = New-Object System.Windows.Controls.RowDefinition
                $rowDef.Height = "Auto"
                $grid.RowDefinitions.Add($rowDef)
            }
            
            # CheckBox avec style moderne
            $checkbox = New-Object System.Windows.Controls.CheckBox
            $checkbox.Content = $software.nom
            $checkbox.Tag = $software.id
            $checkbox.Margin = "5"
            $checkbox.FontSize = 12
            $checkbox.FontWeight = "Normal"
            
            # Positionnement dans la grille
            [System.Windows.Controls.Grid]::SetRow($checkbox, $row)
            [System.Windows.Controls.Grid]::SetColumn($checkbox, $col)
            
            $grid.Children.Add($checkbox)
            $script:allCheckboxes += $checkbox
            
            # Gestion des événements
            $checkbox.Add_Checked({ Update-SelectionCount })
            $checkbox.Add_Unchecked({ Update-SelectionCount })
            
            $col++
            if ($col -eq 3) {
                $col = 0
                $row++
            }
        }
        
        $softwarePanel.Children.Add($grid)
    }
    
    Update-SelectionCount
    Write-InstallLog "✅ Interface construite avec $($script:allCheckboxes.Count) logiciels" -Type "Success"
}

# Fonction de mise à jour du compteur
function Update-SelectionCount {
    $selectedCount = ($script:allCheckboxes | Where-Object { $_.IsChecked -eq $true }).Count
    $countLabel.Text = "$selectedCount logiciel(s) sélectionné(s)"
    
    $installBtn.IsEnabled = $selectedCount -gt 0
    if ($selectedCount -gt 0) {
        $installBtn.Background = [System.Windows.Media.Brushes]::Red
        $installBtn.Content = "🚀 INSTALLER $selectedCount LOGICIEL(S)"
    } else {
        $installBtn.Background = [System.Windows.Media.Brushes]::Gray
        $installBtn.Content = "🚀 SÉLECTIONNER DES LOGICIELS"
    }
}

# Fonction de recherche en temps réel
function Filter-Software {
    param([string]$SearchTerm)
    
    foreach ($checkbox in $script:allCheckboxes) {
        $checkbox.Visibility = if ([string]::IsNullOrEmpty($SearchTerm) -or 
                                  $checkbox.Content -like "*$SearchTerm*") {
            "Visible"
        } else {
            "Collapsed"
        }
    }
}

# Fonction d'installation
function Start-Installation {
    $selectedSoftware = $script:allCheckboxes | Where-Object { $_.IsChecked -eq $true }
    
    if ($selectedSoftware.Count -eq 0) {
        [System.Windows.MessageBox]::Show("❌ Aucun logiciel sélectionné !", "Erreur", 'OK', 'Warning')
        return
    }
    
    $installBtn.IsEnabled = $false
    $installBtn.Content = "⏳ INSTALLATION EN COURS..."
    
    Write-InstallLog "🚀 Début de l'installation de $($selectedSoftware.Count) logiciel(s)" -Type "Info"
    
    $successCount = 0
    $errorCount = 0
    
    foreach ($software in $selectedSoftware) {
        $softwareName = $software.Content
        $softwareId = $software.Tag
        
        Write-InstallLog "📦 Installation de $softwareName ($softwareId)..." -Type "Info"
        
        try {
            $wingetArgs = @("install", "--id", $softwareId, "--exact", "--accept-package-agreements", "--accept-source-agreements")
            if ($silentCheck.IsChecked) {
                $wingetArgs += "--silent"
            }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -Wait -PassThru -NoNewWindow
            
            if ($process.ExitCode -eq 0) {
                Write-InstallLog "✅ $softwareName installé avec succès" -Type "Success"
                $successCount++
            } else {
                Write-InstallLog "❌ Échec installation de $softwareName (Code: $($process.ExitCode))" -Type "Error"
                $errorCount++
            }
        } catch {
            Write-InstallLog "❌ Erreur lors de l'installation de $softwareName : $_" -Type "Error"
            $errorCount++
        }
    }
    
    # Rapport final
    Write-InstallLog "📊 RAPPORT FINAL" -Type "Info"
    Write-InstallLog "✅ Succès : $successCount" -Type "Success"
    if ($errorCount -gt 0) {
        Write-InstallLog "❌ Erreurs : $errorCount" -Type "Error"
    }
    Write-InstallLog "📄 Log sauvegardé : $logPath" -Type "Info"
    
    $installBtn.IsEnabled = $true
    Update-SelectionCount
    
    # Notification finale
    $result = if ($errorCount -eq 0) { "Success" } else { "Warning" }
    Write-InstallLog "🎉 Installation terminée !" -Type $result
}

# Gestionnaires d'événements
$searchBox.Add_TextChanged({
    if ($searchBox.Text -eq "Rechercher un logiciel...") { return }
    Filter-Software -SearchTerm $searchBox.Text
})

$searchBox.Add_GotFocus({
    if ($searchBox.Text -eq "Rechercher un logiciel...") {
        $searchBox.Text = ""
        $searchBox.Foreground = "Black"
    }
})

$selectAllBtn.Add_Click({
    $script:allCheckboxes | Where-Object { $_.Visibility -eq "Visible" } | ForEach-Object { $_.IsChecked = $true }
})

$clearBtn.Add_Click({
    $script:allCheckboxes | ForEach-Object { $_.IsChecked = $false }
})

$installBtn.Add_Click({ Start-Installation })

$refreshBtn.Add_Click({ Build-SoftwareInterface })

$openLogBtn.Add_Click({
    if (Test-Path $logPath) {
        Start-Process "notepad.exe" -ArgumentList $logPath
    } else {
        [System.Windows.MessageBox]::Show("📄 Aucun fichier de log trouvé.", "Information", 'OK', 'Information')
    }
})

# Gestion de la fermeture
$window.Add_Closing({
    if ($script:logEntries.Count -gt 0) {
        Write-InstallLog "👋 Fermeture de l'application" -Type "Info"
    }
})

# Construction initiale et affichage
Build-SoftwareInterface
Write-InstallLog "🎯 Application prête ! Sélectionnez vos logiciels et cliquez sur Installer." -Type "Info"

$window.ShowDialog()