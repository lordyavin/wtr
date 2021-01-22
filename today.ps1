MIT License

Copyright (c) 2020 lordyavin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

# Simple powershell script to determine the working time based on the Windows logon and logoff events.

param (
    [switch]$v = $false
)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
    exit;
}

$target = New-TimeSpan -Hour 6
$now = Get-Date
$midnight = Get-Date -Hour 0 -Minute 0 -Second 0;
$logon_logoff = 7001,7002
$lock_unlock = 4800,4801
$enter_events = 7001,4801
$leave_events = 7002,4800

# Get events
$syslogs = Get-EventLog System -InstanceId $logon_logoff -After $midnight
$seclogs = Get-EventLog Security -InstanceId $lock_unlock -After $midnight
$logs = @($syslogs) + $seclogs
$logs = $logs | Sort-Object -Property TimeWritten -Descending

$leave = $now
$entered

$working = 0
$pause = 0

#for each event in descending time order (latest first)
ForEach ($log in $logs) {
	if($log.instanceid -in $enter_events) {
		$entered = $log.TimeWritten
		$working += $leave - $entered
		if($v) {
			Write-Output "leave  $leave"
			Write-Output "entered $entered"
		}
	}
	elseif($log.instanceid -in $leave_events) {
		$leave = $log.TimeWritten		
		$pause_ = $entered - $leave
		if($v) {
			Write-Output "Pause $pause_"
		}
		$pause += $pause_ 
	}	
}
$format = "{0:hh\:mm}"
$remaining = $target - $working
$remaining = $format -f $remaining
$date = $entered.ToString("dd.MM.yyyy")
$entered = $entered.ToString("HH:mm")
$endofwork = $now.ToString("HH:mm")
$working = $format -f $working
$pause = $format -f $pause
if($v) {
	Write-Output "--------------------------"
}
Write-Output "Date         : $date"
Write-Output "Entered      : $entered"
Write-Output "Leaving (now): $endofwork"
Write-Output "Working      : $working"
Write-Output "Break        : $pause"
Write-Output "--------------------"
Write-Output "Remaining    : $remaining"
