#!/bin/bash

# AWS S3 bucket name
bucket_name="brandon-chesser-cloud-resume-challenge"

# Local file path
index_html="Website/index.html"
index_js="Website/index.js"

# AWS CLI command to upload the file
aws s3 cp "$index_html" "s3://$bucket_name/" --profile AdministratorAccess-395067379223
aws s3 cp "$index_js" "s3://$bucket_name/" --profile AdministratorAccess-395067379223

# Check if the upload was successful
if [ $? -eq 0 ]; then
  echo "File uploaded successfully to S3 bucket: $bucket_name"
else
  echo "Error uploading file to S3 bucket: $bucket_name"
fi
