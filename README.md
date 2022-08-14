# homebridge-cmd4-appletv
PowerShell script to integrate [pyatv](https://github.com/postlund/pyatv) with [homebridge-cmd4](https://github.com/ztalbot2000/homebridge-cmd4). This will expose your Apple TVs power state as a switch which may then be used in automations. We use a switch rather than TV accessory as Homekit automations can't be initiated from TV accessory state changes.

## Getting Started
Download the latest `atv_control.ps1` script and `atv_control.json` config file.

### Prerequisites
* A Windows PC with at least PowerShell 3 available
* [Homebridge](https://homebridge.io/) installed
* PowerShell execution enabled for your Homebridge user
* [homebridge-cmd4](https://github.com/ztalbot2000/homebridge-cmd4) plugin installed in Homebridge

### Installing
Copy the ps1 script and json file to a suitable location. For example, `C:\Users\[user name]\.homebridge\`.

Install [pyatv](https://github.com/postlund/pyatv). Ensure this is run under an administrator prompt so that the packages are installed globally:
```
pip3 install pyatv
```

### Assumptions
We assume:
* That `atv_control.json` will be in the same directory as `atv_control.ps1`
* That atvremote.exe is available in the path
* Homebridge is running as a service under the SYSTEM account

If any of these are not true, edit `atv_control.ps1` and modify $CONFIG, $ATVREMOTE_COMMAND and $SERVICE_USER to suit.


### Configuration
Edit `atv_control.json`.
Name your Apple TV as you would like the switch to appear in Homebridge. Do not use single quotes in the name. Multiple Apple TVs can be added. For example:
```
{
	"Living Room Apple TV": {
		"id": "",
		"airplay_credential": 	"",
		"companion_credential": ""
	},
	"Bedroom Apple TV": {
		"id": "",
		"airplay_credential": "",
		"companion_credential": ""
	}
}
```
Add your Apple TV identifier by performing a scan with atvremote and copying in one of the identifiers into _id_:
```
atvremote.exe scan
```
Add your airplay credential by pairing atvremote with your Apple TV and copying in the resulting credential into _airplay_credential_:
```
atvremote.exe --id AA:BB:CC:DD:EE:FF --protocol airplay pair
```
Add your companion credential by pairing atvremote with your Apple TV and copying in the resulting credential into _companion_credential_:
```
atvremote.exe --id AA:BB:CC:DD:EE:FF --protocol companion pair
```
Create your homebridge-cmd4 config by running and copying its output into homebridge-cmd4 settings in Homebridge:
```
atv_control.ps1 -CreateConfig
```
Restart Homebridge to apply the settinngs. You should now be able to control your Apple TV!

### Logging
Some basic logging is available by appending ` -log` to the _state_cmd_. This will write to `atv_control.ps1.log` in the same directory as the ps1 script.

### Toubleshooting
* > File C:\Users\user\.homebridge\atv_control.ps1 cannot be loaded because running scripts is disabled on this system. For more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.

  Enable PowerShell execution for your Homebridge user. I chose to enable it for LocalMachine as my Homebridge runs as SYSTEM user:
  ```
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
  ```

* A Python error that looks like:
  > ModuleNotFoundError: No module named 'six'

  Reinstall pyatv using an administrator command prompt
  '''
  pip3 install --upgrade --force-reinstall pyatv
  '''

### Acknowledgements
None of this would be possible without the following projects:
* [pyatv](https://github.com/postlund/pyatv)
* [homebridge-cmd4](https://github.com/ztalbot2000/homebridge-cmd4)
* [Homebridge](https://homebridge.io/)

Special inspiratation was taken from [homebridge-appletv](https://github.com/cristian5th/homebridge-appletv). This project can be considered a PowerShell port of homebridge-appletv.

## Contributing
Contrinutions happily accepted. Please send a pull request.

## Authors
* **Dinesh Pannu** - *Initial work*

## License
This project is licensed under Apache License 2.0 - see the [LICENSE](LICENSE) file for details
