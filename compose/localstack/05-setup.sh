#!/bin/bash

aws --endpoint-url=http://localhost:4566 s3 mb s3://test-results
aws --endpoint-url=http://localhost:4566 sqs create-queue --region $AWS_REGION --queue-name example-queue
aws --endpoint-url=http://localhost:4566 sns create-topic --region $AWS_REGION --name example-topic

# --- cdp-uploader local dependencies ---
# Consumer bucket the backend requests uploads into (CDP_UPLOADER_BUCKET) and the
# uploader's quarantine bucket for unscanned files.
aws --endpoint-url=http://localhost:4566 s3 mb s3://boundaries
aws --endpoint-url=http://localhost:4566 s3 mb s3://cdp-uploader-quarantine

# SQS queues used by the uploader's (mock) virus-scan pipeline.
aws --endpoint-url=http://localhost:4566 sqs create-queue --region $AWS_REGION --queue-name mock-clamav
aws --endpoint-url=http://localhost:4566 sqs create-queue --region $AWS_REGION --queue-name cdp-clamav-results
aws --endpoint-url=http://localhost:4566 sqs create-queue --region $AWS_REGION --queue-name cdp-uploader-download-requests
aws --endpoint-url=http://localhost:4566 sqs create-queue --region $AWS_REGION --queue-name cdp-uploader-scan-results-callback.fifo --attributes FifoQueue=true,ContentBasedDeduplication=true

# SNS topic the backend publishes to when a quote is submitted
# (POST /quotes -> SNS_TOPIC_ARN_QUOTE_ESTIMATE_REQUEST). Used by the
# submit-quote performance scenario.
aws --endpoint-url=http://localhost:4566 sns create-topic --region $AWS_REGION --name nrf-quote-estimate-request
