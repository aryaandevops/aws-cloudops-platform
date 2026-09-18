#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="012646746635"
ECR_REPOSITORY="aws-cloudops-app"
ASG_NAME="aws-cloudops-dev-asg"
LAUNCH_TEMPLATE_ID="lt-0428d7457034c6e96"
IMAGE_TAG="${1:?Image tag is required}"

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

echo "Deploying image: ${IMAGE}"

CURRENT_VERSION=$(aws ec2 describe-launch-template-versions \
  --launch-template-id "$LAUNCH_TEMPLATE_ID" \
  --versions '$Latest' \
  --region "$AWS_REGION" \
  --query 'LaunchTemplateVersions[0].VersionNumber' \
  --output text)

echo "Current Launch Template version: ${CURRENT_VERSION}"

USER_DATA=$(aws ec2 describe-launch-template-versions \
  --launch-template-id "$LAUNCH_TEMPLATE_ID" \
  --versions "$CURRENT_VERSION" \
  --region "$AWS_REGION" \
  --query 'LaunchTemplateVersions[0].LaunchTemplateData.UserData' \
  --output text)

DECODED_USER_DATA=$(printf '%s' "$USER_DATA" | base64 -d)

UPDATED_USER_DATA=$(printf '%s' "$DECODED_USER_DATA" | sed \
  -E "s#(aws-cloudops-app:)[^\"[:space:]]+#\1${IMAGE_TAG}#g")

ENCODED_USER_DATA=$(printf '%s' "$UPDATED_USER_DATA" | base64 -w 0)

LAUNCH_TEMPLATE_DATA=$(printf '{"UserData":"%s"}' "$ENCODED_USER_DATA")

NEW_VERSION=$(aws ec2 create-launch-template-version \
  --launch-template-id "$LAUNCH_TEMPLATE_ID" \
  --source-version "$CURRENT_VERSION" \
  --launch-template-data "$LAUNCH_TEMPLATE_DATA" \
  --region "$AWS_REGION" \
  --query 'LaunchTemplateVersion.VersionNumber' \
  --output text)

echo "Created Launch Template version: ${NEW_VERSION}"

aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$ASG_NAME" \
  --launch-template "LaunchTemplateId=${LAUNCH_TEMPLATE_ID},Version=${NEW_VERSION}" \
  --region "$AWS_REGION"

echo "Updated ASG to Launch Template version: ${NEW_VERSION}"

CURRENT_REFRESH=$(aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name "$ASG_NAME" \
  --region "$AWS_REGION" \
  --query 'InstanceRefreshes[?Status==`Pending` || Status==`InProgress`].InstanceRefreshId | [0]' \
  --output text)

if [ "$CURRENT_REFRESH" != "None" ] && [ -n "$CURRENT_REFRESH" ]; then
  echo "Instance refresh already in progress: ${CURRENT_REFRESH}"
  echo "Skipping new instance refresh."
else
  REFRESH_ID=$(aws autoscaling start-instance-refresh \
    --auto-scaling-group-name "$ASG_NAME" \
    --preferences MinHealthyPercentage=100,InstanceWarmup=120 \
    --region "$AWS_REGION" \
    --query 'InstanceRefreshId' \
    --output text)

  echo "Instance refresh started: ${REFRESH_ID}"
fi

echo "Deployment completed successfully."
