{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3FullAccess",
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${s3_arn}/*",
        "${s3_arn}*"
      ]
    },
    {
      "Sid": "EFSFullAccess",
      "Action": [
        "elasticfilesystem:*"
      ],
      "Effect": "Allow",
      "Resource": 
        "${efs_arn}"
    }
  ]
}