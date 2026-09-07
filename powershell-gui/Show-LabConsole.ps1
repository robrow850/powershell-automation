#requires -Version 7.2
<# .SYNOPSIS
Windows-only WPF console with an asynchronous runspace against fictional users.
No network calls, credentials, or account changes. Run with pwsh -STA.
#>
if(-not $IsWindows){throw 'WPF requires Windows; this project cannot run on macOS.'}
if([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA'){throw 'Start with pwsh -STA -File Show-LabConsole.ps1'}
Add-Type -AssemblyName PresentationFramework
[xml]$xaml=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Sample Administration Console" Width="650" Height="430">
<DockPanel Margin="20"><TextBlock DockPanel.Dock="Top" Text="Fictional user inventory — no tenant connection" Margin="0,0,0,12"/>
<Button Name="Refresh" DockPanel.Dock="Top" Content="Load sample users" Margin="0,0,0,12" Height="35"/>
<TextBlock Name="Status" DockPanel.Dock="Bottom" Text="Ready" Margin="0,12,0,0"/>
<DataGrid Name="Results" IsReadOnly="True" AutoGenerateColumns="True"/></DockPanel></Window>
'@
$window=[Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($xaml))
$button=$window.FindName('Refresh'); $grid=$window.FindName('Results'); $status=$window.FindName('Status')
$state=@{worker=$null;handle=$null}
$timer=[Windows.Threading.DispatcherTimer]::new();$timer.Interval=[TimeSpan]::FromMilliseconds(100)
$button.Add_Click({
    $button.IsEnabled=$false;$status.Text='Loading fictional users...'
    $state.worker=[PowerShell]::Create()
    $null=$state.worker.AddScript('Start-Sleep -Milliseconds 500; [pscustomobject]@{Name="Sample User"; Enabled=$true}; [pscustomobject]@{Name="Sample Disabled"; Enabled=$false}')
    $state.handle=$state.worker.BeginInvoke();$timer.Start()
})
$timer.Add_Tick({
    if($state.handle.IsCompleted){
        $timer.Stop()
        try{$grid.ItemsSource=@($state.worker.EndInvoke($state.handle));$status.Text='Loaded fictional sample'}
        catch{$status.Text='Sample load failed'}
        finally{$state.worker.Dispose();$state.worker=$null;$button.IsEnabled=$true}
    }
})
$window.Add_Closed({$timer.Stop();if($state.worker){$state.worker.Stop();$state.worker.Dispose()}})
$null=$window.ShowDialog()
