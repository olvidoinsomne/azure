########################################################################################
# Brief Description: bulk add of security group to IAM role                            #
# Created by Tim Jones 04.25.2025                                                      #
# Version .1                                                                           #
########################################################################################
#!/bin/bash

#Set Variables
timeStamp=$(date +%m-%d-%y-%H_%M_%S)
logpath="/var/log/script-logs/"
logFile="${logpath}_${timeStamp}".log
groupID="" # Target Security group ID

## Ensure logFile can be written
if [ -d "${logpath}" ]; then
    echo "" > /dev/null
else
    #Check if running as root, if not prompt for password
    if [[ "$EUID" = 0 ]]; then
        echo "" > /dev/null
    else
        echo "As the log folder does not exist, we need to create it with elevated permissions."
        loggedInUser=$(whoami)
    fi
    #Create directory
    sudo mkdir "${logpath}"
    #Assign ownership of logged in user to logpath.
    sudo chown -R $loggedInUser $logpath    
fi
##Create the logFile
touch $logFile

for subscriptionid in $(az account list --only-show-errors --query "[].id" -o tsv); do
    #Get the subscription name
    subscriptionName=$(az account list --only-show-errors --query "[?id=='$subscriptionid'].name" -o tsv)
    #Get the role ID for Security Admin
    echo Adding Security Admin role to group $groupID in subscription $subscriptionName \| $subscriptionid
    echo "{ 
    \"log\": \"Adding Security Admin role to group $groupID in subscription $subscriptionName \| $subscriptionid\"
}" >> $logFile
    az role assignment create --assignee $groupID --role "Security Admin" --scope /subscriptions/$subscriptionid >> $logFile
done