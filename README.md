# HealthCare-Website
Transition HealthCare North's website from its current costly and high-maintenance cloud server setup to a more economical and efficient AWS service, specifically leveraging a static S3 website.

#Diagram-pending

# Naming Standards
This section is designed to implement a clear and concise set of naming standards for AWS resources, as well as a folder structure for this repository.

## Resource naming conventions
Name the resources in the order listed below separated by a hyphen:

1. Project name - Healthcare Website abbreviated to **hcw**
2. Purpose/description - For example: **terraform-state** or **website-bucket**
3. Environment (if applicable) - **dev** or **prod**
4. Extra characters if necessary with S3 buckets to keep names unique

The same bucket can be used for all state files, so there is no need for **dev** or **prod** with this resource, same goes for the DynamoDB table for state locking

### Example:
An S3 bucket for the website in the dev environment could be named:

hcw-website-bucket-dev-87332

## Repository Folder Structure
Given that terraform configurations will exist for multiple configurations and environments, create a separate folder for each configuration and environment. Place a descriptive name followed by either the **dev** or **prod** environments. 

A suitable name for the folder containing the CI pipeline for the Prod environment could be:

CI_pipeline_prod

## Terraform Remote state with distinct state files
The same bucket can be used for multiple state files, by specififying the desired S3 key in each configuration like so:

~~~
terraform {
  backend "s3" {
    bucket = "hcw-terraform-state-82734"
    encrypt = true    
    dynamodb_table = "hcw-state-locks"
    key    = "website-bucket/dev/terraform.tfstate"
    region = "us-east-1"
  }
}
~~~

In the above example, a similar naming convention has been used for the bucket key, with the exception of the project name, since that will be present in the bucket name itself. 

# Implement Pull Request Workflow

A pull request (PR) is opened by a GitHub project contributor to gain permission (approval) to have their contribution merged from their repository branch into the project's repository base (main) branch. This process allows asynchronous collaboration while maintaining isolated development environments between individual contributors.

## Create a Pull Request Template

Creating a pull request template can provide content to include in a pull request.  A PR template is simply a file named `pull_request_template` followed by a `.md` or `.txt` extension.  It can be customized to create standardized pull requests based on specific criteria and be placed in the `root`, `dev`, or `.github` directories.

Some basic universal examples:

**Please consider the following steps before submitting a PR**

1. **Confirm PR is not a duplicate**

2. **If not, confirm that:**

    - Your changes were created in a separate branch

    - Include a descriptive commit message

    - test (if applicable)

3. **Open Pull Request**

    - Confirm target branch

    - Create a descriptive PR title

    - Describe proposed changes

    - Add `@mentions` of the person or team responsible for review

***Remove template before submitting.***
