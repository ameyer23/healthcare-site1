## Use the pipeline_dev branch to develop pipeline in development environment. 

To test that tests run on pull requests, create a new branch from pipeline_dev and create a pull request to merge changes into pipeline_dev. 

There is a separate state file for the pipeline_dev environment, although the same two deployment buckets are used for both.

## Merging with main
1. Once changes are working and merged to pipeline_dev, keep working branch open and alter for merge with main
2. Change required variables (see below)
3. Run terraform plan and apply
- If your aws profile (with temporary credentials) is not called 'temp', run terraform commands with -var 'aws_profile=<profile_name>' option, or create a .tfvars file
- You will be prompted for a GitHub personal access token. These are created on an individual level and any that give access to all repositories work. It is recommended to create a new token with access only to this repository.
4. Add and commit changes
5. Push current branch to remote
6. Create a pull request to merge with main
7. Delete working branch

## The following variable values need to be changed in variables.tf before merging with main
- environment = **dev** → **prod** 
- github_branch = **pipeline_dev** → **main**