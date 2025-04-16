########################################################################################
# Brief Description: Keyvault Promo                                                    #
# 	a one stop helper file to update keyvault values in dev and prod environments.     #
# Created by Tim Jones 04.10.2023                                                      #
# Version .1                                                                           #           
# Update version .9 04.16.2025                                                         #
#   Changelog:  Streamline functions and add kvConfig.json                             #
#               for storing environment login info.                                    #
########################################################################################

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

## Variables: 
	$workingDirectory = "/Users/tjones/gits/Dev/"
##*===============================================

##*===============================================
##* END VARIABLE DECLARATION 
##*===============================================

##*===============================================
##* Functions
##*===============================================

# Function to add key vault values
function bulkAddKVValues {
	Param (
    $spName,
    $spPassword,
    $csv
	)

	# Expecting csv with headers of key and value

	#Modules needed
	#Install-Module -Name Az -Force -Scope CurrentUser

	$secretValues = @()

	Write-Host "Logging into the source environment."
	$securePassword = ConvertTo-SecureString $spPassword -AsPlainText -Force
	$credential = New-Object -typename System.Management.Automation.PSCredential `
		-argumentlist $spName, $securePassword
	Connect-AzAccount -Credential $credential -TenantId "dd0a7738-e5d7-49ed-8a01-42e0fd15076c" -ServicePrincipal | Out-Null
	$subscriptionInfo = Get-AzSubscription
	Write-Host "Logged into" $subscriptionInfo.Name

	$keyVaults = Get-AzKeyVault
	#$keyVaults.VaultName

	ForEach ($keyVault in $keyVaults) {
		If ($keyVault.VaultName -like "*sharp-kv") {
			$sharpKV = $keyVault
			Write-Host "Connected to the Key Vault" $sharpKV.VaultName
		}
	}

	## Adding catch for when logins don't work
	Write-Host "Press Enter to continue or any other key to exit..."

	try {
		while ($true) {
			$key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

			if ($key.Character -eq "`r") {  # Handles Enter key
				Write-Host "Continuing..."
				break
			} else {
				Write-Host "Exiting..."
				exit
			}
		}
	} catch {
		Write-Host "Script terminated."
		exit
	}



	$valuePairs = Import-Csv -Path $csv

	ForEach ($valuePair in $valuePairs) {
		Set-AzKeyVaultSecret -VaultName $sharpKV.VaultName -Name $valuePair.key -SecretValue $(ConvertTo-SecureString $valuePair.value -AsPlainText -Force)
	}

	Write-Host "The below values were added to" $sharpKV.VaultName

	ForEach ($valuePair in $valuePairs) {
		Write-Host "Getting value string for" $valuePair.key
		$secretProperties = Get-AzKeyVaultSecret -VaultName $sharpKV.VaultName -Name $valuePair.key
		$secretValueText = '';
		$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretProperties.SecretValue)
		try {
			$secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
		} finally {
			[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
		}
		Write-Host "Value is:" $secretValueText
	}
}

# Function to select environments to update
function Select-Environments {
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$environments
    )

    Write-Host "`nAvailable Environments:"
    for ($i = 0; $i -lt $environments.Count; $i++) {
        Write-Host "$($i + 1). $($environments[$i].name) ($($environments[$i].environment))"
    }

    Write-Host "`nSelect environments to update:"
    Write-Host "1. Dev (Development environments)"
    Write-Host "2. Prod (Production environments)"
    Write-Host "3. All environments"
    Write-Host "4. Custom selection"
    
    $choice = Read-Host "`nEnter your choice (1-4)"

    switch ($choice) {
        "1" { 
            return $environments | Where-Object { $_.environment -eq "Dev" }
        }
        "2" { 
            return $environments | Where-Object { $_.environment -eq "Prod" }
        }
        "3" { 
            return $environments 
        }
        "4" {
            Write-Host "`nEnter the numbers of the environments you want to update (space-separated):"
            Write-Host "Example: 1 3 5 for first, third and fifth environments"
            $selection = Read-Host "Selection"
            
            $selectedIndices = $selection -split ' ' | ForEach-Object { [int]$_ - 1 }
            return $selectedIndices | ForEach-Object { $environments[$_] }
        }
        default {
            Write-Host "Invalid selection. Exiting..."
            exit
        }
    }
}

# function to update all KeyVault values
function KeyVault-UpdateAll {
    # Read the configuration file
    $config = Get-Content -Path "$workingDirectory/kvConfig.json" | ConvertFrom-Json
    
    # Get selected environments
    $selectedEnvironments = Select-Environments -environments $config.environments
    
    if ($null -eq $selectedEnvironments -or $selectedEnvironments.Count -eq 0) {
        Write-Host "No environments selected. Exiting..."
        return
    }

    Write-Host "`nUpdating the following environments:"
    $selectedEnvironments | ForEach-Object { Write-Host "- $($_.name)" }
    
    $confirmation = Read-Host "`nDo you want to continue? (y/n)"
    if ($confirmation -ne 'y') {
        Write-Host "Operation cancelled."
        return
    }

    foreach ($env in $selectedEnvironments) {
        Write-Host "`n    #########################################"
        Write-Host "    Updating KeyVault Values for $($env.name)"
        Write-Host "    #########################################"
        
        bulkAddKVValues -spName $env.spName `
                       -spPassword $env.spPassword `
                       -csv "$workingDirectory/$($env.csvFile)"
    }
}

KeyVault-UpdateAll