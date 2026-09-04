#!/usr/bin/env bash

set -xeuo pipefail

# Create service IAM roles
lstk aws iam create-role --role-name demo-role --assume-role-policy-document file://role.json
lstk aws iam put-role-policy --role-name demo-role --policy-name demo-policy --policy-document file://policy.json

# Create CodeConnection connection
lstk aws codeconnections create-connection --connection-name demo-connection --provider-type GitHub

# Create CodeBuild project
lstk aws codebuild create-project \
    --name demo-compile \
    --source type=CODEPIPELINE,buildspec="$(cat buildspec.yaml)" \
    --artifacts type=CODEPIPELINE \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:5.0,computeType=BUILD_GENERAL1_SMALL \
    --service-role arn:aws:iam::000000000000:role/demo-role

# Create pipeline artifact bucket
lstk aws s3 mb s3://artifact-bucket

# Create pipeline output bucket
lstk aws s3 mb s3://output-bucket

# Create pipeline
lstk aws codepipeline create-pipeline --pipeline file://./pipeline.json

# Check pipeline status
lstk aws codepipeline list-pipeline-executions --pipeline-name demo-pipeline

# Wait for pipeline to finish
status=
until [[ $status =~ Succeeded ]]; do
    status=$(lstk aws codepipeline list-pipeline-executions --pipeline-name demo-pipeline --output text --query pipelineExecutionSummaries[0].status)
    sleep 5
done

# Retrieve build
lstk aws s3 cp s3://output-bucket/fzf/fzf .

# Try build
file fzf
chmod +x fzf
./fzf --version
