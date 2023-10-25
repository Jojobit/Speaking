#A demo of how to create workspaces in PowerBI using PowerShell, upload a report to the workspace, set its parameters and trigger a refresh. Then, add the users with the correct access rights to the workspaces.
#And a little bit of Starwars quotes, because why not?
#Prerequisites: PowerBI module installed, PowerBI account, workspaces.txt file with the names of the workspaces to be created
#Install the PowerBI module, if not already installed
if (!(Get-Module -Name MicrosoftPowerBIMgmt -ListAvailable)) {
    Install-Module -Name MicrosoftPowerBIMgmt
}   
else {
    Write-Host "PowerBI module already installed"
} 

#Let's get cracking!
#Connect to the PowerBI service
#Login to PowerBI
Login-PowerBI


#Get a list of all the workspaces
Get-PowerBIWorkspace
$workspaces = Get-PowerBIWorkspace
$workspaces
$workspaces[-1]


#Make a workspace with the name of the company
$tempcompany = "Demo"
New-PowerBIWorkspace -Name $tempcompany
#Verify that the workspace was created
Get-PowerBIWorkspace -name $tempcompany
#Put that in a variable
$checkworkspace=Get-PowerBIWorkspace -name $tempcompany
#Check the name and id of the workspace
$checkworkspace.name
$checkworkspace.id
#Notice the workspace id, it's the same as in Power BI Service

#Great, but what if you want to check if the workspace already exists before creating it?
#You can use the if statement and the Get-PowerBIWorkspace commandto check if the workspace already exists
#If the workspace already exists, the workspace will not be created
#If the workspace doesn't exist, the workspace will be created
if (!(Get-PowerBIWorkspace -name $tempcompany)) {
    New-PowerBIWorkspace -Name $tempcompany
}
else {
    Write-Host "Workspace already exists"
}


#Fair enough, but what if you want to create a lot of workspaces?
#Yoda: "Do. Or do not. There is no try."
#You can use a text file with the names of the workspaces to be created
#and then loop through the text file to create the workspaces

#Creating workspaces with the names from workspaces.txt, if they don't already exist
$CompanyNames = Get-Content -Path "workspaces.txt"

#What's a loop?
#A loop is a way to repeat a set of commands multiple times
#In this case, we want to loop through the list of company names and create a workspace for each company
#The loop will stop when it reaches the end of the list of company names
#Example: If the list of company names is "Company1", "Company2", "Company3", the loop will create a workspace for each company
#and then stop
#A foreach loop is used to loop through a list of items
foreach ($company in $CompanyNames) {
        New-PowerBIWorkspace -Name $company
  }

#Great, but what if you want to check if the workspace already exists before creating it?
#Darth Vader: "I find your lack of faith disturbing."
#Let's put it all together and create a loop that checks if the workspace already exists before creating it with if-clause and foreach-loop
#You can use the Get-PowerBIWorkspace command to check if the workspace already exists
#If the workspace already exists, the command will return the name of the workspace
#If the workspace doesn't exist, the command will return nothing
#You can use the if statement to check if the workspace already exists
#If the workspace already exists, the if statement will return true
#If the workspace doesn't exist, the if statement will return false
#If the workspace doesn't exist, the New-PowerBIWorkspace command will be executed
#If the workspace already exists, the New-PowerBIWorkspace command will not be executed
#Example: If the list of company names is "Company1", "Company2", "Company3", the loop will check if the workspace "Company1" exists
#If the workspace "Company1" doesn't exist, the New-PowerBIWorkspace command will be executed and a workspace with the name "Company1" will be created
#If the workspace "Company1" already exists, the New-PowerBIWorkspace command will not be executed and a workspace with the name "Company1" will not be created
#A foreach loop is used to loop through a list of items         
foreach ($company in $CompanyNames) {
  $checkworkspace=Get-PowerBIWorkspace -name $company
    if( $company -ine $checkworkspace.Name) {
      New-PowerBIWorkspace -Name $company
    } 
    else {write-host "Workspace "$checkworkspace.name" already exists, will not create."}   
}

#Check that the workspaces were created
#Pipe the results of the Get-PowerBIWorkspace command to the where-object command
#What's a pipe again?
#A pipe is used to pass the results of one command to another command
#The where-object command will filter the results of the Get-PowerBIWorkspace command
#The where-object command will only return the workspaces that have a name that is in the list of company names
#The list of company names is stored in the $CompanyNames variable
$workspaces = Get-PowerBIWorkspace| where-object {$CompanyNames -contains $_.name} 
#The $_.name is used to refer to the name of the workspace that is returned by the Get-PowerBIWorkspace command
#The where-object command will only return the workspaces that have a name that is in the list of company names

#Check the list of workspaces
$workspaces

#-----------------------------------------------------
#Upload the report from a file to the workspaces
#The report is stored in the C:\git\Demo folder
#The report is called "Best-Report-Ever.pbix"
#The report will be uploaded to all the workspaces that were created, $workspaces
#A foreach loop is used to loop through the list of items
$report = "Best-Report-Ever.pbix"
    foreach ($w in $workspaces) {
        $workspace_name = $w.name
        write-host "Now uploading the best report ever to " $workspace_name
        new-powerbireport -Path $report -WorkspaceId $w.id
    }

#Let's check that the report was uploaded to the workspaces
#The Get-PowerBIReport command will return the reports that are in the workspace
#The Get-PowerBIReport command will only return the reports that are in the workspace that is stored in the $w variable
#The $w variable is the current workspace in the $workspaces list
#A foreach loop is used to loop through the list of items
foreach ($w in $workspaces) {
    $workspace_name = $w.name
    write-host "Now checking the reports in " $workspace_name
    $reports = Get-PowerBIReport -WorkspaceId $w.id
    $reports
}

#Optional, only for the brave and the bold
#Set the parameters of the report in all the workspaces that were created, $workspaces
#The parameters will be set in all the workspaces that were created, $workspaces
#A foreach loop is used to loop through the list of items
#Changing parameter for the dataset in all the workspaces from workspaces.txt
#The parameter value is the second part of the workspace name
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

#Let's check in Power BI Service that the parameters were set in the reports


#Now let's refresh the reports. All the reports, at once, in all the workspaces
#There is no cmdlet to refresh all the reports in all the workspaces
#Yoda: "In a dark place we find ourselves, and a little more knowledge lights our way.” 
#Nothing stands in the way of the Power jedi!
#You can use the Invoke-PowerBIRestMethod command to refresh all the reports in all the workspaces
#A foreach loop is used to loop through the list of items
foreach ($w in $workspaces) {
    get-powerbidataset -workspaceid $w.id
    $d = Get-PowerBIDataset -workspaceid $w.Id
    (Invoke-PowerBIRestMethod -Method Post -Url ("groups/"+$w.id+"/datasets/"+$d.id+"/refreshes") | ConvertFrom-Json)
    }

#Let's check in Power BI Service that the reports were refreshed


#Enable the automatic refresh schedule for all the datasets in all the workspaces in the workspaces.txt file
#A foreach loop is used to loop through the list of items
foreach ($w in $workspaces) {
    $workspace_name = $w.name
    write-host "Now enabling the automatic refresh schedule for " $workspace_name
    $datasets = Get-PowerBIDataset -WorkspaceId $w.id
    foreach ($dataset in $datasets) {
        $dataset_name = $dataset.name
        write-host "Now enabling the automatic refresh schedule for " $dataset_name
        $dataset_id = $dataset.id
        $refresh = '{
            "schedule": {
                "enabled": true,
                "refreshType": "OnDemand"
            }
        }'
        (Invoke-PowerBIRestMethod -Method patch -Url ("datasets/"+$dataset_id) -body $refresh | ConvertFrom-Json)
    }
}

#-----------------------------------------------------
#Let's add the emails from a list as members of the workspaces we created
#The list of emails is stored in the emails.txt file on C:\Demo folder and contains the list of emails, one email per line
#We will use the Add-PowerBIWorkspaceUser command to add the emails as members of the workspaces
$emails = Get-Content "emails.txt"
foreach ($w in $workspaces) {
    $workspace_name = $w.name
    write-host "Now adding the users to " $workspace_name
    foreach ($email in $emails) {
        Add-PowerBIWorkspaceUser -WorkspaceId $w.id -UserEmailAddress $email -AccessRight Member
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
#Power Jedi, you are now
#Yoda: "May the Force be with you"

#A list of cmdlets used in this script
#Get-PowerBIWorkspace Get a list of all the workspaces
#New-PowerBIWorkspace Create a new workspace
#New-PowerBIReport which uploads the report to the workspaces
#Get-PowerBIReport which returns the reports in the workspaces
#Get-PowerBIDataset which returns the datasets in the workspaces
#Add-PowerBIWorkspaceUser which adds the emails as members of the workspaces

#A list of REST API calls used in this script
#Invoke-PowerBIRestMethod -Method get -Url ("datasets/"+$di.id+"/parameters")
#Invoke-PowerBIRestMethod -Method post -Url ("datasets/"+$di.id+"/Default.UpdateParameters")
#Invoke-PowerBIRestMethod -Method Post -Url ("groups/"+$w.id+"/datasets/"+$d.id+"/refreshes")


#A list of all the cmdlets that you can use to manage Power BI with PowerShell
#https://docs.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps

#A list of all the REST API calls that you can use to manage Power BI with PowerShell
#https://docs.microsoft.com/en-us/rest/api/power-bi/


