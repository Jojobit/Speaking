#Use the cmdlets, the REST API endpoints and the advanced building blocks to:
#create workspaces in PowerBI 
#upload a report 
#change parameter
#trigger refresh
#add users to the workspaces
#and a sneak peak into Fabtools, the PowerShell module for Fabric

#Install the PowerBI module, if not already installed
if (Get-Module -Name MicrosoftPowerBIMgmt -ListAvailable) 
{Write-Host "PowerBI module already installed"} else {Install-Module -Name MicrosoftPowerBIMgmt}



#Login to PowerBI
Login-PowerBI



#Get a list of all the workspaces
Get-PowerBIWorkspace

$workspaces = Get-PowerBIWorkspace

$workspaces

$workspaces[-1]


#Make a workspace with the name of the company
$tempcompany = "Demo Data BASH 2023"
New-PowerBIWorkspace -Name $tempcompany

#Verify that the workspace was created
Get-PowerBIWorkspace -name $tempcompany

#Put that in a variable
$checkworkspace=Get-PowerBIWorkspace -name $tempcompany
#Check the name and id of the workspace
$checkworkspace.name
$checkworkspace.id
#Notice the workspace id. Check in Service.


#Check if the workspace already exists before creating it
if (!(Get-PowerBIWorkspace -name $tempcompany)) {
  New-PowerBIWorkspace -Name $tempcompany
} else {
  Write-Host "Workspace already exists"
}


#Create a lot of workspaces
#Use a text file with the names of the workspaces to be created
#Loop through the text file to create the workspaces
#Check if the workspace already exists before creating it 
$CompanyNames = Get-Content -Path "C:\workspaces.txt"
$CompanyNames
        
foreach ($company in $CompanyNames) {
$checkworkspace=Get-PowerBIWorkspace -name $company
  if( $company -ine $checkworkspace.Name) {
    New-PowerBIWorkspace -Name $company
  } else {write-host "Workspace "$checkworkspace.name" already exists, will not create."}   
}

#Check that the workspaces were created
#A pipe is used to pass the results of one command to another command
#The where-object command will filter the results of the Get-PowerBIWorkspace command
#The $_.name refers to the name of the workspace that is returned by the Get-PowerBIWorkspace command
#The where-object command will only return the workspaces that are in the list of company names
$workspaces = Get-PowerBIWorkspace| where-object {$CompanyNames -contains $_.name}
$workspaces| select-object name,id
#Check also in Power BI Service that the workspaces were created


#Upload the report from a file to the workspaces
#The report "Best-Report-Ever.pbix" is stored in the C:\git\DataWizard folder
#The report will be uploaded to all the workspaces that were created, $workspaces
#Foreach loop. The $w variable is the current workspace in the $workspaces list
$path = "C:\Best-Report-Ever.pbix"

foreach ($w in $workspaces) {
      $workspace_name = $w.name
      write-host "Now uploading the best report ever to " $workspace_name
      new-powerbireport -Path $path -WorkspaceId $w.id
  }

#Check that the report was uploaded to the workspaces
foreach ($w in $workspaces) {
  $workspace_name = $w.name
  write-host "Now checking the reports in " $workspace_name
  $reports = Get-PowerBIReport -WorkspaceId $w.id
  $reports| select-object name,id
}

#Set the parameter of the report in the workspaces
#Select Fxxxx from the name of workspaces and use that as the parameter
foreach ($w in $workspaces) {
  $di = Get-PowerBIDataset -workspaceid $w.Id
    (Invoke-PowerBIRestMethod -Method get -Url ("datasets/"+$di.id+"/parameters") | ConvertFrom-Json).value 
$parameter = $w.name.Split('-')[1].TrimStart(1).Trim(' ')
    $updatedetails = '{
      "updateDetails": [
        {
          "name": "Parameter",
          "newValue": "'+$parameter+'"
        }
      ]
    }'
    write-host "Updating the parameter for "$di.name" in "$w.name
    (Invoke-PowerBIRestMethod -Method post -Url ("datasets/"+$di.id+"/Default.UpdateParameters") -body $updatedetails | ConvertFrom-Json)
  }

#Let's check the parameters now
foreach ($w in $workspaces) {
  $di = Get-PowerBIDataset -workspaceid $w.Id
  $check=(Invoke-PowerBIRestMethod -Method get -Url ("datasets/"+$di.id+"/parameters") | ConvertFrom-Json).value.currentValue
  write-host "The parameter for "$di.name" in "$w.name" is "$check
}




#Add the emails from a list as members of the workspaces we created
#The list of emails is stored in the emails.txt file on C:\Demo folder and contains the list of emails, one email per line


$emails = Get-Content "C:\emails.txt"
foreach ($w in $workspaces) {
  $workspace_name = $w.name
  write-host "Now adding the users to " $workspace_name
  foreach ($email in $emails)
{Add-PowerBIWorkspaceUser -WorkspaceId $w.id -UserEmailAddress $email -AccessRight Member
  }
}


#Let's check in Power BI Service that the emails were added as members of the workspaces


#Refresh all the reports, at once, in all the workspaces
foreach ($w in $workspaces) {
  get-powerbidataset -workspaceid $w.id
  $d = Get-PowerBIDataset -workspaceid $w.Id
  (Invoke-PowerBIRestMethod -Method Post -Url ("datasets/"+$d.id+"/refreshes") | ConvertFrom-Json)
  }


#I had enough of long Power BI Rest API calls and Invoke-PowerBIRestMethod...
#Introducing Fabtools: https://github.com/Jojobit/Fabtools

#Install the Fabtools module, if not already installed
Install-Module -Name Fabtools

#Refresh with cmdlet from Fabtools
foreach ($w in $workspaces) {
  get-powerbidataset -workspaceid $w.id
  $d = Get-PowerBIDataset -workspaceid $w.Id
  Invoke-FabricDatasetRefresh -DatasetID $d.id
}
#Nicer than (Invoke-PowerBIRestMethod -Method Post -Url ("datasets/"+$d.id+"/refreshes") | ConvertFrom-Json)


#Cleanup. Delete all the workspaces in $workspaces from the tenant
foreach ($w in $workspaces){  
    $workspaceId =$w.id
    Remove-FabricWorkspace $workspaceId
    write-host "Done deleting "$w.Name
    }


#Microsoft Fabric capacity is billed by the second
#You can pause (suspend) the capacity when you are not using it
#You can resume the capacity when you need it

#Connect to Azure
Connect-AzAccount
Set-FabricAuthToken

#Get all capacities
#This gives all the Fabric and Power BI capacities that the user has access to
Get-FabricCapacity