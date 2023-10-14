# this version of this file is only for familiarization
# download instead a release package to get this file with comments and undeleted helpful code junk


$priority_level_id___low = 64
$priority_level_id___below_normal = 16384
$priority_level_id___normal = 32
$priority_level_id___above_normal = 32768
$priority_level_id___high = 128
$priority_level_id___realtime = 256


function SetPriorityForOnlyUniqueProcess
{
param
(
	[Parameter(Mandatory)] [int]$pid_,
	[Parameter(Mandatory)] [int]$priority_level_id
)

	$FN = $PSCmdlet.MyInvocation.MyCommand.Name

	$proc_name = Get-Process -Id $pid_ | Select -Expand ProcessName
	$processes = Get-Process -ProcessName $proc_name
	if ($processes.Count -ne 1)
	{
		Write-Host "$($FN): not allowing to change the priority when the number of processes with this name is more than 1"
		return
	}

	$filter = "ProcessId=$pid_"
	$cim_processes = Get-CimInstance Win32_Process -Filter $filter
	$num = ($cim_processes | Measure-Object).count
	if ($num -ne 1)
	{
		throw
	}
	$cim_process = $cim_processes[0]
	Start-Sleep -Seconds 1
	$cim_process | Invoke-CimMethod -Name SetPriority -Arguments @{Priority=$priority_level_id} | Out-Null
}

function WatchProcessPriority
{
param ([Parameter(Mandatory)] [int]$pid_)

	$priority_level_id = $priority_level_id___above_normal

	"WatchProcessPriority " + $pid_

	$processes = Get-Process -Id $pid_
	$num = $processes.count
	if ($num -ne 1)
	{
		return
	}
	$process = $processes[0]
	while (1)
	{
		if ($process.HasExited)
		{
			break
		}
		$process.Refresh()
		if ($process.PriorityClass -eq "Normal")
		{
			$process.PriorityClass = "AboveNormal"
		}
		Start-Sleep -Seconds 1
		Write-Host 'ping'
	}

	Write-Host 'exiting the priority watching loop'
}

Write-Verbose -Verbose "Monitoring for new processes; press Ctrl-C to exit..."
try
{
	$query = '
	SELECT TargetInstance FROM __InstanceCreationEvent 
	WITHIN 1 WHERE 
	TargetInstance ISA "Win32_Process"
	'

	Register-CimIndicationEvent -ErrorAction Stop -Query $query -SourceIdentifier ProcessStarted

	while (1)
	{
		($e = Wait-Event -SourceIdentifier ProcessStarted) | Remove-Event
		$proc_id = $e.SourceEventArgs.NewEvent.TargetInstance.Handle
		$proc_name = ""
		try
		{
			$proc_name = Get-Process -Id $proc_id -ErrorAction stop | Select -Expand ProcessName -ErrorAction stop
		}
		catch
		{
			continue
		}

		if ($proc_name -eq 'Audacious')
		{
			SetPriorityForOnlyUniqueProcess -pid $proc_id -priority_level_id $priority_level_id___realtime
		}
		if ($proc_name -eq 'Winamp')
		{
			SetPriorityForOnlyUniqueProcess -pid $proc_id -priority_level_id $priority_level_id___realtime
		}
		if ($proc_name -eq 'vlc')
		{
			SetPriorityForOnlyUniqueProcess -pid $proc_id -priority_level_id $priority_level_id___realtime
		}
	}
}
finally
{
  UnRegister-Event ProcessStarted
}

