workflow StartStop-VM
{
    #---------------------------------------------------------------
    # Example:
    #       Virtual machine should have assigned below tag:
    #       tag: operatingHours
    #       value: 9:00;17:00;Mon-Tue-Wed-Thu-Fri-Sat-Sun;1;Auto
    #---------------------------------------------------------------

	#Input parameters
	param (
		# Time Zone parameter
		[Parameter(Mandatory=$true)]
		[string]$TimeZone = "GMT Standard Time"
	)

    # Get the connection "AzureRunAsConnection "
    $connectionName = "AzureRunAsConnection"
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    $Output = Add-AzureRmAccount `
                -ServicePrincipal `
                -TenantId $servicePrincipalConnection.TenantId `
                -ApplicationId $servicePrincipalConnection.ApplicationId `
                -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

    # Define static variables
    $Items = @()

    # Get all virtual machines with tag 'operatingHours'
    $VMs = Get-AzureRmVM | Where-Object {$_.Tags.Keys -match "operatingHours"}

    If ($VMs -ne "") 
    {
        # Create array with VM name, resource group name, start and stop time, days, priority 
        foreach ($VM in $VMs)
        {
                $operatingHoursTag = $VM.tags['operatingHours'] -split ";"
                If ($operatingHoursTag[4].ToLower() -eq "auto") {
                       $LineItem = New-Object -TypeName PSObject -Property @{
                           Name          = [string]$VM.Name
                           ResourceGroup = [string]$VM.ResourceGroupName
                           Start         = [string]$operatingHoursTag[0]
                           Stop          = [string]$operatingHoursTag[1]
                           Days          = [string]$operatingHoursTag[2]
                           Priority      = [string]$operatingHoursTag[3]
                        }
                       $Items += $LineItem
                }
        }

        if ($Items -ne "") {

            # Get current UTC time
            $currentTime = Get-Date
            write-output "Current Time in UTC: $currentTime"  
            write-output "Time zone: $TimeZone`n"

            Write-Output "Virtual machines to auto start/stop:"
            $Items | Select-Object Priority, ResourceGroup, Name, Start, Stop, Days 
            write-output "********************************************"          

            # Get all unique priorites values 
            $startPriorities = $Items | Sort-Object -Property Priority | Select-Object -Property Priority -Unique
            $stopPriorities  = $Items | Sort-Object -Property Priority -Descending | Select-Object -Property Priority -Unique

            # For each priority start in parallel all virtual machines with assigned certain priority
            foreach ($priority in $startPriorities) {
                $VMs = $Items | Where-Object {$_.Priority -eq $priority.Priority}
                foreach -parallel ($VM in $VMs) {
                    inlinescript 
                    {
                    # Function to convert UTC time to local time base on time zone
                     function Get-LocalTime {
                        param ($timeZone) 
                        $UTCTime = (Get-Date).ToUniversalTime()
                        $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($timeZone)
                        $localTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
                        return $localTime
                     }
                     # Define variables outside inlinescript
                     $VM = $Using:VM
                     $timeZone = $Using:TimeZone
                     try {
                            # Get latest virtual machine status
                            $vmStatus = (Get-AzureRmVM -Name $($VM.Name) -ResourceGroupName $($VM.ResourceGroup) -Status).Statuses[1].Code
                            [int]$VMStart = $($VM.Start).Replace(":","")
                            [int]$VMStop = $($VM.Stop).Replace(":","")
                            [int]$Time = $(Get-LocalTime($timeZone)).Hour.ToString() + $(Get-LocalTime($timeZone)).Minute.ToString()
                            $dayAbb = $(Get-LocalTime($timeZone)).DayOfWeek.ToString().SubString(0,3).ToLower()
                            $VMDays = $($($VM.Days).ToLower()).Split("-")
                            # Start virtual machine
                            if (($VMStart -le $Time) -and ($VMStop -gt $Time) -and ($VMDays -contains $dayAbb) -and ($vmStatus -ne "PowerState/running") -and ($vmStatus -ne "PowerState/starting") -and ($vmStatus -ne "PowerState/deallocating")) {
                                Write-Output "$(Get-LocalTime($timeZone)) - $($VM.Name) - Starting virtual machine"
                                $VMStartOutput = Start-AzureRmVM -Name $($VM.Name) -ResourceGroupName $($VM.ResourceGroup)
                                Write-Output "$(Get-LocalTime($timeZone)) - $($VM.Name) - Virtual machine started"
                            }
                            else {
                               Write-Output "$(Get-LocalTime($timeZone)) - $($VM.Name) - Virtual Machine doesn't meet requirements to start" 
                            }  
                         }
                     catch {
                           write-output "$(Get-LocalTime($timeZone)) - $($VM.Name) - Found error during virtual machine starting: $($_.Exception.Message)"
                     }
                   }
                }
            }

            # For each priority stop in parallel all virtual machines with assigned certain priority
            foreach ($priority in $stopPriorities) {
                $VMs = $Items | Where-Object {$_.Priority -eq $priority.Priority}
                foreach -parallel ($VM in $VMs) {
                    inlinescript 
                    {
                    # Function to convert UTC time to local time base on time zone                        
                     function Get-LocalTime {
                        param ($timeZone) 
                        $UTCTime = (Get-Date).ToUniversalTime()
                        $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($timeZone)
                        $localTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
                        return $localTime
                     }
                     # Define variables outside inlinescript
                     $VM = $Using:VM
                     $timeZone = $Using:TimeZone
                     try {
                        # Get latest virtual machine status
                        $vmStatus = (Get-AzureRmVM -Name $($VM.Name) -ResourceGroupName $($VM.ResourceGroup) -Status).Statuses[1].Code
                        [int]$VMStart = $($VM.Start).Replace(":","")
                        [int]$VMStop = $($VM.Stop).Replace(":","")
                        $dayAbb = $(Get-LocalTime($timeZone)).DayOfWeek.ToString().SubString(0,3).ToLower()   
                        [int]$Time = $(Get-LocalTime($timeZone)).Hour.ToString() + $(Get-LocalTime($timeZone)).Minute.ToString()                                            
                        $VMDays = $($($VM.Days).ToLower()).Split("-")
                        # Start virtual machine
                        if (($VMStop -le $Time) -and ($VMStart -le $Time) -and ($VMDays -contains $dayAbb) -and ($vmStatus -ne "PowerState/deallocated") -and ($vmStatus -ne "PowerState/starting") -and ($vmStatus -ne "PowerState/deallocating")) {
                            Write-Output "$(Get-LocalTime($timeZone)) - $($VM.Name) - Stopping virtual machine"
                            $VMStopOutput = Stop-AzureRmVM -Name $($VM.Name) -ResourceGroupName $($VM.ResourceGroup) -Force
                            Write-Output "$(Get-LocalTime($timeZone)) - $($VM.Name) - Virtual machine stopped"
                        }
                        else {
                            Write-Output "$(Get-LocalTime($timeZone)) - $($VM.Name) - Virtual Machine doesn't meet requirements to stop" 
                        }
                                               }
                     catch {
                           write-output "$(Get-LocalTime($timeZone)) - $($VM.Name) - Found error during virtual machine stopping: $($_.Exception.Message)"
                     }
                   }       
                }
            }
        }
    }
    else {
        Write-Output "Tag 'operatingHours' wasn't defined for any virtual machine"
    }   
}
