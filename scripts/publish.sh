#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd $DIR > /dev/null

source common.sh

pushd ..  > /dev/null

case "$1" in
  prod)
    BUCKET=s3://customs-docs.shipamax-api.com
    CLOUDFRONT_DISTRIBUTION=E1G853F7ECL2P7
    ;;
  staging)
    BUCKET=s3://customs-docs-staging.shipamax-api.com
    CLOUDFRONT_DISTRIBUTION=XXX
    ;;
  *)
    echo "Must specify deployment type."
    echo "Usage: $0 {prod|staging}"
    exit 1
esac

AWS_ACCOUNT=$(get_aws_account)
echo "AWS Account: '$AWS_ACCOUNT'"
if [ "$AWS_ACCOUNT" != "freightforwarding" ]; then
	echo "Wrong AWS account: '$AWS_ACCOUNT'. Double check that the correct AWS credentials are set."
	exit
fi

export DEPLOY_ENV=$1

HASH=`git rev-parse HEAD` # if error, run: git tag -a v0.0 -m "Version init"
BRANCH=`git branch --no-color | grep \* | cut -d ' ' -f2`
HOST=`hostname`

###################

echo "Building"
bundle install
bundle exec middleman build --clean

echo "Uploading to S3"
aws s3 sync build/ $BUCKET

echo "Invalidating cache"
invalidate_cloudfront_cache $CLOUDFRONT_DISTRIBUTION

echo "Broadcast deployment"
slack_notify "Customs declaration API docs deployed to $DEPLOY_ENV by $USER ($BRANCH/$HASH)"

popd > /dev/null
popd > /dev/null

echo "Done"
