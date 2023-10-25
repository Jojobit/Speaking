#Use the cmdlets, the REST API endpoints and the advanced building blocks to:
#create workspaces in PowerBI 
#upload a report 
#change parameter
#trigger refresh
#add users to the workspaces

#Install the PowerBI module, if not already installed
if (Get-Module -Name MicrosoftPowerBIMgmt -ListAvailable) 
  {Write-Host "PowerBI module already installed"}   
else 
  {Install-Module -Name MicrosoftPowerBIMgmt}



#Login to PowerBI
Login-PowerBI



#Get a list of all the workspaces
Get-PowerBIWorkspace

$workspaces = Get-PowerBIWorkspace

$workspaces

$workspaces[0]


#Make a workspace with the name of the company
$tempcompany = "Demo Stockholm Data Saturday"
New-PowerBIWorkspace -Name $tempcompany

#Verify that the workspace was created
Get-PowerBIWorkspace -name $tempcompany

#Put that in a variable
$checkworkspace=Get-PowerBIWorkspace -name $tempcompany
#Check the name and id of the workspace
$checkworkspace.name
$checkworkspace.id
#Notice the workspace id


#Check if the workspace already exists before creating it
if (!(Get-PowerBIWorkspace -name $tempcompany)) {
  New-PowerBIWorkspace -Name $tempcompany
}
else {
  Write-Host "Workspace already exists"
}


#Create a lot of workspaces
#Use a text file with the names of the workspaces to be created
#Loop through the text file to create the workspaces
#Check if the workspace already exists before creating it 
$CompanyNames = Get-Content -Path "C:\git\DataWizard\workspaces.txt"
$CompanyNames
        
foreach ($company in $CompanyNames) {
$checkworkspace=Get-PowerBIWorkspace -name $company
  if( $company -ine $checkworkspace.Name) {
    New-PowerBIWorkspace -Name $company
  } 
  else {write-host "Workspace "$checkworkspace.name" already exists, will not create."}   
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
#The report "Best-Report-Ever.pbix" is stored in the C:\git\Demo folder
#The report will be uploaded to all the workspaces that were created, $workspaces
#Foreach loop. The $w variable is the current workspace in the $workspaces list
$path = "C:\git\DataWizard\Best-Report-Ever.pbix"

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


#Refresh all the reports, at once, in all the workspaces
foreach ($w in $workspaces) {
  get-powerbidataset -workspaceid $w.id
  $d = Get-PowerBIDataset -workspaceid $w.Id
  (Invoke-PowerBIRestMethod -Method Post -Url ("groups/"+$w.id+"/datasets/"+$d.id+"/refreshes") | ConvertFrom-Json)
  }


#Add the emails from a list as members of the workspaces we created
#The list of emails is stored in the emails.txt file on C:\Demo folder and contains the list of emails, one email per line
$emails = Get-Content "C:\git\DataWizard\emails.txt"
foreach ($w in $workspaces) {
  $workspace_name = $w.name
  write-host "Now adding the users to " $workspace_name
  foreach ($email in $emails)
{Add-PowerBIWorkspaceUser -WorkspaceId $w.id -UserEmailAddress $email -AccessRight Member
  }
}


#Let's check in Power BI Service that the emails were added as members of the workspaces


#Now, to sum up, we have:
#created the workspaces, 
#uploaded the report to the workspaces,
#set the parameters of the report in the workspaces, 
#refreshed the reports in the workspaces, and 
#added the members of the workspaces

#We have done all this with PowerShell
#We have done all this with the Power BI PowerShell cmdlets and a little bit with the Power BI REST API


#A list of cmdlets used in this script
#Get-PowerBIWorkspace Get a list of all the workspaces
#New-PowerBIWorkspace Create a new workspace
#New-PowerBIReport which uploads the report to the workspaces
#Get-PowerBIReport which returns the reports in the workspaces
#Get-PowerBIDataset which returns the datasets in the workspaces
#Add-PowerBIWorkspaceUser which adds the emails as members of the workspaces

#A list of REST API calls used in this script
#Invoke-PowerBIRestMethod -Method Get -Url ("datasets/"+$di.id+"/parameters")
#Invoke-PowerBIRestMethod -Method Post -Url ("datasets/"+$di.id+"/Default.UpdateParameters")
#Invoke-PowerBIRestMethod -Method Post -Url ("groups/"+$w.id+"/datasets/"+$d.id+"/refreshes")


#A list of all the cmdlets that you can use to manage Power BI with PowerShell
#https://docs.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps

#A list of all the REST API calls that you can use to manage Power BI with PowerShell
#https://docs.microsoft.com/en-us/rest/api/power-bi/





#Cleanup. Delete all the workspaces from workspaces.txt

#Delete Company Workspace
#Get the list of workspaces
$workspaces = Get-PowerBIWorkspace| where-object {$CompanyNames -contains $_.name}
#Loop through each workspace and delete it
foreach ($w in $workspaces){  
  $workspaceId =$w.id
  Invoke-PowerBIRestMethod -Method DELETE -Url "groups/$workspaceId"
  write-host "Done deleting "$w.Name
  }