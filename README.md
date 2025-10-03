# Windows Performance Diagnostics Script
An experimental PowerShell script for diagnosing slow computer performance by collecting and analyzing system metrics.

# Overview
This script was created as an experiment to identify possible reasons for a 'slow computer'. It collects key performance indicators that can help determine what might be causing performance issues on a Windows system.
# Background
Windows provides several built-in diagnostic tools (Event Viewer, Performance Monitor, Resource Monitor, Task Manager, etc.) that can help determine why a computer was running slowly. This script aims to complement those tools by:

Aggregating critical metrics in a single snapshot
Providing quick diagnostics without navigating multiple Windows tools
Detecting bottlenecks automatically with threshold-based alerts
Creating shareable reports for troubleshooting or documentation
Measuring its own performance to ensure minimal system impact

This script was developed collaboratively using AI assistants (Gemini, ChatGPT, Claude, and Copilot) as an experimental approach to system diagnostics.
# Features
This script provides a comprehensive real-time performance snapshot:

# Performance Metrics

CPU Load - Current processor utilization percentage
Processor Queue Length - Identifies CPU bottlenecks (values > 2 indicate issues)
Memory Statistics - Available RAM and commit charge percentage
Disk Performance - Active time percentage and queue length to detect I/O bottlenecks
Network Usage - Real-time bandwidth consumption (sent/received) per interface
Network Health - Adapter status and latency testing (ping to 8.8.8.8)

# Process Analysis

Top 10 CPU Consumers - Processes using the most CPU resources
Top 10 Memory Consumers - Individual processes by working set
Aggregated Memory Usage - Total memory consumption grouped by process name (useful for multi-instance processes)

# Smart Diagnostics

Automated Bottleneck Detection - Alerts for:

High CPU load (>85%)
CPU queue bottlenecks
Low available RAM (<500 MB)
High commit charge (>85%)
Disk I/O bottlenecks (>80% active time or queue >2)
High network throughput
Disconnected network adapters
High latency (>100ms)



Performance Tracking

Section Timings - Shows how long each diagnostic component takes to run
Hardware Summary - CPU model, core count, total RAM
Disk Space Summary - Used and free space on all drives
Report Generation - Saves results to timestamped text file

# Requirements

Windows 10/11 or Windows Server 2016+
PowerShell 5.1 or higher
Administrator privileges (required for full performance counter access)
Network connectivity (optional - only needed for ping test to 8.8.8.8)

# Usage

Clone or download this repository
Open PowerShell as Administrator (required for full performance counter access)
Navigate to the script directory
Run the script:

powershell.\SystemDiagnostic.ps1
The script will:

Display a comprehensive diagnostic report in the console
Save the report to a timestamped file: SystemReport-[HOSTNAME]-[TIMESTAMP].txt
Complete in just a few seconds (typically 2-5 seconds depending on system)

Example Output
=== SYSTEM DIAGNOSTIC SNAPSHOT FOR DESKTOP-PC ===
Captured At : 10/03/2025 11:49:23 AM
------------------------------------------------------------------
Hardware Summary:
CPU Model       : Intel(R) Core(TM) i7-10700K CPU @ 3.80GHz
Total RAM       : 32 GB
------------------------------------------------------------------
Real-Time Performance Metrics (Snapshot):
CPU Load (%)            : 45.23%
Processor Queue         : 1 (Values > 2 indicate a CPU bottleneck)
Available RAM (MB)      : 8456
Commit Charge (%)       : 62.5% (High = heavy paging/RAM strain)
Disk Active Time (%)    : 15.4% (Values > 80% = Disk I/O bottleneck)
Disk Queue Length       : 0.2 (Values > 1-2 = Disk I/O bottleneck)
------------------------------------------------------------------
⚠️ Bottleneck Alerts:
None detected.
------------------------------------------------------------------
# Future Development
This script could evolve to include:

Historical Event Analysis - Automated parsing of Windows Event Viewer logs to identify past performance issues
Performance Monitor Integration - Analysis of perfmon data logs for trending over time
Scheduled Snapshots - Run diagnostics at intervals to capture performance patterns
HTML/CSV Export - Alternative report formats for easier analysis and sharing
Baseline Comparison - Compare current performance against established baseline metrics
Service Analysis - Identify problematic or resource-heavy Windows services
Startup Impact Analysis - Measure boot time and startup program impact
GPU Metrics - Add graphics card utilization for systems with dedicated GPUs
Temperature Monitoring - Track CPU/disk temperatures if sensors available
Automated Remediation Suggestions - Recommend specific actions based on detected issues

# Understanding the Output
# Key Metrics to Watch
Processor Queue Length: Values consistently above 2 suggest the CPU can't keep up with demand.
Commit Charge: High percentages (>85%) indicate the system is relying heavily on the page file, which is much slower than RAM.
Disk Active Time: Sustained values above 80% suggest the disk is a bottleneck. Consider upgrading to an SSD if using HDD.
Disk Queue Length: Values above 2 indicate I/O requests are backing up, causing slowdowns.
Network Latency: Ping times above 100ms may indicate connectivity issues affecting online performance.

# Common Bottleneck Patterns

Slow Application Launch: High disk active time + high disk queue
System Lag/Freezing: High CPU load + high processor queue
Tab Switching Delays: Low available RAM + high commit charge
Slow File Transfers: High network throughput or adapter issues
General Sluggishness: Multiple alerts firing simultaneously

# Limitations
Help Desk Considerations:
In Help Desk or corporate IT environments, there may be limitations to using this script:

Time constraints may not allow for running diagnostic scripts
Group Policy or security restrictions may prevent script execution
Administrative access may not be available
Built-in enterprise management tools may be preferred

# This script is best suited for:

Learning and experimentation
Personal system diagnostics
Small business IT environments
Situations where built-in Windows tools need supplementation

# Contributing
Contributions are welcome! If you have ideas for improvements or find bugs, please:

Fork the repository
Create a feature branch
Submit a pull request

# Disclaimer
This script is provided as-is for educational and diagnostic purposes. Always test in a non-production environment first. The author is not responsible for any system changes or issues that may arise from using this script.
Resources

Windows Event Viewer Documentation
PowerShell Documentation
Windows Performance Monitor
