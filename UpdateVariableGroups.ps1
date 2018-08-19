$personalAccessToken = "YOUR_PAT_TOKEN_GOES_HERE"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "",$personalAccessToken)))
$accountname = "YOUR_ACCOUNT_NAME_GOES_HERE"
$variableGroupName = "YOUR_VARIABLE_GROUP_NAME_GOES_HERE"
$projectName = "YOUR_PROJECT_NAME_GOES_HERE"

$vstsUri = "https://" + $accountname + ".visualstudio.com/"

# GET https://{accountName}.visualstudio.com/{project}/_apis/distributedtask/variablegroups?api-version=4.1-preview.1
# get variable groups and find our one
$call = $vstsUri + $projectName + "/_apis/distributedtask/variablegroups?api-version=4.1-preview.1"
$result = Invoke-RestMethod -Uri $call -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

$groupId = (-1)
foreach($group in $result.value) {
    if($group.name.Equals($variableGroupName)) {

        $groupId = $group.id
        break;
    }
}

# if we can't find the group, throw an error
if($groupId -lt 0) {

    throw("Couldn't find group")

}

# get full json for our group
$call = $vstsUri + $projectName + "/_apis/distributedtask/variablegroups/" + $groupId + "?api-version=4.1-preview.1"
$group = Invoke-RestMethod -Uri $call -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

# https://docs.microsoft.com/en-us/rest/api/vsts/_apis/distributedtask/variablegroups/variablegroups/update?view=vsts-rest-4.1
# update variable group by id
$group.variables.MySecret = @{}
$group.variables.MySecret += @{"value" = "New Secret Value"}
$group.variables.MySecret += @{"isSecret" = $true}

$call = $vstsUri + $projectName + "/_apis/distributedtask/variablegroups/" + $groupId + "?api-version=4.1-preview.1"
$result = Invoke-RestMethod -Uri $call -Method Put -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Body (ConvertTo-Json $group -Depth 10) 
