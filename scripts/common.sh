set -Eeuo pipefail

function slack_notify() {
  MESSAGE=$1

  if [ -z "$MESSAGE" ]; then
    echo "Slack Notifier: No message provided"
    return
  fi

  if [ -z "$SLACK_DEPLOY_WEBHOOK" ]; then
    echo "Slack Notifier: No webhook URL found. Set 'SLACK_DEPLOY_WEBHOOK' env variable"
    return
  fi

  curl -X POST -H "'Content-type: application/json'" "$SLACK_DEPLOY_WEBHOOK" --data "{\"text\":\"$MESSAGE\"}"
}

function get_aws_account() {
  aws iam list-account-aliases --output text --query 'AccountAliases[0]' | sed 's/\"//g'
}

function invalidate_cloudfront_cache() {
  DISTRIBUTION=$1

  if [ -z "$DISTRIBUTION" ]; then
    echo "Cloudfront Cache Invalidator: No distribution ID provided"
    return
  fi

  aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION" --paths '/*'
}