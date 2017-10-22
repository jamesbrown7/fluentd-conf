# Fluentd (td-agent) updater

## Setup

### Host

1. Install the fluentd-updater.sh script to the fluentd host with 0755 permissions
1. Add a call to fluentd-updater.sh to the fluentd host's root account crontab, set to run every
five minutes.

### AWS

1. Create a new S3 bucket, named fluentd.conf.bucket (if you change this name, modify value in
S3BUCKET_NAME within the fluentd-updater.sh script)
1. Add a new policy to give the fluentd host read access to the fluentd config storage
bucket:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1508702513000",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::fluentd.conf.bucket",
                "arn:aws:s3:::fluentd.conf.bucket/*"
            ]
        }
    ]
}
```
3. Add the fluentd host to a role that includes the policy. Or, if the host is already
associated with an IAM role, simply add the above policy to the existing role.
