#!/bin/bash

# Usage: ./upload_navdata_to_s3.sh <path_to_db_file> <s3_bucket> [aws_region] [s3_prefix] [base_url]

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Validate arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <path_to_db_file> <s3_bucket> [aws_region] [s3_prefix] [base_url]"
    echo "Example: $0 ./open-navdata.db my-bucket us-east-1 neoradar https://pkg.neoradar.app"
    exit 1
fi

DB_FILE="$1"
S3_BUCKET="$2"
AWS_REGION="${3:-$(aws configure get region)}"
S3_PREFIX="${4:-""}"
BASE_URL="${5:-""}"

# Validate DB file
if [ ! -f "$DB_FILE" ]; then
    echo "Error: Database file not found: $DB_FILE"
    exit 1
fi

# Validate AWS region is set
if [ -z "$AWS_REGION" ]; then
    echo "Error: AWS region not specified and not found in AWS config"
    echo "Please provide a region or configure it with: aws configure set region REGION"
    exit 1
fi

# Setup paths with prefix if provided
if [ -n "$S3_PREFIX" ]; then
    # Ensure the prefix doesn't have a trailing slash
    S3_PREFIX="${S3_PREFIX%/}"
    DB_S3_PATH="$S3_PREFIX/open-navdata.db"
    METADATA_S3_PATH="$S3_PREFIX/navdata.json"
else
    DB_S3_PATH="open-navdata.db"
    METADATA_S3_PATH="navdata.json"
fi

# Create temporary metadata file
TEMP_METADATA=$(mktemp)

# Calculate SHA-256 checksum
echo "Calculating checksum for $DB_FILE..."
CHECKSUM=$(sha256sum "$DB_FILE" | awk '{print $1}')
VERSION=$(date +"%Y.%m.%d")

# Create metadata file
echo "Creating metadata file..."
if [ -n "$BASE_URL" ]; then
    # Use custom base URL if provided
    # Ensure the base URL doesn't have a trailing slash
    BASE_URL="${BASE_URL%/}"
    
    
    DOWNLOAD_URL="$BASE_URL/open-navdata.db"
else
    # Use S3 URL if no base URL provided
    DOWNLOAD_URL="https://$S3_BUCKET.s3.$AWS_REGION.amazonaws.com/$DB_S3_PATH"
fi

cat > "$TEMP_METADATA" << EOF
{
  "version": "$VERSION",
  "checksum": "$CHECKSUM",
  "url": "$DOWNLOAD_URL"
}
EOF

echo "Metadata file contents:"
cat "$TEMP_METADATA"

# Upload the database file
echo "Uploading database file to S3..."
aws s3 cp "$DB_FILE" "s3://$S3_BUCKET/$DB_S3_PATH" --region "$AWS_REGION"
if [ $? -ne 0 ]; then
    echo "Error: Failed to upload database file to S3"
    rm "$TEMP_METADATA"
    exit 1
fi

# Upload metadata file
echo "Uploading metadata file to S3..."
aws s3 cp "$TEMP_METADATA" "s3://$S3_BUCKET/$METADATA_S3_PATH" --region "$AWS_REGION"
if [ $? -ne 0 ]; then
    echo "Error: Failed to upload metadata file to S3"
    rm "$TEMP_METADATA"
    exit 1
fi

# Make both files public
echo "Setting public-read ACL for database file..."
aws s3api put-object-acl --bucket "$S3_BUCKET" --key "$DB_S3_PATH" --acl public-read --region "$AWS_REGION"
if [ $? -ne 0 ]; then
    echo "Warning: Failed to set public-read ACL for database file"
fi

echo "Setting public-read ACL for metadata file..."
aws s3api put-object-acl --bucket "$S3_BUCKET" --key "$METADATA_S3_PATH" --acl public-read --region "$AWS_REGION"
if [ $? -ne 0 ]; then
    echo "Warning: Failed to set public-read ACL for metadata file"
fi

# Verify the URLs
DB_URL="https://$S3_BUCKET.s3.$AWS_REGION.amazonaws.com/$DB_S3_PATH"
METADATA_URL="https://$S3_BUCKET.s3.$AWS_REGION.amazonaws.com/$METADATA_S3_PATH"

echo ""
echo "Upload completed successfully!"
echo ""
echo "S3 File Locations:"
echo "Database: $DB_URL"
echo "Metadata: $METADATA_URL"
echo ""

if [ -n "$BASE_URL" ]; then
    echo "Custom URL in metadata:"
    echo "Database URL in metadata: $DOWNLOAD_URL"
fi

echo ""
echo "Please note: If you're using a custom domain for your S3 bucket, the actual URLs might differ."

# Clean up
rm "$TEMP_METADATA"
exit 0