# parameters of Azure ResourceGroupName, Subscriptionid ,Forms , Mappings and StorageKey Path's passing from Dll 
param 
(   
 [string]$resourceGroupName,
 [string]$subscriptionId,
 [string]$formsPath,
 [string]$mappingsPath,
 [string]$storageKeyPath,
 [string]$orgName
)
##########################################
$location = 'Central US'  #By default Azure Location is setting to 'Central Us'

$IMSAppWebJobs   = 'IMSAppWebJobs'+$orgName
$IMSAppPrintAll  = 'IMSAppPrintAll'+$orgName
$IMSAppBinder    = 'IMSAppBinder'+$orgName
$IMSAppForms     = 'IMSAppForms'+$orgName
$IMSAppServicePlan = 'IMSAppServicePlan'


#Login to Azure account
Login-AzureRmAccount
# select Subscription
Set-AzureRmContext  -SubscriptionId $subscriptionId 

# Create new resource group if not exists.
$rgAvail = Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue
if(!$rgAvail){
    $resourceGroupName ='IMSAppResourceGroup'
    $resourceGroupName = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location	
	$resourceGroupName = $resourceGroupName.ResourceGroupName
}

$IMSAppAllAppServicePlan = Get-AzureRmAppServicePlan -ResourceGroupName $resourceGroupName -Name $IMSAppServicePlan
if(!$IMSAppAllAppServicePlan)
{
New-AzureRmAppServicePlan -Name $IMSAppServicePlan -Location $location -ResourceGroupName $resourceGroupName -Tier Free
}
$IMSAppAllAppServicePlan = Get-AzureRmAppServicePlan -ResourceGroupName $resourceGroupName -Name $IMSAppServicePlan




#Create new WebApp for WebJobs Application if not exists
$webAppWebJobs = Get-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppWebJobs -ErrorAction SilentlyContinue

if(!$webAppWebJobs -And $IMSAppAllAppServicePlan)
{
New-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppWebJobs -AppServicePlan $IMSAppServicePlan -Location $location
}

#Create new WebApp for PrintAll Application if not exists
$webAppPrintAll = Get-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppPrintAll -ErrorAction SilentlyContinue
if(!$webAppPrintAll -And $IMSAppAllAppServicePlan)
{
New-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppPrintAll -AppServicePlan $IMSAppServicePlan -Location $location
}

#Create new WebApp for Binder Application if not exists
$webAppBinder = Get-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppBinder -ErrorAction SilentlyContinue
if(!$webAppBinder -And $IMSAppAllAppServicePlan)
{
New-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppBinder -AppServicePlan $IMSAppServicePlan -Location $location
}

#Create new WebApp for FormsManagment Application if not exists
$webAppFormsManagement = Get-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppForms -ErrorAction SilentlyContinue
if(!$webAppFormsManagement -And $IMSAppAllAppServicePlan)
{
New-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $IMSAppForms -AppServicePlan $IMSAppServicePlan -Location $location
}
	
   $StorageAccountName = 'imsappformstrge'+$orgName # between 3 to 24 charactors and should be lower-caseLetters only
                                                 # Create the storage account if it doesn't already exist
   $checkStorageAccountExists = Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $resourceGroupName -ErrorAction Ignore
    if($checkStorageAccountExists  -eq $null){    
      $StorageAccount = New-AzureRmStorageAccount -AccountName $StorageAccountName -ResourceGroupName $resourceGroupName -Location $location -SkuName "Standard_LRS"
	 
    }
	$IMSAppStorageAppInsight = 'IMSAppStorageAppInsight'+$orgName
	#creating AppInsight for FormsManagement Application if not exists
	$MyRes=Get-AzureRmResource -ResourceName $IMSAppStorageAppInsight -ResourceGroupName $resourceGroupName
if ($null -eq $MyRes) {
  	 $resource =  New-AzureRmResource -ResourceName $IMSAppStorageAppInsight -ResourceGroupName $resourceGroupName -Tag @{ applicationType = "web"; applicationName = $IMSAppForms} -ResourceType "Microsoft.Insights/components" -Location "East US" -PropertyObject @{"Application_Type"="web"} -Force  
	 $AppInsightName =  $resource.Name
     $IKey = $resource.Properties.InstrumentationKey
}

# If the StorageAccoount exists then create Containers -- 'forms' and 'mappings'
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -AccountName $StorageAccountName
 if($storageAccount)
{
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName).Value[0]
$ctx = $storageAccount.Context
$StorageAccountContext = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $StorageAccountName}).Context

	    $ContainerName = 'forms'
	    $storageContainer = Get-AzureStorageContainer -Context $ctx -ErrorAction Stop | where-object {$_.Name -eq $ContainerName}	
        If($storageContainer)
        {        
		   $formsInAzureCount = 0
		   $listOfBLobs = Get-AzureStorageBlob -Container $ContainerName -Context $ctx 
		   $listOfBlobs | ForEach-Object { $formsInAzureCount++ }
		   if(@(Get-ChildItem $formsPath).Count -ne $formsInAzureCount)
							{	
							 Get-AzureStorageBlob -Context $ctx -Container $ContainerName | Remove-AzureStorageBlob						        	                       							
									   $files = Get-ChildItem $formsPath
									   foreach($file in $files)
									   {
									   $localfile = $formsPath+"\"+$file
									   $remotefile = "$file"
									   Set-AzureStorageBlobContent -File $localfile -Container $ContainerName -Blob $remotefile -Context $ctx -Force:$Force 
									   }
			                }					
        }
        Else 
        {
            New-AzureStorageContainer -Name  $ContainerName -Context $StorageAccountContext -Permission blob  -ErrorAction SilentlyContinue *>&1
               $files = Get-ChildItem $formsPath
			   foreach($file in $files)
			   {
			   $localfile = $formsPath+"\"+$file
			   $remotefile = "$file"
			   Set-AzureStorageBlobContent -File $localfile  -Container $ContainerName -Blob $remotefile -Context $ctx -Force:$Force 
			   }
	    }

		 $ContainerName = 'mappings'
		 $storageContainer = Get-AzureStorageContainer -Context $ctx -ErrorAction Stop | where-object {$_.Name -eq $ContainerName}	
        If($storageContainer)
        {         
		   $mappingsInAzureCount = 0
		   $listOfBLobs = Get-AzureStorageBlob -Container $ContainerName -Context $ctx 
		   $listOfBlobs | ForEach-Object { $mappingsInAzureCount++ }
		   if(@(Get-ChildItem $mappingsPath).Count -ne $mappingsInAzureCount)
							{							        
	                         Get-AzureStorageBlob -Context $ctx -Container $ContainerName | Remove-AzureStorageBlob		
									   $files = Get-ChildItem $mappingsPath
									   foreach($file in $files)
									   {
									   $localfile = $mappingsPath+"\"+$file
									   $remotefile = "$file"
									   Set-AzureStorageBlobContent -File $localfile -Container $ContainerName -Blob $remotefile -Context $ctx -Force:$Force 
									   }
			                }					
        }
        Else 
        {
            New-AzureStorageContainer -Name  $ContainerName -Context $StorageAccountContext -Permission blob  -ErrorAction SilentlyContinue *>&1
               $files = Get-ChildItem $mappingsPath
			   foreach($file in $files)
			   {
			   $localfile = $mappingsPath+"\"+$file
			   $remotefile = "$file"
			   Set-AzureStorageBlobContent -File $localfile  -Container $ContainerName -Blob $remotefile -Context $ctx -Force:$Force 
			   }
	    }

  $path = $storageKeyPath +'StorageKey.txt'
  if (Test-Path $path) 
     {
       Clear-Content $path 
	   Add-Content -Path $path -Value $storageAccountKey
     } 
	 else	 
	 {
      New-Item -Path $storageKeyPath -Name "StorageKey.txt" -ItemType "file" -Value $storageAccountKey
     }

  } 
  # Creating storage Account , KeyVault for IMSAppPrintAll and Binder

    $StorageAccountName = 'imsappstorageacc'+$orgName # between 3 to 24 charactors and should be lower-caseLetters only
                                                 # Create the storage account if it doesn't already exist
   $checkStorageAccountExists = Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $resourceGroupName -ErrorAction Ignore
    if($checkStorageAccountExists  -eq $null){
      $ResourceGroupName = $resourceGroupName     
      $StorageAccount = New-AzureRmStorageAccount -AccountName $StorageAccountName -ResourceGroupName $resourceGroupName -Location $location -SkuName "Standard_LRS"    	 
    }

	        $IMSAppKeyVaults='ImsAppKeyVaults'+$orgName
			$KeyVault = Get-AzureRMKeyVault -VaultName $IMSAppKeyVaults
			if(!$KeyVault)
			{
			New-AzureRmKeyVault -VaultName $IMSAppKeyVaults -ResourceGroupName $resourceGroupName -Location $location
			}
