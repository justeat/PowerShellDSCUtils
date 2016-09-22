# PowerShellDSCUtils
Just Eat PowerShell DSC Utilities

##Provision Pull Client
The Provision pull client script takes two parameters for it to run. 
```
PullServerURL
ConfigurationIDGUID
```
Both of these are mandatory. The purpose of them is to tell the client the location of the pull server, and to tell the client what configuration it should be using.

The Pull client is basically a wrapper script that detects the version of PowerShell you are running, then it goes and calls the relevant script based on said version. Both version 4 and 5 have the same end goal, but implementation between the two versions is slightly different. 

An example of running the script would be as so:

```powershell
.\ProvisionPullClient.ps1 -PullServerURL https://pullserver.example.com:8080/PSDSCPullServer.svc -ConfigurationIDGUID "435e907f-123d-4b8b-80c8-fb5e37957e4e"
```
