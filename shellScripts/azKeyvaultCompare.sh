########################################################################################
# Brief Description: Azure Keyvault Secret Value Comparison                            #
# Created by Tim Jones 02.27.2025                                                      #
# Version 1.0                                                                          #
# Description: Each production keyvault should take roughly 1 hour to parse. This      #
#              script will let you know once it begins each keyvault.                  #
# Note: The keyvaults array variable needs to be seperated with a space and keyvault   #
#       names should be enclosed in quotes. i.e. ("keyvault1" "keyvault2" ...)         #
########################################################################################
#!/bin/bash

#Set Variables
# Define the key vaults you want to compare
keyvaults=("keyvault1" "keyvault2")

# CSV output file name
output_file="secrets_comparison.csv"

# create CSV headers: first column is SecretName, then one for each key vault
header="SecretName"
for kv in "${keyvaults[@]}"; do
    header+=",$kv"
done
echo "$header" > "$output_file"

# Create a temporary directory for intermediate files
temp_dir=$(mktemp -d)

# For each key vault, create a temporary file that stores secret,value pairs
for kv in "${keyvaults[@]}"; do
    temp_file="$temp_dir/${kv}.csv"
    echo "Retrieving secrets from $kv..."
    # List secret names from the key vault
    secret_names=$(az keyvault secret list --vault-name "$kv" --query "[].name" -o tsv)
    
    # Create (or empty) the temporary file
    > "$temp_file"
    
    for secret in $secret_names; do
        # Get the secret value (suppress errors if not found)
        value=$(az keyvault secret show --vault-name "$kv" --name "$secret" --query "value" -o tsv 2>/dev/null)
        # Write the secret and its value to the temp file (CSV format)
        echo "$secret,$value" >> "$temp_file"
    done
    
    # Sort the temporary file by secret name for consistency
    sort -t, -k1,1 "$temp_file" -o "$temp_file"
done

# Create a file that holds the union of all secret names
all_secrets_file="$temp_dir/all_secrets.txt"
> "$all_secrets_file"
for kv in "${keyvaults[@]}"; do
    temp_file="$temp_dir/${kv}.csv"
    cut -d, -f1 "$temp_file" >> "$all_secrets_file"
done
sort -u "$all_secrets_file" -o "$all_secrets_file"

# For each unique secret, build a CSV line that includes values from all key vaults
while IFS= read -r secret; do
    line="\"$secret\""
    for kv in "${keyvaults[@]}"; do
        temp_file="$temp_dir/${kv}.csv"
        # Get the value for this secret from the corresponding key vault file (if present)
        value=$(grep -F "$secret," "$temp_file" | head -n 1 | cut -d, -f2-)
        line+=",\"$value\""
    done
    echo "$line" >> "$output_file"
done < "$all_secrets_file"

echo "Comparison CSV created: $output_file"

# Clean up temporary files
rm -r "$temp_dir"