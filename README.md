# mc-aws

Consists of mc server components, a cli tool `mc-server.sh` a user-data for the spot instance and a launch config template.

### How it works:
Request a spot instance based off the provided launch configuration and the arbitrary instance type.

What to look for in terms of server suitable for mc:
* Computing power
* Network performance
* At least 2 gigs of RAM

Satisfiable by a c5/c5d type ec2 instance.
We use spot instance, therefore have to take care of saving and loading the game, for this we use tarballs.
Kinda best choice for this: c5d.large. Relatively cheap, by ca. 70% than usual price, $0.033 + TAX of course.

### Launch config example
```
{
    "SecurityGroupIds": [
        "SC_GROUP_FOR_SSH_AND_PORT_25565"
    ],
    "EbsOptimized": true,
    "IamInstanceProfile": {
        "YOUR_INSTANCE_PROFILE_PREFERABLY_TO_FULL_S3_ACCESS"
    },
    "ImageId": "AMI_DEPENDS_ON_THE_REGION",
    "InstanceType": "{instance_type}", // This comes from the cli
    "KeyName": "YOUR_REGISTERED_SSH_KEY",
    "Monitoring": {
        "Enabled": false
    },
    "UserData": "{user_data}" // This also comes from the cli
}
```
Copy and rename the launch config to **local**.whatever.json, fill the required parts and you are good to go.

Use the cli tool, run `./mc-server.sh` for help, or with help, or --help doesn't really matter. 

## Important notes

Currently only one spot request supported. That being said, I'm not responsible for any error caused by leaving the aforementioned declaration out of account.

The linux os has to be distro of CentOS. Reliability-wise I would suggest either Amazon Linux AMI 2018 or Amazon Linux AMI 2.
Unless one modifies the user-data, could not proceed with other distros. 

## Future plans

1. Ability to handle multiple spot request.
2. Compatiblity with other distros if necessary at all.

## For newbies

* All these are region dependent. What does that mean? Security groups, ssh key, ami has to be readded per region.
* Create an aws account [here](https://aws.amazon.com/resources/create-account/?tag=duckduckgo-d-20)
* [Configure you aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
    * Configure and manage your region from the cli, using `aws configure`
* Login and register an [ssh key](https://docs.aws.amazon.com/opsworks/latest/userguide/security-settingsshkey.html).
* Create the security groups required by the launch configuration. Open port to 22 (ssh) and 25565 (mc-server port).
* Gonna need an ami too.
* Need an instance profile also, this can be obtained from the IAM service. In other words create a service role of type EC2 and give access to s3.
