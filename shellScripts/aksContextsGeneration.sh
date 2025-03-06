########################################################################################
# Brief Description: Quickly add all AKS clusters to your kube config file.            #
# Created by Tim Jones 06.14.2022                                                      #
# Version .1                                                                           #
########################################################################################
#!/bin/bash

#Set Variables
timeStamp=$(date +%m-%d-%y-%H_%M_%S)
logpath="/var/log/"
logFile="aksGen_${timeStamp}".log
contextList="./contextList.txt"
#Logfile setup
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

#Functions
dateStamp(){
    date +%m-%d-%y-%H_%M_%S
}

#getting all subscriptions and counting the total
listCount=$(az account list | jq -r '.[].name' | wc -l)

#while loop to run through necessary tasks on all subscriptions with nodes.
while [ $listCount -ne -1 ];
    do
    #normalize count to work with array values
    ((listCount--))
    #Get account subscription name from array call value 
    accountSubscription=$(az account list | jq -r ".[$listCount].name")
    dateStamp >> $logFile
    echo "Getting account list for subscription $accountSubscription..." | tee -a $logFile
    #Check to see if there is an active cluster
    aksActive=$(az aks list --subscription "$accountSubscription" | jq '.' | awk ' { gsub (/ /,""); print }')
        if [ -z "$aksActive" ]; then
            dateStamp | xargs echo "Subcription $accountSubscription does not have any AKS cluster..." | tee >> $logFile
        else
            #count clusters in subscription
            declare -i clusterCount=$(az aks list --subscription "$accountSubscription" | jq '.[].name' | wc -l | awk ' { gsub (/ /,""); print }')
            #Print out the details of the subscriptions clusters
            while [ $clusterCount -gt 0 ];
            do
                #Decrement clusterCount variable for array lookup
                ((clusterCount--))
                #Count nodes in Cluster
                nodeCount=$(az aks list --subscription "$accountSubscription" | jq -r ".[$clusterCount] | .agentPoolProfiles | .[] | .count")
                dateStamp | xargs echo "The node count for subcription $accountSubscription is $nodeCount..." | tee >> $logFile
                #Get cluster Information
                clusterName=$(az aks list --subscription "$accountSubscription" | jq -r ".[$clusterCount].name")
                #Check if context exists for cluster
                contextCheck=$(cat ~/.kube/config | grep "cluster: $clusterName" | awk '{ print $2 }')
                if [ "$contextCheck" == "$clusterName" ]; then
                    dateStamp | xargs echo "The context $clusterName is already in your kube config file   " | tee -a $logFile
                else
                    resourceGroup=$(az aks list --subscription "$accountSubscription" | jq -r ".[$clusterCount].resourceGroup")
                    #Add the cluster to your local kubeconfig and
                    az account set --subscription "$accountSubscription"
                    echo "The context $clusterName is being added into your kube config file."
                    az aks get-credentials --resource-group $resourceGroup --name $clusterName && \
                        dateStamp | xargs echo "The context $clusterName is was succesfully added into your kube config file..." | tee >> $logFile
                    echo $clusterName >> $contextList
                fi    
            done
        fi
    done
#List contexts added
    echo "The following contexts have been added to your kube config file:" | tee -a $logFile
    $contextList | tee -a $logFile
#Place logfile in the Log path specified.
    mv $logFile $logPath