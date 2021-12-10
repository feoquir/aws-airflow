import os,boto3,json
# Boto3 Client for S3
s3 = boto3.client("s3")

def dag_sync(event,context):
    try:
        # Event Elements Definition attempt (S3 Bucket Name and Object Name)
        bucket_name =  event['Records'][0]["s3"]["bucket"]["name"]
        object_name =  event['Records'][0]["s3"]["object"]["key"]
        # Determine the actual file name by removing the Object's Prefix
        if '/' in object_name:
            file_name = object_name.split('/')[-1]
        else:
            file_name = object_name
        # SQL File Detection
        if ".sql" in file_name:
            # EFS SQL Location definition
            file_name = 'sql/' + file_name
            if not os.path.exists("/mnt/efs/sql"):
                os.makedirs("/mnt/efs/sql")
        # Event analysis - Object Creation vs. Object Deletion
        if "ObjectCreated" in event['Records'][0]['eventName']:
            with open('/mnt/efs/{}'.format(file_name), 'wb') as data:
                s3.download_fileobj(bucket_name, object_name, data)
            return { "statusCode" : 200, "body" : json.dumps("File Uploaded Successfully") }
        elif "ObjectRemoved" in event['Records'][0]['eventName']:
            os.remove('/mnt/efs/{}'.format(file_name))
            return { "statusCode" : 200, "body" : json.dumps("File Removed Successfully") }
    except:
        # Exception when an event is not properly configured
        return { "statusCode" : 400, "body" : json.dumps("No Proper Event Defined") }