## WHAT DOES THIS SCRIPT DO? ####################################################################
# It iterates through all the projects and all their build definitions in a given VSTS account  #
# and configures a given retention policy. In this example I have hard-coded a retention policy #
# for all pull request builds, but this can easily be customised to meet different needs.       #
# This script is based on a question I got around configuring pull request retention policies   # 
# across an account (VSTS) or collection (TFS).                                                 #
#################################################################################################

$personalAccessToken = "<your personal access token>"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "",$personalAccessToken)))
$accountname = "<your account name>"

# get all projects
$call = "https://" + $accountname + ".visualstudio.com/DefaultCollection/_apis/projects"
$result = Invoke-RestMethod -Uri $call -Method Get -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

$allProjects = $result.value

# iterate through all projects 
foreach($project in $allProjects) {

    # get all build definitions in each project
    $call = "https://" + $accountname + ".visualstudio.com/" + $project.id + "/_apis/build/definitions"
    $result = Invoke-RestMethod -Uri $call -Method Get -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

    $allDefinitions = $result.value

    # iterate through definitions
    foreach($definition in $allDefinitions) {
        
        # pull details on each definition (this contains the retention policy info we need)
        $definitionDetails = Invoke-RestMethod -Uri $definition.url -Method GET -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
        
        # convert the url to the url we're expecting for the definition update later
        $putUrl = $definition.url.Split("?")[0] + "?api-version=4.0"

        # remove any pull requests rule that already exists
        $retentionRules = $definitionDetails.retentionRules
        $definitionDetails.retentionRules = @()
        foreach($retentionRule in $retentionRules) {
            if($retentionRule.branches[0] -eq "+refs/pull/*") {
                continue
            }

            $definitionDetails.retentionRules += $retentionRule
        }

        # create the new rule
        $newRetentionRule = '{
        "branches":  [ "+refs/pull/*" ],
        "artifacts":  [ ],
        "artifactTypesToDelete":  [ "FilePath", "SymbolStore" ],
        "daysToKeep":  10,
        "minimumToKeep":  1,
        "deleteBuildRecord":  true,
        "deleteTestResults":  true
        }';
        $definitionDetails.retentionRules += ConvertFrom-Json $newRetentionRule

       Invoke-RestMethod -Body (ConvertTo-Json $definitionDetails -Depth 100) -Uri $putUrl -Method PUT -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
    }
}