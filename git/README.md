# Steps to Setup and Run Draft Release Notes

The `draft-release-notes.py` looks at all the code changes and creates a report. This is a great way of know what has happened and how the code base has changed over time.
`draft-release-notes.py` only looks at changes from a base, or starting point. Typically that starting point is a previous version. It could be a timeperiod, or a specific git commit hash. 

## Prerequisites 
Need to download and [install github command line tools](https://github.com/cli/cli?tab=readme-ov-file#installation).
- mac os `brew install gh` [Other Install Options](https://github.com/cli/cli?tab=readme-ov-file#macos)
- [Linux Install Options](https://github.com/cli/cli?tab=readme-ov-file#linux--bsd)
- [Windows Install Options](https://github.com/cli/cli?tab=readme-ov-file#windows)

You will need Python3 installed on your host. MacOS has python3 by default. Additional [Download and Install Instructions](https://www.python.org/downloads/) are on the python website.

## Clone repo
`git clone https://github.com/ericpassmore/helpers.git`
Extract the file and move it to a location that makes sense for you. You could leave it in the current directy as well. 
For example on Linux and MacOS
`mkdir $HOME/helpers/ && cp helpers/git/draft-release-notes.py $HOME/helpers/`

## Run 
You need to checkout the git repo you are insterested in creating release notes. Draft-release-notes works by querying the local git repo.
Here are the steps for Spring repo. 
- Clone `git clone https://github.com/AntelopeIO/spring.git`
- Enter directory `cd spring`
- Change to the release branch `git checkout release/1.0` 
- Run oneline summary `python3 $HOME/helpers/git/draft-release-notes.py lastweek --oneline`

The format for the command is `python3` `full path to draft-release-notes.py` `start either time period or release tag` `format`

## Starting Point 
The start is typically a release tag. For example `v1.0.2`. It could be a specific git commit hash for example `6f24190d03b57c33ba91b18e895c8b7d381cd296`
The staring point may also be a timepoint, for example `lastweek`

The starting point acts as the base, and only changes since that starting point are reported. This is usefull if you want to see
- all the changes since a specific release
- all the changes since lastweek 

### Format 
There are 4 output options 
- oneline - single line of summary text
- html - html representation of report
- full-html - shows related issues in addition to pull requests
- markdown - an example report ready to be modify for github release notes

## Typical UseCases 
Since `draft-release-notes.py` uses the local github instance, if you want to see all the changes in a specific branch, you only need to checkout that branch. 
For example if you wanted to see all the changes for the next release candidate, and that release canidate was on branch `release/1.0` You would do the following:
#### Release Candidate 
- `cd spring`
- `git checkout release/1.0`
- `git pull origing release/1.0`
- `python3 $HOME/helpers/git/draft-release-notes.py v1.0.2 --markdown`

#### Changes Last Week
- `cd spring`
- `git checkout main`
- `git pull origin main`
- `python3 $HOME/helpers/git/draft-release-notes.py lastweek --oneline`

#### Changes Since A PR
First find the commit hash for the PR.
- `cd spring`
- `git checkout main`
- `git pull origin main`
- `python3 $HOME/helpers/git/draft-release-notes.py 648ea46e395f354da2af7ba7a61d835f0cc31cb7 --oneline`

#### Changes Since v1.0.2 Up To A Specific Point
First find the commit hash for the stopping point 
- `cd spring`
- `git checkout main`
- `git pull origin main`
- `git checkout 648ea46e395f354da2af7ba7a61d835f0cc31cb7`
- `python3 $HOME/helpers/git/draft-release-notes.py v1.0.2 --full-html`
