

BEARER_TOKEN="XXXYYY"
BRANCH=release/5.0
# Step 1. Query the workflows for the branch and event you want
curl -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer BEARER_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" \
https://api.github.com/repos/AntelopeIO/leap/actions/runs\?branch\=BRANCH\&event\=pull_request

# Step 2. Iterate over "workflow_runs" look for name = "Build & Test". Grab the workflow "id" and  "updated_at" from that action
# return list of id/updated tuple. find id with the latest updated date 
#
#
# {
#      "id": 6658541217,
#      "name": "Build & Test",
#      "updated_at": "2023-11-21T22:00:28Z"
# }

# Step 3. Get all the artifacts from that workflow
curl -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer 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" -H "X-GitHub-Api-Version: 2022-11-28" \
https://api.github.com/repos/AntelopeIO/leap/actions/runs/6949985088/artifacts

# Step 4. iterate over list "artifacts" look for name = "leap-deb-amd64" and return "id" and "archive_download_url"

# Step 5. download the "archive_download_url" and follow redirects
# May need to call /zip to get redirect to real asset download url
curl -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer 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" -H "X-GitHub-Api-Version: 2022-11-28" \
https://api.github.com/repos/AntelopeIO/leap/actions/artifacts/1065564215/zip
