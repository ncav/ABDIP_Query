# Prompt the user to enter the API key for AbuseIPDB
$apiKey = Read-Host "Enter your AbuseIPDB API key"

# Define a function to query the AbuseIPDB API
function Query-AbuseIPDB($ip) {
    # Build the URL for the AbuseIPDB API
    $url = "https://api.abuseipdb.com/api/v2/check?ipAddress=$ip&maxAgeInDays=90"

    # Create a new HTTP request with the API key in the headers
    $request = Invoke-WebRequest -Uri $url -Headers @{Key = $apiKey}

    # Convert the JSON response to a PowerShell object
    $response = ConvertFrom-Json $request.Content

    # Check if the address is listed in the API response
    if ($response.data.abuseConfidenceScore -gt 0) {
        # Extract the domain name and country code from the API response
        $domain = $response.data.domain
        $countryCode = $response.data.countryCode
            
        # Use the country code to get the country name from the API
        $countryUrl = "https://restcountries.com/v2/alpha/$countryCode"
        $countryRequest = Invoke-WebRequest -Uri $countryUrl
        $countryResponse = ConvertFrom-Json $countryRequest.Content
        $country = $countryResponse.name

        # Print a warning message to the user
        Write-Host "Warning: $ip ($domain, $country) is listed on the AbuseIPDB with a score of $($response.data.abuseConfidenceScore)"
    }
    else {
        Write-Host "$ip is not listed on the AbuseIPDB"
    }
}

# Display the menu
do {
    Write-Host "---------------------"
    Write-Host "AbuseIPDB Lookup Menu"
    Write-Host "1. Query a single IP"
    Write-Host "2. Query multiple IPs"
    Write-Host "3. Query netstat -ano Foreign Address Only"
    Write-Host "4. Exit"
    $choice = Read-Host "Enter your choice (1, 2, 3, or 4)"
    
    # Handle the user's choice
    switch ($choice) {
        1 {
            # Prompt the user to enter an IP address
            $ipAddress = Read-Host "Enter the IP address to check"
            
            # Query the AbuseIPDB API for the specified IP address
            Query-AbuseIPDB $ipAddress
        }
        2 {
            # Prompt the user to enter a list of IP addresses
            $ipList = Read-Host "Enter a comma-separated list of IP addresses to check"
            $ips = $ipList.Split(",").Trim()
            
            # Iterate through each IP address in the list
            foreach ($ip in $ips) {
                # Query the AbuseIPDB API for the current IP address
                Query-AbuseIPDB $ip
            }
        }
        3 {
    # Run the netstat command to get a list of active network connections
    $netstatOutput = netstat -ano
    
    # Extract the IP addresses from the netstat output using a regular expression
    $ips = [regex]::Matches($netstatOutput, "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}").Value | Sort-Object -Unique
    
    # Filter out private IP addresses
    $publicIps = @()
    foreach ($ip in $ips) {
        $ipBytes = [IPAddress]$ip
        if ($ipBytes.AddressFamily -eq "InterNetwork" -and
            !$ipBytes.AddressFamily.IsIPv6LinkLocal -and
            !$ipBytes.AddressFamily.IsIPv6Multicast -and
            !$ipBytes.AddressFamily.IsIPv6SiteLocal -and
            !$ipBytes.AddressFamily.IsIPv6Teredo -and
            !$ipBytes.AddressFamily.IsIPv6UniqueLocal -and
            !$ipBytes.IsIPv6SiteLocal -and
            !$ipBytes.IsIPv6Teredo -and
            !$ipBytes.IsIPv6LinkLocal -and
            $ipBytes.Address -notmatch "^127\." -and
            $ipBytes.Address -notmatch "^169\.254\." -and
            $ipBytes.Address -notmatch "^192\.168\." -and
            $ipBytes.Address -notmatch "^10\." -and
            $ipBytes.Address -notmatch "^172\.(1[6-9]|2[0-9]|3[0-1])\.")
        {
            $publicIps += $ip
        }
    }

    # Iterate through each public IP address in the list
    foreach ($ip in $publicIps) {
        # Query the AbuseIPDB API for the current IP address
        Query-AbuseIPDB $ip
        }
    }
        4 {
            # Exit the script
            break
        }
        default {
            # Invalid choice
            Write-Host "Invalid choice. Please enter a valid option (1, 2, 3, or 4)."
        }
    }
} while ($true)