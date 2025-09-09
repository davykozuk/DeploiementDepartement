Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Configuration
$outputPath = ".\logiciels.xml"
$logPath = "$env:TEMP\XMLGenerator_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Interface WPF moderne
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="🔧 Générateur de Configuration XML - WinGet Manager"
        Height="900" Width="1200" MinHeight="700" MinWidth="1000"
        WindowStartupLocation="CenterScreen"
        Background="White"
        FontFamily="Segoe UI">
    
    <Window.Resources>
        <Style x:Key="ModernButton" TargetType="Button">
            <Setter Property="Background" Value="#4CAF50"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Margin" Value="3"/>
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
                                <Setter Property="Opacity" Value="0.8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <Style x:Key="SearchButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
            <Setter Property="Background" Value="#2196F3"/>
        </Style>
        
        <Style x:Key="ActionButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
            <Setter Property="Background" Value="#FF9800"/>
        </Style>
        
        <Style x:Key="CreateButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
            <Setter Property="Background" Value="#F44336"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="20,10"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="80"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="200"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                    <GradientStop Color="#FF9800" Offset="0"/>
                    <GradientStop Color="#FFB74D" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>
            
            <Grid Margin="20,0">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="🔧" FontSize="28" VerticalAlignment="Center" Margin="0,0,10,0"/>
                    <StackPanel>
                        <TextBlock Text="Générateur de Configuration XML" FontSize="22" FontWeight="Bold" Foreground="White"/>
                        <TextBlock x:Name="StatusText" Text="Prêt à créer votre configuration" FontSize="12" Foreground="#FFF3E0"/>
                    </StackPanel>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- Zone de recherche et catégories -->
        <Border Grid.Row="1" Background="#F5F5F5" Padding="15">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="200"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <!-- Recherche -->
                <StackPanel Grid.Column="0" Orientation="Horizontal">
                    <TextBlock Text="🔍" FontSize="16" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <TextBox x:Name="SearchBox" Width="300" Height="35" Padding="10,5"
                             FontSize="14" VerticalAlignment="Center"/>
                    <Button x:Name="SearchBtn" Content="🔍 Rechercher" Style="{StaticResource SearchButton}"
                            Height="35" Margin="10,0,0,0"/>
                </StackPanel>
                
                <!-- Gestion des catégories -->
                <StackPanel Grid.Column="1" Orientation="Vertical" Margin="10,0">
                    <TextBlock Text="📁 Catégorie :" FontSize="12" FontWeight="Bold"/>
                    <ComboBox x:Name="CategoryCombo" Height="25" Margin="0,3,0,0" IsEditable="True"/>
                    <Button x:Name="NewCategoryBtn" Content="➕ Nouvelle" Style="{StaticResource ModernButton}"
                            Height="25" FontSize="10" Margin="0,3,0,0"/>
                </StackPanel>
                
                <!-- Actions -->
                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button x:Name="AddSelectedBtn" Content="➕ Ajouter Sélection" 
                            Style="{StaticResource ActionButton}" Height="35" IsEnabled="False"/>
                    <Button x:Name="ClearSearchBtn" Content="🧹 Nettoyer" 
                            Style="{StaticResource ModernButton}" Background="#9E9E9E" Height="35"/>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- Zone principale avec résultats et configuration -->
        <Grid Grid.Row="2" Margin="10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            
            <!-- Résultats de recherche WinGet -->
            <Border Grid.Column="0" Background="White" CornerRadius="8" Margin="0,0,5,0" 
                    BorderBrush="#E0E0E0" BorderThickness="1">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
                        <TextBlock Text="📦 Résultats WinGet" FontSize="16" FontWeight="Bold" VerticalAlignment="Center"/>
                        <TextBlock x:Name="ResultCount" Text="" FontSize="12" Foreground="#666" 
                                   Margin="10,0,0,0" VerticalAlignment="Center"/>
                        <Button x:Name="SelectAllSearchBtn" Content="☑️ Tout" Style="{StaticResource ModernButton}"
                                Background="#4CAF50" FontSize="10" Height="20" Margin="10,0,0,0"/>
                        <Button x:Name="ClearAllSearchBtn" Content="☐ Rien" Style="{StaticResource ModernButton}"
                                Background="#F44336" FontSize="10" Height="20"/>
                    </StackPanel>
                    
                    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                        <StackPanel x:Name="SearchResults"/>
                    </ScrollViewer>
                </Grid>
            </Border>
            
            <!-- Configuration en cours -->
            <Border Grid.Column="1" Background="White" CornerRadius="8" Margin="5,0,0,0" 
                    BorderBrush="#E0E0E0" BorderThickness="1">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
                        <TextBlock Text="⚙️ Configuration XML" FontSize="16" FontWeight="Bold" VerticalAlignment="Center"/>
                        <TextBlock x:Name="ConfigCount" Text="(0 logiciels)" FontSize="12" Foreground="#666" 
                                   Margin="10,0,0,0" VerticalAlignment="Center"/>
                        <Button x:Name="ClearConfigBtn" Content="🗑️ Vider" Style="{StaticResource ModernButton}"
                                Background="#F44336" FontSize="10" Height="20" Margin="10,0,0,0"/>
                    </StackPanel>
                    
                    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                        <TreeView x:Name="ConfigTree" Background="Transparent"/>
                    </ScrollViewer>
                    
                    <Button Grid.Row="2" x:Name="CreateXmlBtn" Content="🚀 CRÉER FICHIER XML" 
                            Style="{StaticResource CreateButton}" Height="50" Margin="0,10,0,0"/>
                </Grid>
            </Border>
        </Grid>
        
        <!-- Zone de logs -->
        <Border Grid.Row="3" Background="#263238" CornerRadius="8" Margin="10">
            <Grid Margin="10">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                
                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,5">
                    <TextBlock Text="📋 Journal d'Activité" FontSize="14" FontWeight="Bold" 
                               Foreground="White" VerticalAlignment="Center"/>
                    <Button x:Name="ClearLogBtn" Content="🧹 Nettoyer" Style="{StaticResource ModernButton}"
                            Background="#607D8B" FontSize="10" Height="20" Margin="10,0,0,0"/>
                </StackPanel>
                
                <TextBox Grid.Row="1" x:Name="LogBox" 
                         Background="#37474F" Foreground="#E8F5E8" 
                         FontFamily="Consolas" FontSize="11"
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
$searchBox = $window.FindName("SearchBox")
$searchBtn = $window.FindName("SearchBtn")
$categoryCombo = $window.FindName("CategoryCombo")
$newCategoryBtn = $window.FindName("NewCategoryBtn")
$addSelectedBtn = $window.FindName("AddSelectedBtn")
$clearSearchBtn = $window.FindName("ClearSearchBtn")
$searchResults = $window.FindName("SearchResults")
$resultCount = $window.FindName("ResultCount")
$selectAllSearchBtn = $window.FindName("SelectAllSearchBtn")
$clearAllSearchBtn = $window.FindName("ClearAllSearchBtn")
$configTree = $window.FindName("ConfigTree")
$configCount = $window.FindName("ConfigCount")
$clearConfigBtn = $window.FindName("ClearConfigBtn")
$createXmlBtn = $window.FindName("CreateXmlBtn")
$logBox = $window.FindName("LogBox")
$clearLogBtn = $window.FindName("ClearLogBtn")
$statusText = $window.FindName("StatusText")

# Variables globales
$script:searchCheckboxes = @()
$script:configData = @{}  # Structure: Category -> Array of Software Objects
$script:logEntries = @()

# Fonction de logging
function Write-Log {
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
    
    # Mise à jour du statut
    switch ($Type) {
        "Success" { $statusText.Text = "✅ $Message" }
        "Error" { $statusText.Text = "❌ $Message" }
        "Warning" { $statusText.Text = "⚠️ $Message" }
        default { $statusText.Text = $Message }
    }
    
    [System.Windows.Forms.Application]::DoEvents()
}

# Initialisation des catégories par défaut
function Initialize-Categories {
    $defaultCategories = @("Navigateurs", "Développement", "Multimédia", "Productivité", "Utilitaires", "Jeux", "Communication")
    foreach ($cat in $defaultCategories) {
        $categoryCombo.Items.Add($cat)
    }
    $categoryCombo.SelectedIndex = 0
}

# Fonction de recherche WinGet
function Search-WinGetPackages {
    param([string]$SearchTerm)
    
    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        Write-Log "⚠️ Terme de recherche vide" -Type "Warning"
        return
    }
    
    Write-Log "🔍 Recherche WinGet : '$SearchTerm'..." -Type "Info"
    $searchBtn.IsEnabled = $false
    $searchBtn.Content = "⏳ Recherche..."
    
    try {
        # Exécution de winget search
        $wingetResults = winget search $SearchTerm --accept-source-agreements 2>$null | Out-String
        
        if (-not $wingetResults -or $wingetResults.Trim() -eq "") {
            Write-Log "❌ Aucun résultat trouvé pour '$SearchTerm'" -Type "Warning"
            return
        }
        
        # Parsing des résultats (format tabulaire de winget)
        $lines = $wingetResults -split "`n" | Where-Object { $_ -and $_.Trim() -ne "" }
        $packages = @()
        
        # Recherche de la ligne d'en-tête pour déterminer les colonnes
        $headerFound = $false
        foreach ($line in $lines) {
            if ($line -match "^Name\s+Id\s+Version\s+Match\s+Source" -or $line -match "^Nom\s+Id\s+Version") {
                $headerFound = $true
                continue
            }
            
            if ($headerFound -and $line -match "^-+" ) {
                continue  # Ligne de séparation
            }
            
            if ($headerFound -and $line.Trim() -ne "") {
                # Parsing de chaque ligne de résultat
                $parts = $line -split '\s{2,}' # Split sur 2+ espaces
                if ($parts.Count -ge 2) {
                    $packages += @{
                        Name = $parts[0].Trim()
                        Id = $parts[1].Trim()
                        Version = if ($parts.Count -gt 2) { $parts[2].Trim() } else { "N/A" }
                    }
                }
            }
        }
        
        Display-SearchResults -Packages $packages -SearchTerm $SearchTerm
        
    } catch {
        Write-Log "❌ Erreur lors de la recherche : $_" -Type "Error"
    } finally {
        $searchBtn.IsEnabled = $true
        $searchBtn.Content = "🔍 Rechercher"
    }
}

# Affichage des résultats de recherche
function Display-SearchResults {
    param(
        [array]$Packages,
        [string]$SearchTerm
    )
    
    $searchResults.Children.Clear()
    $script:searchCheckboxes = @()
    
    if ($Packages.Count -eq 0) {
        $noResults = New-Object System.Windows.Controls.TextBlock
        $noResults.Text = "❌ Aucun résultat pour '$SearchTerm'"
        $noResults.FontStyle = "Italic"
        $noResults.Foreground = "#999"
        $noResults.Margin = "10"
        $searchResults.Children.Add($noResults)
        $resultCount.Text = "(0 résultats)"
        return
    }
    
    Write-Log "✅ $($Packages.Count) résultats trouvés" -Type "Success"
    $resultCount.Text = "($($Packages.Count) résultats)"
    
    foreach ($package in $Packages) {
        # Container pour chaque résultat
        $border = New-Object System.Windows.Controls.Border
        $border.Background = "#F9F9F9"
        $border.BorderBrush = "#E0E0E0"
        $border.BorderThickness = 1
        $border.CornerRadius = 4
        $border.Margin = "0,2"
        $border.Padding = "8,6"
        
        $grid = New-Object System.Windows.Controls.Grid
        $col1 = New-Object System.Windows.Controls.ColumnDefinition
        $col1.Width = "Auto"
        $col2 = New-Object System.Windows.Controls.ColumnDefinition
        $col2.Width = "*"
        $grid.ColumnDefinitions.Add($col1)
        $grid.ColumnDefinitions.Add($col2)
        
        # CheckBox
        $checkbox = New-Object System.Windows.Controls.CheckBox
        $checkbox.VerticalAlignment = "Top"
        $checkbox.Margin = "0,0,8,0"
        $checkbox.Tag = @{
            Name = $package.Name
            Id = $package.Id
            Version = $package.Version
        }
        [System.Windows.Controls.Grid]::SetColumn($checkbox, 0)
        
        # Informations du package
        $infoPanel = New-Object System.Windows.Controls.StackPanel
        
        $nameText = New-Object System.Windows.Controls.TextBlock
        $nameText.Text = $package.Name
        $nameText.FontWeight = "Bold"
        $nameText.FontSize = 12
        $nameText.Foreground = "#1976D2"
        
        $idText = New-Object System.Windows.Controls.TextBlock
        $idText.Text = "ID: $($package.Id)"
        $idText.FontSize = 10
        $idText.Foreground = "#666"
        
        $versionText = New-Object System.Windows.Controls.TextBlock
        $versionText.Text = "Version: $($package.Version)"
        $versionText.FontSize = 10
        $versionText.Foreground = "#666"
        
        $infoPanel.Children.Add($nameText)
        $infoPanel.Children.Add($idText)
        $infoPanel.Children.Add($versionText)
        [System.Windows.Controls.Grid]::SetColumn($infoPanel, 1)
        
        $grid.Children.Add($checkbox)
        $grid.Children.Add($infoPanel)
        $border.Child = $grid
        
        $searchResults.Children.Add($border)
        $script:searchCheckboxes += $checkbox
        
        # Événement de sélection
        $checkbox.Add_Checked({ Update-AddButton })
        $checkbox.Add_Unchecked({ Update-AddButton })
    }
    
    Update-AddButton
}

# Mise à jour du bouton d'ajout
function Update-AddButton {
    $selectedCount = ($script:searchCheckboxes | Where-Object { $_.IsChecked -eq $true }).Count
    $addSelectedBtn.IsEnabled = $selectedCount -gt 0
    if ($selectedCount -gt 0) {
        $addSelectedBtn.Content = "➕ Ajouter ($selectedCount)"
    } else {
        $addSelectedBtn.Content = "➕ Ajouter Sélection"
    }
}

# Ajout des logiciels sélectionnés à la configuration
function Add-SelectedToConfig {
    $selectedPackages = $script:searchCheckboxes | Where-Object { $_.IsChecked -eq $true }
    $category = $categoryCombo.Text.Trim()
    
    if ([string]::IsNullOrWhiteSpace($category)) {
        Write-Log "⚠️ Veuillez sélectionner une catégorie" -Type "Warning"
        return
    }
    
    if ($selectedPackages.Count -eq 0) {
        Write-Log "⚠️ Aucun logiciel sélectionné" -Type "Warning"
        return
    }
    
    # Initialiser la catégorie si nécessaire
    if (-not $script:configData.ContainsKey($category)) {
        $script:configData[$category] = @()
    }
    
    $addedCount = 0
    foreach ($checkbox in $selectedPackages) {
        $package = $checkbox.Tag
        
        # Vérifier si déjà présent
        $exists = $script:configData[$category] | Where-Object { $_.Id -eq $package.Id }
        if (-not $exists) {
            $script:configData[$category] += @{
                Name = $package.Name
                Id = $package.Id
                Version = $package.Version
            }
            $addedCount++
        }
    }
    
    if ($addedCount -gt 0) {
        Write-Log "✅ $addedCount logiciel(s) ajouté(s) à la catégorie '$category'" -Type "Success"
        Update-ConfigTree
        
        # Décocher les éléments ajoutés
        $selectedPackages | ForEach-Object { $_.IsChecked = $false }
        Update-AddButton
    } else {
        Write-Log "⚠️ Tous les logiciels sélectionnés sont déjà présents" -Type "Warning"
    }
}

# Mise à jour de l'arbre de configuration
function Update-ConfigTree {
    $configTree.Items.Clear()
    $totalCount = 0
    
    foreach ($category in $script:configData.Keys | Sort-Object) {
        $categoryItem = New-Object System.Windows.Controls.TreeViewItem
        $categoryItem.Header = "📁 $category ($($script:configData[$category].Count) logiciels)"
        $categoryItem.FontWeight = "Bold"
        $categoryItem.Foreground = "#1976D2"
        $categoryItem.IsExpanded = $true
        
        foreach ($software in $script:configData[$category]) {
            $softwareItem = New-Object System.Windows.Controls.TreeViewItem
            $softwareItem.Header = "📦 $($software.Name) [$($software.Id)]"
            $softwareItem.FontSize = 11
            $categoryItem.Items.Add($softwareItem)
            $totalCount++
        }
        
        $configTree.Items.Add($categoryItem)
    }
    
    $configCount.Text = "($totalCount logiciels)"
    $createXmlBtn.IsEnabled = $totalCount -gt 0
}

# Création du fichier XML
function Create-XmlConfig {
    if ($script:configData.Count -eq 0) {
        Write-Log "⚠️ Aucune configuration à exporter" -Type "Warning"
        return
    }
    
    Write-Log "🚀 Création du fichier XML..." -Type "Info"
    
    try {
        # Création du document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDoc.AppendChild($xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null))
        
        $rootNode = $xmlDoc.CreateElement("logiciels")
        $xmlDoc.AppendChild($rootNode)
        
        foreach ($category in $script:configData.Keys | Sort-Object) {
            $categoryNode = $xmlDoc.CreateElement("categorie")
            $categoryNode.SetAttribute("nom", $category)
            
            foreach ($software in $script:configData[$category]) {
                $softwareNode = $xmlDoc.CreateElement("logiciel")
                $softwareNode.SetAttribute("nom", $software.Name)
                $softwareNode.SetAttribute("id", $software.Id)
                $categoryNode.AppendChild($softwareNode)
            }
            
            $rootNode.AppendChild($categoryNode)
        }
        
        # Sauvegarde avec formatage
        $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
        $xmlWriterSettings.Indent = $true
        $xmlWriterSettings.IndentChars = "  "
        $xmlWriterSettings.NewLineChars = "`r`n"
        $xmlWriterSettings.Encoding = [System.Text.Encoding]::UTF8
        
        $xmlWriter = [System.Xml.XmlWriter]::Create($outputPath, $xmlWriterSettings)
        $xmlDoc.Save($xmlWriter)
        $xmlWriter.Close()
        
        $totalSoftware = ($script:configData.Values | Measure-Object -Property Count -Sum).Sum
        Write-Log "✅ Fichier XML créé : $outputPath" -Type "Success"
        Write-Log "📊 $($script:configData.Count) catégories, $totalSoftware logiciels" -Type "Info"
        
        # Proposer d'ouvrir le fichier
        $result = [System.Windows.MessageBox]::Show(
            "✅ Fichier XML créé avec succès !`n`n📁 Emplacement : $outputPath`n📊 Contenu : $($script:configData.Count) catégories, $totalSoftware logiciels`n`nVoulez-vous ouvrir le fichier ?",
            "Configuration XML Créée",
            'YesNo',
            'Information'
        )
        
        if ($result -eq 'Yes') {
            Start-Process "notepad.exe" -ArgumentList $outputPath
        }
        
    } catch {
        Write-Log "❌ Erreur création XML : $_" -Type "Error"
    }
}

# Gestionnaires d'événements
$searchBtn.Add_Click({ Search-WinGetPackages -SearchTerm $searchBox.Text })

$searchBox.Add_KeyDown({
    if ($_.Key -eq "Return") {
        Search-WinGetPackages -SearchTerm $searchBox.Text
    }
})

$newCategoryBtn.Add_Click({
    $newCategory = [Microsoft.VisualBasic.Interaction]::InputBox("Nom de la nouvelle catégorie :", "Nouvelle Catégorie", "")
    if (-not [string]::IsNullOrWhiteSpace($newCategory)) {
        if ($categoryCombo.Items -notcontains $newCategory) {
            $categoryCombo.Items.Add($newCategory)
            $categoryCombo.SelectedItem = $newCategory
            Write-Log "✅ Catégorie '$newCategory' créée" -Type "Success"
        } else {
            Write-Log "⚠️ Catégorie '$newCategory' existe déjà" -Type "Warning"
        }
    }
})

$addSelectedBtn.Add_Click({ Add-SelectedToConfig })

$clearSearchBtn.Add_Click({
    $searchResults.Children.Clear()
    $script:searchCheckboxes = @()
    $resultCount.Text = ""
    $addSelectedBtn.IsEnabled = $false
    Write-Log "🧹 Résultats de recherche nettoyés" -Type "Info"
})

$selectAllSearchBtn.Add_Click({
    $script:searchCheckboxes | ForEach-Object { $_.IsChecked = $true }
})

$clearAllSearchBtn.Add_Click({
    $script:searchCheckboxes | ForEach-Object { $_.IsChecked = $false }
})

$clearConfigBtn.Add_Click({
    $result = [System.Windows.MessageBox]::Show("⚠️ Êtes-vous sûr de vouloir vider toute la configuration ?", "Confirmation", 'YesNo', 'Question')
    if ($result -eq 'Yes') {
        $script:configData = @{}
        Update-ConfigTree
        Write-Log "🗑️ Configuration vidée" -Type "Warning"
    }
})

$createXmlBtn.Add_Click({ Create-XmlConfig })

$clearLogBtn.Add_Click({
    $logBox.Clear()
    $script:logEntries = @()
})

# Ajout de l'assembly pour InputBox
Add-Type -AssemblyName Microsoft.VisualBasic

# Initialisation
Initialize-Categories
Write-Log "🎯 Générateur XML prêt ! Recherchez des logiciels et créez votre configuration." -Type "Info"

# Affichage de la fenêtre
$window.ShowDialog()