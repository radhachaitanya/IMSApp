#Passing the AzureWebJobs and AzureWebSites bin folder paths as parameters 
param 
(   
 [string]$ExpireTodayValidToDocuments_Path,
 [string]$SendDocumentExpirationNotificationToFN_Path ,
 [string]$SLARemainingTime_Path ,
 [string]$UpdateSlaFlagonActiveCases_Path ,
 [string]$CreateTaskOnDepenedetnAgeChange_Path ,  
 [string]$UpdateAttorneyInFNandCases_Path ,
 [string]$IMSAppSourcePrintAll_Path,
 [string]$IMSAppSourceBinder_Path,
 [string]$IMSAppSourceFormsManagement_Path,
 [string]$resourceGroupName,
 [string]$subscriptionId,
 [string]$orgName

)
#Enter Location

$location = 'Central US'
##########################################
#$PublishedPath = $ToolPath"\\PkgFolder\PublishedStatus"
$Apiversion = "2016-08-01"
$webAppName = 'IMSAppWebJobs'+$orgName
$IMSAppPrintAll  = 'IMSAppPrintAll'+$orgName
$IMSAppBinder    = 'IMSAppBinder'+$orgName
$IMSAppForms     = 'IMSAppForms'+$orgName

$ExpireTodayValidToDocuments_UrI = 'https://'+$webAppName+'.scm.azurewebsites.net/api/triggeredwebjobs/ExpireTodayValidToDocuments'
$SendDocumentExpirationNotificationToFN_UrI = 'https://'+$webAppName+'.scm.azurewebsites.net/api/triggeredwebjobs/SendDocumentExpirationNotificationToFN'
$SLARemainingTime_UrI = 'https://'+$webAppName+'.scm.azurewebsites.net/api/triggeredwebjobs/SLARemainingTime'
$UpdateSlaFlagonActiveCases_UrI ='https://'+$webAppName+'.scm.azurewebsites.net/api/triggeredwebjobs/UpdateSlaFlagonActiveCases'
$CreateTaskOnDependentAgeChange_UrI = 'https://'+$webAppName+'.scm.azurewebsites.net/api/triggeredwebjobs/CreateTaskOnDependentAgeChange'
$UpdateAttorneyInFNandCases_UrI = 'https://'+$webAppName+'.scm.azurewebsites.net/api/triggeredwebjobs/UpdateAttorneyInFNandCases'

Add-AzureAccount 
Select-AzureSubscription -SubscriptionId $subscriptionId  

#New-Item  $ToolPath\PkgFolder\PublishedStatus -type file
#Add-content $ToolPath\PkgFolder\PublishedStatus -value "Applications Deployment Start $(Get-Date)"

#Login to Azure account
#Connect-AzureRmAccount 
#select Subscription
#Set-AzureRmContext  -SubscriptionId $subscriptionId 

# if ResourceGroupName not mentioned in the script , select default ResourceGroupName as "IMSAppResourceGroup"
if($resourceGroupName -eq '')
{
  $resourceGroupName = 'IMSAppResourceGroup'
}

 #Publishing the WebSite of IMSAppPrintAll
 $webAppPrintAll = Get-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppPrintAll -ErrorAction SilentlyContinue
if($webAppPrintAll)
{
 Publish-AzureWebsiteProject -name $IMSAppPrintAll -package $IMSAppSourcePrintAll_Path
 #Add-content $PublishedPath -value "Successfully Deployed the PrintAll Application"
}
  #Publishing the WebSite of IMSAppBinder
  $webAppBinder = Get-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppBinder -ErrorAction SilentlyContinue
if($webAppBinder)
{
 Publish-AzureWebsiteProject -name $IMSAppBinder -package $IMSAppSourceBinder_Path
 #Add-content $PublishedPath -value "Successfully Deployed the Binder Application"
}
  #Publishing the WebSite of IMSAppForms
  $webAppForms = Get-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppForms -ErrorAction SilentlyContinue
if($webAppForms)
{
 Publish-AzureWebsiteProject -name $IMSAppForms -package $IMSAppSourceFormsManagement_Path
  #Add-content $PublishedPath -value "Successfully Deployed the Forms Application"
}
 

#Getting the publishingCredentials
 function Get-PublishingProfileCredentials($resourceGroupName, $webAppName){
 $resourceType = "Microsoft.Web/sites/config"
 $resourceName = "$webAppName/publishingcredentials"
 $publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion $Apiversion -Force
    return $publishingCredentials
 }
#Getting the Azure Claims 
 function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $webAppName){
 $publishingCredentials = Get-PublishingProfileCredentials $resourceGroupName $webAppName
 return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
}
 #Generating Token to Authicate the Azure.
 $accessToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppname
 #Generating header to create and publish the Webjob :
 $Header = @{
    'Content-Disposition'='attachment; filename=ConsoleApp.zip' 
	'Authorization'=$accessToken
	}

 $webAppWebjobs = Get-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $webAppName -ErrorAction SilentlyContinue
if($webAppWebjobs)
{
 # Creating the WebJob of ExpireTodayValidToDocuments
 $result = Invoke-RestMethod -Uri $ExpireTodayValidToDocuments_UrI  -Headers $Header -Method put -InFile $ExpireTodayValidToDocuments_Path -ContentType 'application/zip'

 # Creating the WebJob of SendDocumentExpirationNotificationToFN
 $result = Invoke-RestMethod -Uri $SendDocumentExpirationNotificationToFN_UrI -Headers $Header -Method put -InFile $SendDocumentExpirationNotificationToFN_Path -ContentType 'application/zip'

 # Creating the WebJob of SLARemainingTime
 $result = Invoke-RestMethod -Uri $SLARemainingTime_UrI -Headers $Header -Method put -InFile $SLARemainingTime_Path -ContentType 'application/zip'
  
 # Creating the WebJob of UpdateSlaFlagonActiveCases
 $result = Invoke-RestMethod -Uri $UpdateSlaFlagonActiveCases_UrI  -Headers $Header -Method put -InFile $UpdateSlaFlagonActiveCases_Path -ContentType 'application/zip'
 
 # Creating the WebJob of CreateTaskOnDependentAgeChange
 $result = Invoke-RestMethod -Uri $CreateTaskOnDependentAgeChange_UrI -Headers $Header -Method put -InFile $CreateTaskOnDepenedetnAgeChange_Path -ContentType 'application/zip'

  # Creating the WebJob of UpdateAttorneyInFNandCases
   $result = Invoke-RestMethod -Uri $UpdateAttorneyInFNandCases_UrI -Headers $Header -Method put -InFile $UpdateAttorneyInFNandCases_Path -ContentType 'application/zip'
 
  #Add-content $PublishedPath -value "Successfully Deployed the Webjobs Application"
}

#Add-content $PublishedPath -value "Applications Deployment End $(Get-Date)"