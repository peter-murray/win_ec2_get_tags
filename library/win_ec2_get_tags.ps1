#!powershell
#
# WANT_JSON
# POWERSHELL_COMMON

$AWS_REGIONS = ('ap-northeast-1',
                'ap-southeast-1',
                'ap-southeast-2',
                'eu-central-1',
                'eu-west-1',
                'eu-west-2',
                'sa-east-1',
                'us-east-1',
                'us-west-1',
                'us-west-2',
                'us-gov-west-1')

Function Fetch-Content($uri)
{
    Try
    {
        $r = Invoke-WebRequest -Uri $uri -Method GET
        If ($r.StatusCode -ne 200)
        {
            Fail-Json (New-Object psobject) "Unexpected status code: $status for $uri"
            #$content = $null
            #$content = $r.Content

        }
        return $r.Content
    }
    Catch
    {
        return $null
    }
}

Function Get-Region()
{
    $zone = Fetch-Content("http://169.254.169.254/latest/meta-data/placement/availability-zone")
    $region = $null

    If ( $zone -ne $null)
    {
        $region = $zone
        ForEach($r in $AWS_REGIONS) {
            If ($zone.StartsWith($r))
            {
                $region = $r
                break
            }
        }
    }

    return $region
}

Function Get-Tags($instance, $region)
{
    $ec2Tags = Get-EC2Tag -Region $region -Filter @{ Name="resource-id";Values=$instance }
    $tags = @{}

    If ($ec2Tags -ne $null)
    {
        ForEach ($tag in $ec2Tags) {
            $tags.Add($tag.Key, $tag.Value)
        }
    }

    return $tags
}

$instanceId = Fetch-Content("http://169.254.169.254/latest/meta-data/instance-id")
$region = Get-Region

$tags = Get-Tags -instance $instanceId -region $region

$result = New-Object psobject @{
    changed = $FALSE
    tags = $tags
};

$result.changed = $TRUE
Exit-Json $result
