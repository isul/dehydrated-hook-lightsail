# Amazon Lightsail hook for dehydrated
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

`awscli` requires an AWS user access key.

```
$ aws configure
AWS Access Key ID [None]: AQIXXXXXXXXXXBQ
AWS Secret Access Key [None]: Va5XXXXXXXXXXCt
Default region name [None]: us-east-1
Default output format [None]: json
```

## Dependencies

The script requires the following tools.
- awscli (https://aws.amazon.com/cli/, pip install awscli)
- bash
- [jq](https://stedolan.github.io/jq/)
- dig


## Usage

```
$ ./dehydrated -c -d example.com -t dns-01 -k 'hooks/lightsail/hook-lightsail.sh'
```
The -t dns-01 part can be skipped, if you have set this challenge type in your config already. Same goes for the -k 'hooks/lightsail/hook-lightsail.sh' part, when set in the config as well.

If you would like to sign wildcard certificates use run.sh

You need to change the following settings in your dehydrated domains.txt:
```
example.com *.example.com > example.com
```
Also you need to change the following settings in run.sh:
```
DEHYDRATED_DIR=/volume1/system/usr/local/dehydrated
DOMAIN=example.com
```

And then run the following script.
```
$ ./hooks/lightsail/run.sh
```

**Please note that you should use the staging URL when experimenting with this script to not hit Let's Encrypt's rate limits.** See [https://github.com/lukas2511/dehydrated/blob/master/docs/staging.md](https://github.com/lukas2511/dehydrated/blob/master/docs/staging.md).