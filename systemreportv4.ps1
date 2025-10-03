# 10/3/2025 11:49 AM
# System Performance Diagnostic Snapshot Script
# Developed with Gemini, ChatGPT, Claude, and Copilot
# Focuses on real-time metrics and top resource consumers
# Optimized for speed + embedded section timings + bottleneck alerts

# --- 1. Define Utility Functions ---

function Get-PerformanceMetrics {
    $Counters = @(
        '\Processor(_Total)\% Processor Time'
        '\System\Processor Queue Length'
        '\Memory\Available MBytes'
        '\Memory\% Committed Bytes In Use'
        '\PhysicalDisk(_Total)\% Disk Time'
        '\PhysicalDisk(_Total)\Avg. Disk Queue Length'
    )
    $PerformanceData = Get-Counter -Counter $Counters

    [PSCustomObject]@{
        Timestamp              = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        'CPU Load (%)'         = [math]::Round($PerformanceData.CounterSamples[0].CookedValue, 2)
        'Proc Queue'           = [math]::Round($PerformanceData.CounterSamples[1].CookedValue, 0)
        'Available RAM (MB)'   = [math]::Round($PerformanceData.CounterSamples[2].CookedValue, 0)
        'Commit Charge (%)'    = [math]::Round($PerformanceData.CounterSamples[3].CookedValue, 2)
        'Disk Active Time (%)' = [math]::Round($PerformanceData.CounterSamples[4].CookedValue, 2)
        'Disk Queue'           = [math]::Round($PerformanceData.CounterSamples[5].CookedValue, 2)
    }
}

function Get-TopProcessesByMemory {
    Get-Process |
        Group-Object ProcessName |
        ForEach-Object {
            $totalMemory = ($_.Group | Measure-Object WorkingSet64 -Sum).Sum
            [PSCustomObject]@{
                Name        = $_.Name
                'Instances' = $_.Count
                'Memory(MB)'= [math]::Round($totalMemory / 1MB, 2)
            }
        } | Sort-Object 'Memory(MB)' -Descending | Select-Object -First 10
}

function Get-NetworkUsage {
    $counters = @(
        '\Network Interface(*)\Bytes Sent/sec',
        '\Network Interface(*)\Bytes Received/sec'
    )
    $netData = Get-Counter -Counter $counters

    $grouped = $netData.CounterSamples |
        Group-Object { $_.Path.Split('\')[2] } |
        ForEach-Object {
            $iface = $_.Name
            $sent = ($_.Group | Where-Object { $_.Path -like "*Bytes Sent/sec*" }).CookedValue
            $recv = ($_.Group | Where-Object { $_.Path -like "*Bytes Received/sec*" }).CookedValue

            [PSCustomObject]@{
                Interface       = $iface
                'Sent (KB/sec)' = [math]::Round($sent / 1KB, 2)
                'Recv (KB/sec)' = [math]::Round($recv / 1KB, 2)
            }
        }

    return $grouped
}

function Get-NetworkHealth {
    $adapters = Get-NetAdapter | Select-Object Name, Status, LinkSpeed
    $ping = Test-Connection -ComputerName 8.8.8.8 -Count 2 -ErrorAction SilentlyContinue |
        Select-Object Address, ResponseTime

    return @{
        Adapters = $adapters
        Ping     = $ping
    }
}

function Get-AlertSummary($metrics, $networkStats, $networkHealth) {
    $alerts = @()

    if ($metrics.'CPU Load (%)' -gt 85) { $alerts += "⚠️ High CPU Load: $($metrics.'CPU Load (%)')%" }
    if ($metrics.'Proc Queue' -gt 2) { $alerts += "⚠️ Processor Queue Length > 2 (Possible CPU bottleneck)" }
    if ($metrics.'Available RAM (MB)' -lt 500) { $alerts += "⚠️ Low Available RAM: $($metrics.'Available RAM (MB)') MB" }
    if ($metrics.'Commit Charge (%)' -gt 85) { $alerts += "⚠️ High Commit Charge: $($metrics.'Commit Charge (%)')%" }
    if ($metrics.'Disk Active Time (%)' -gt 80) { $alerts += "⚠️ High Disk Active Time: $($metrics.'Disk Active Time (%)')%" }
    if ($metrics.'Disk Queue' -gt 2) { $alerts += "⚠️ High Disk Queue Length: $($metrics.'Disk Queue')" }

    foreach ($iface in $networkStats) {
        if ($iface.'Recv (KB/sec)' -gt 5000 -or $iface.'Sent (KB/sec)' -gt 5000) {
            $alerts += "⚠️ High Network Throughput on $($iface.Interface): Sent=$($iface.'Sent (KB/sec)') KB/s, Recv=$($iface.'Recv (KB/sec)') KB/s"
        }
    }

    foreach ($adapter in $networkHealth.Adapters) {
        if ($adapter.Status -ne 'Up') {
            $alerts += "⚠️ Network Adapter '$($adapter.Name)' is $($adapter.Status)"
        }
    }

    foreach ($ping in $networkHealth.Ping) {
        if ($ping.ResponseTime -gt 100) {
            $alerts += "⚠️ High Latency to $($ping.Address): $($ping.ResponseTime) ms"
        }
    }

    return $alerts
}

# --- 2. Main Script Execution ---

$startTime = Get-Date
$hostname  = $env:COMPUTERNAME

$timeCIM = Measure-Command {
    $cpuInfo = Get-CimInstance Win32_Processor -Property Name, NumberOfLogicalProcessors | Select-Object -First 1
    $sysInfo = Get-CimInstance Win32_ComputerSystem -Property TotalPhysicalMemory
}

$CPUModel  = $cpuInfo.Name
$TotalRAM  = [math]::Round($sysInfo.TotalPhysicalMemory / 1GB, 2)
$Cores     = $cpuInfo.NumberOfLogicalProcessors
$ReportPath = ".\SystemReport-$hostname-$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

$timeMetrics = Measure-Command {
    $Metrics = Get-PerformanceMetrics
}

$timeDisks = Measure-Command {
    $Disks = Get-PSDrive -PSProvider FileSystem |
        Select-Object Name,
            @{n="Used(GB)";e={[math]::Round($_.Used / 1GB, 2)}},
            @{n="Free(GB)";e={[math]::Round($_.Free / 1GB, 2)}}
}

$timeTopCPU = Measure-Command {
    $TopCPUProcesses = Get-Counter '\Process(*)\% Processor Time' |
        Select-Object -ExpandProperty CounterSamples |
        Where-Object { $_.InstanceName -notmatch '^(idle|_total|system)$' } |
        Sort-Object CookedValue -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            $Proc = Get-Process -Name $_.InstanceName -ErrorAction SilentlyContinue | Select-Object -First 1
            [PSCustomObject]@{
                'Name'       = $_.InstanceName
                'ID'         = $Proc.Id
                'CPU %'      = [Math]::Round(($_.CookedValue / $Cores), 2)
                'Memory(MB)' = [Math]::Round(($Proc.WorkingSet64 / 1MB), 2)
            }
        }
}

$timeTopRAM = Measure-Command {
    $TopRAMProcesses = Get-Process |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First 10 -Property ProcessName, Id,
            @{n='Memory(MB)';e={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
            @{n='CPU(s)';e={[math]::Round($_.CPU, 2)}}
}

$timeAgg = Measure-Command {
    $AggregatedMemoryProcesses = Get-TopProcessesByMemory
}

$timeNetwork = Measure-Command {
    $NetworkStats = Get-NetworkUsage
    $NetworkHealth = Get-NetworkHealth
}

$Alerts = Get-AlertSummary $Metrics $NetworkStats $NetworkHealth

# --- 3. Generate Report ---

$Report = @"
=== SYSTEM DIAGNOSTIC SNAPSHOT FOR $hostname ===
Captured At : $(Get-Date)
------------------------------------------------------------------
Hardware Summary:
CPU Model       : $CPUModel
Total RAM       : $TotalRAM GB
------------------------------------------------------------------
Real-Time Performance Metrics (Snapshot):
CPU Load (%)            : $($Metrics.'CPU Load (%)')%
Processor Queue         : $($Metrics.'Proc Queue') (Values > 2 indicate a CPU bottleneck)
Available RAM (MB)      : $($Metrics.'Available RAM (MB)')
Commit Charge (%)       : $($Metrics.'Commit Charge (%)')% (High = heavy paging/RAM strain)
Disk Active Time (%)    : $($Metrics.'Disk Active Time (%)')% (Values > 80% = Disk I/O bottleneck)
Disk Queue Length       : $($Metrics.'Disk Queue') (Values > 1-2 = Disk I/O bottleneck)
------------------------------------------------------------------
Disk Usage Summary:
$( $Disks | Format-Table -AutoSize | Out-String )
------------------------------------------------------------------
Top 10 Processes by CPU %:
$( $TopCPUProcesses | Format-Table -AutoSize | Out-String )
------------------------------------------------------------------
Top 10 Processes by Current RAM Usage (Working Set):
$( $TopRAMProcesses | Format-Table -AutoSize | Out-String )
------------------------------------------------------------------
Aggregated Memory Usage (Grouped by Process Name):
$( $AggregatedMemoryProcesses | Format-Table -AutoSize | Out-String )
------------------------------------------------------------------
Network Usage Snapshot (KB/sec):
$( $NetworkStats | Format-Table -AutoSize | Out-String )

Network Adapter Status:
$( $NetworkHealth.Adapters | Format-Table -AutoSize | Out-String )

Ping Test to 8.8.8.8 (Google DNS):
$( $NetworkHealth.Ping | Format-Table -AutoSize | Out-String )
Note: High latency or packet loss may indicate connectivity issues.
------------------------------------------------------------------
⚠️ Bottleneck Alerts:
$( if ($Alerts.Count -eq 0) { "None detected." } else { $Alerts -join "`n" } )
------------------------------------------------------------------
Section Timings (seconds):
CIM Queries                  : $($timeCIM.TotalSeconds)
Performance Counters         : $($timeMetrics.TotalSeconds)
Disk Usage Query             : $($timeDisks.TotalSeconds)
Top CPU Processes            : $($timeTopCPU.TotalSeconds)
Top RAM Processes            : $($timeTopRAM.TotalSeconds)
Aggregated Memory Grouping   : $($timeAgg.TotalSeconds)
Network Usage Query          : $($timeNetwork.TotalSeconds)
------------------------------------------------------------------
Script Duration: $((Get-Date) - $startTime).TotalSeconds seconds
Used to measure script efficiency
"@

# Output to console and file
$Report | Write-Host
$Report | Out-File $ReportPath -Encoding UTF8

Write-Host "`nReport saved to $ReportPath" -ForegroundColor Green