# Download AntelopeIO/Leap Deb Packages

Now that `AntelopeIO/leap` produces debian packages on every pull request, we can download those packages to get the binaries for a specific commit level. This script allows you to select a github PR and get the associated debian package with the leap binaries. By default the most recent github PR is used.

## Prerequisite

You need a read-only bearer token for public repositories. You can get one on github see [managing-your-personal-access-tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) to generate a token

## Usage

Typical usage is to specify the `release` branch and provide your token. This will get the debian packages for the most recent build on that branch. By default the debian package is downloaded to the `.` directory

`python3 download_artifacts.py --branch release/5.0 --bearer-token github_XXXXX`

### Options
- `branch` default is `release/5.0` branch to get latest artifact
- `bearer-token` github bearer token to access github api
- `download-dir` default is `.`. director to save download
- `select-pr` default is `False` boolean option that allows command line selection of PR and associated commit sha.
- `stop-after-prs` default is `False` boolean option prints the PR list and exits
- `pr-search-length` default is `10` number of PRs to show in the list, higher number will go further back in time
- `debug` default is `False`, prints information on background actions and data to stderr

## Selecting a PR

When selecting a PR enter the index number. The index number starts each line and is enclosed in `[]`. For example running
`python3 download_artifacts.py --branch release/5.0 --bearer-token github_XXX --select-pr`

You will see the following: **NOTE** The cmd line selection `1` one for the most recent PR with sha `04774eb7726ae95a6cb795b493fcf0f25021bc5f`

```
[1] PR 2029 [5.0] P2P: Pause net_plugin during snapshot write
		Merge time Jan 04 2024 06PM
		SHA 04774eb7726ae95a6cb795b493fcf0f25021bc5f
[2] PR 2038 [5.0] only register prometheus handlers when `prometheus_plugin` enabled; fixing memory leak
		Merge time Jan 04 2024 06PM
		SHA 31f7bc45a437acce0d459570386e24a36bba1d0a
[3] PR 2036 [5.0] Version to Bump 5.0.0 stable
		Merge time Jan 03 2024 11PM
		SHA e2fda3bac4edc25c1af640260b4f8fcf4a83ac22
[4] PR 2026 [5.0] remove per-row `tellp()` during snapshot creation boosting performance
		Merge time Jan 02 2024 09PM
		SHA 91dea834da323183738669cbcc6902424926a4bc
[5] PR 1978 [5.0] (chainbase) use `free()` -- not `delete` -- for `aligned_alloc()` pointer
		Merge time Dec 22 2023 01AM
		SHA 574f430c59f0f3e2ee37af839b448351868aebaf
[6] PR 2015 [5.0] Test: Check for unlinkable blocks while syncing - 2
		Merge time Dec 21 2023 02PM
		SHA debef7f383e994a9f169760e5b7b2223b1448537
[7] PR 2008 [5.0] Test: Check for unlinkable blocks while syncing
		Merge time Dec 20 2023 11PM
		SHA 4becdd5d9f5dfb063119d5970aa7701e2fb06774
[8] PR 2007 [5.0] Fix unlinkable block exceptions when block-log-retain-blocks = 0
		Merge time Dec 20 2023 02PM
		SHA 89e2db14d0bac644b4a4dbaf9a0e33381789fa1c
[9] PR 2000 [5.0] Test: Fix trx_generator handling of connection lost
		Merge time Dec 19 2023 01PM
		SHA a469b696372148a636d0e62ae8c85b01a0e6f3d7
[10] PR 1986 [5.0] Add BLS_PRIMITIVES2 to bios-boot-tutorial.py
		Merge time Dec 19 2023 01AM
		SHA 091bd3446854cffc57ffbab81f4f4f09f5d8f058
Please Select a PR >>1
Download Complete corresponding commit: 04774eb7726ae95a6cb795b493fcf0f25021bc5f
```
