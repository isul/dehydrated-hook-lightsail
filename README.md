# dehydrated-hook-lightsail
DNS 01 hook for Amazon Lightsail
This is a Dehydrated hook script that employs awscli to enable dns-01 challenges with Amazon Lightsail.

## Installation

```
$ cd ~
$ git clone https://github.com/lukas2511/dehydrated
$ cd dehydrated
$ mkdir hooks
$ git clone https://github.com/isul/dehydrated-hook-lightsail hooks/lightsail
```

## Configuration

You need to change the following settings in your dehydrated config (original value commented out):
```
CHALLENGETYPE="dns-01"
HOOK=${BASEDIR}/hooks/lightsail/hook-lightsail.sh
HOOK_CHAIN="no"
```

**Please note that you should use the staging URL when experimenting with this script to not hit Let's Encrypt's rate limits.** See [https://github.com/lukas2511/dehydrated/blob/master/docs/staging.md](https://github.com/lukas2511/dehydrated/blob/master/docs/staging.md).

`awscli` requires an AWS user access key.

$ aws configure
AWS Access Key ID [None]: AQIXXXXXXXXXXBQ
AWS Secret Access Key [None]: Va5XXXXXXXXXXCt
Default region name [None]: us-east-1
Default output format [None]: json


## Dependencies

The script requires the following tools.
- awscli (https://aws.amazon.com/cli/, pip install awscli)
- bash
- [jq](https://stedolan.github.io/jq/)
- dig
