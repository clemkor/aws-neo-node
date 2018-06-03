import boto3
import logging
import requests
import os

logging.getLogger('botocore').setLevel(logging.CRITICAL)
logging.getLogger('boto3').setLevel(logging.CRITICAL)

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def refresh_blockchain_archive(event, context):
    url = os.environ['BLOCKCHAIN_ARCHIVE_URL']
    bucket = os.environ['BLOCKCHAIN_ARCHIVE_BUCKET_NAME']
    key = os.environ['BLOCKCHAIN_ARCHIVE_KEY']
    chunk_size_bytes = int(os.environ['BLOCKCHAIN_ARCHIVE_CHUNK_SIZE_BYTES'])

    logger.info(
        'Refreshing blockchain archive from: %s into %s/%s '
        'in chunks of size %s',
        url,
        bucket,
        key,
        chunk_size_bytes)

    s3 = boto3.client('s3')

    multi_part_upload = s3.create_multipart_upload(
        Bucket=bucket,
        Key=key,
        ServerSideEncryption='AES256')

    archive_response = requests.get(url, stream=True)

    part_number = 0
    part_info = {
        'Parts': []
    }

    for archive_chunk in archive_response.iter_content(
            chunk_size=chunk_size_bytes):
        part_number += 1

        logger.info('Uploading chunk: %s', part_number)

        part = s3.upload_part(
            Bucket=bucket,
            Key=key,
            PartNumber=part_number,
            UploadId=multi_part_upload['UploadId'],
            Body=archive_chunk)

        part_etag = part['ETag']
        part_info['Parts'].append({
            'PartNumber': part_number,
            'ETag': part_etag
        })

        logger.info('Uploaded chunk: %s with etag: %s', part_number, part_etag)

    s3.complete_multipart_upload(
        Bucket=bucket,
        Key=key,
        UploadId=multi_part_upload['UploadId'],
        MultipartUpload=part_info)

    logger.info('Refresh completed.')
