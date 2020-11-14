#Your list of servers
 $Servers = Get-Content 'C:\power\1.txt'
 $TodayDate = Get-Date
 $RPCFails = @()

#Get information from every server in your list, you can add more variables if you want more information about the remote systems.
foreach ( $server in $Servers ) {
    try { 
        $Sys = get-wmiobject Win32_ComputerSystem -ComputerName $server
        $osinfo= Get-WmiObject Win32_OperatingSystem -ComputerName $Server 
        $CPUAndMemory = get-wmiobject Win32_ComputerSystem -cn $server | select @{name="PhysicalMemory";Expression={"{0:N2}" -f($_.TotalPhysicalMemory/1gb).tostring("N0")}},NumberOfProcessors,Name
        $gb = ' GB'
        $mhz = ' MHZ'
        $Processor = get-wmiobject Win32_Processor -ComputerName $Server | Select-Object Name
        $Disk = get-wmiobject Win32_LogicalDisk -ComputerName $Server
        $Ip = gwmi Win32_NetworkAdapterConfiguration -ComputerName $Server | ? {$_.IPEnabled} 
        $lastboot= Get-WmiObject win32_OperatingSystem -computer $server | Select csname, @{label=’LastBootUTime’ ;expression={$_.ConvertToDateTime($_.LastBootUpTime)}}
        $Patch = Get-Hotfix -ComputerName $Server | Sort InstalledOn -Descending | select HotfixID, Description, InstalledOn, InstalledBy | Select -First 5 | out-string
        $service = Get-wmiobject win32_service -computername $server |where {$_.startmode -like 'Auto'}  | select Name, DisplayName, Status | out-string
        
       
        ##Creates a pscustom-object with the naming you want.
        $Object = [PScustomobject]  @{
        ServerName                       = $sys.Name
        Manufacturer                     = $sys.Manufacturer
        Domain                           = $sys.Domain
        OSVersion                        = $osinfo.Caption
        OSVersionNumber                  = $osinfo.Version
        OSBuild                          = $osinfo.BuildNumber
        IPv4Adress                       = $Ip.IPAddress | select -First 1
        CPUName                          = $Processor.Name | select -First 1
        NumberofCPUs                     = $CPUAndMemory.numberofprocessors
        NumberofCPUCores                 = $Processor.NumberOfCores.Count
        Memory                           = $CPUAndMemory.PhysicalMemory + $gb
        LogicalDisks                     = ($Disk | ? { $_.DriveType -eq 3 -and $_.Size -notlike $null } | % { "[{0}] {1}\ ({2}) = {3:N2} / {4:N2} GB ({5:N1}% Free)" -f $_.FileSystem, $_.DeviceID, $_.VolumeName, ($_.FreeSpace / 1GB), ($_.Size / 1GB), (($_.FreeSpace / $_.Size) * 100) } | Out-String).Trim()
        LastBoot                         = $lastboot.LastBootUTime                    
        TodaysDate                       = $TodayDate
        PowershellVersion                = $PSVersion
        LastInstalledPatches             = $Patch
        ServiceState                     = $service
      
        
               
    }

    #Shows your data
    $Object
    
        
    }
    catch { 
        $RPCFails   
    }
}
