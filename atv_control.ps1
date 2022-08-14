param(
	[switch]$createConfig,
	[switch]$log
)

$CONFIG="$PSScriptRoot\atv_control.json"
$ATVREMOTE_COMMAND="atvremote.exe"
$SERVICE_USER="nt authority\system"

###############################################################################

function Usage() {
	$scriptName = split-path $MyInvocation.PSCommandPath -Leaf
	Write-Output "Usage:"
	Write-Output "`t $scriptName -CreateConfig"
	Write-Output "`t $scriptName Get [accessory name] [characteristic]"
	Write-Output "`t $scriptName Get [accessory name] [characteristic] [value]"
}

function Log {
    param(
        [Parameter(Mandatory=$true)][String]$message
    )
	
	$scriptName = split-path $MyInvocation.PSCommandPath -Leaf
    $timeStamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $line = "$timeStamp $PID $message"
	
	# Don't output if we are running from a service
	#
	if ($(whoami) -ne $SERVICE_USER) {
		Write-Host $line
	}

    if ($log) {
        Add-Content "$($PSScriptRoot)\$($scriptName).log" $line
    }
}


function CreateConfig() {

	$config = Get-Content -Raw -Path $CONFIG | ConvertFrom-Json
	
	$cmd4_config = [ordered]@{
	    "platform" = "Cmd4"
		"name" = "Cmd4"
		"interval" = 5
		"timeout" = 4000
		"debug" = $false
		"stateChangeResponseTime" = 3
		"queueTypes" = @(
			@{
				"queue" = "A"
				"queueType" = "WoRm"
			}
		)
		"accessories" = @()
	}


	foreach ($device in $config.PSObject.Properties) {
		$deviceConfig = [ordered]@{
			"type" = "Switch"
            "displayName" = "$($device.Name) Power"
            "on" = "FALSE"
            "queue" = "A"
            "polling" = @(
				@{"characteristic" = "on"}
			)
            "state_cmd" = "powershell.exe -file $PSCommandPath"
		};
		
		$cmd4_config.accessories += $deviceConfig
	}
	
	$json = $cmd4_config | ConvertTo-Json -Depth 4
	Write-Output $json
}

function GetDevice($config, $deviceString) {	
	foreach ($configuredDevice in $config.PSObject.Properties) {
		
		if ($deviceString -like "$($configuredDevice.Name) *" )
		{
			$deviceConfig = $configuredDevice.Value
		}
	}
	
	return $deviceConfig
}

function Run() {
	$config = Get-Content -Raw -Path $CONFIG | ConvertFrom-Json
	$deviceConfig = GetDevice $config $device
	
	$validConfig = $true
	if ($null -eq $deviceConfig)
	{
		$validConfig = $false
		Write-Output "Device $device not in config"
	}
	elseif ($null -eq $deviceConfig.id) {
		$validConfig = $false
		Write-Output "id not set for device $device in config"
	}
	elseif ($null -eq $deviceConfig.airplay_credential) {
		$validConfig = $false
		Write-Output "airplay_credentials not set for device $device in config"
	}
	elseif ($null -eq $deviceConfig.companion_credential) {
		$validConfig = $false
		Write-Output "companion_credential not set for device $device in config"
	}
	
	if ($validConfig) {
		switch($io) {
			"Get" {
				switch($characteristic){
					"On" {
						$atv_power_state = & $ATVREMOTE_COMMAND --id $deviceConfig.id --airplay-credentials $deviceConfig.airplay_credential power_state
						if ("$atv_power_state" -eq "PowerState.On") {
							Write-Output "1"
						} 
						else {
							Write-Output "0"
						}	
	
						break
					}
		
					default {
						Write-Output "Unhandled Get ${device}  Characteristic ${characteristic}"
					}
				}
				break
			}
			
			"Set" {
				if ($device -like "* Power") {
					switch($characteristic) {
						"On" {
							$atv_power_state = & $ATVREMOTE_COMMAND --id $deviceConfig.id --airplay-credentials $deviceConfig.airplay_credential power_state
							if ("$atv_power_state" -eq "PowerState.On") {
								& $ATVREMOTE_COMMAND --id $deviceConfig.id --companion-credentials $deviceConfig.companion_credential turn_off
								Write-Output "1"
							} 
							else {
								& $ATVREMOTE_COMMAND --id $deviceConfig.id --companion-credentials $deviceConfig.companion_credential turn_on
								Write-Output "0"
							}
						}
					
						default {
							Write-Output "Unhandled Set $device Characteristic $characteristic"
						}
					}
				}
				break
			}
			
			default {
				Write-Output "Unknown io command $io"
			}
		}
	}
}


$boundArguments = ""
foreach($psbp in $PSBoundParameters.GetEnumerator())
{
	$boundArguments += "Key={0} Value={1}, " -f $psbp.Key,$psbp.Value
}

if ("" -ne $boundArguments) {
	Log $boundArguments
}


$unboundArguments = ""
foreach($arg in $args)
{
	$unboundArguments += "[$arg] " 
}

if ("" -ne $unboundArguments) {
	Log $unboundArguments
}
Log "user: $(whoami)"

$io = ""
$device = ""
$characteristic = ""
if ($args.Count -ge 3)
{
	$io = $args[0]
	
	# homebridge-cmd4 uses single quotes which PowerShell parses incorrectly when coming from cmd
	# So we detect for that here and piece the arguments back together
	#
	if ($args[1] -like "'*") {
		$device = ""

		for ($i=1; $i -lt $args.Count; ++$i) {
			$device += "$($args[$i]) "
			
			if ($args[$i] -like "*'")
			{
				# Strip trailing slash
				#
				$device = $device -replace ".$"
				
				$characteristic = $args[$i + 1]
				$option = $args[$i + 2]
				break
			}
		}
	}
	else {
		$device = $args[1]
		$characteristic = $args[2]
		$option = $args[3]
	}
	
	# strip leading and trailing single quotes
	#
	if ($device -like "'*'") {
		$device = $device -replace ".$"
		$device = $device -replace "^."
	}
	
	# strip leading and trailing single quotes
	#
	if ($characteristic -like "'*'") {
		$characteristic = $characteristic -replace ".$"
		$characteristic = $characteristic -replace "^."
	}
	Log "io: $io, device: $device, characteristic: $characteristic"
}



if ($PSBoundParameters.ContainsKey('createConfig')) {
	CreateConfig
}
elseif ($io -ne "" -and $device -ne "" -and $characteristic -ne "") {
	Run
} 
else {
	Usage
	exit 1
}