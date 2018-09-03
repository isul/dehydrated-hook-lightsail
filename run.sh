#!/usr/bin/env bash

# Path to a directory containing dehydrated
DEHYDRATED_DIR=/volume1/system/usr/local/dehydrated

# your domain
DOMAIN=example.com

if [ -d "$DEHYDRATED_DIR/certs/$DOMAIN.backup" ]; then
  rm -rf $DEHYDRATED_DIR/certs/$DOMAIN.backup
fi
mv $DEHYDRATED_DIR/certs/$DOMAIN $DEHYDRATED_DIR/certs/$DOMAIN.backup

$DEHYDRATED_DIR/dehydrated -c -d *.$DOMAIN --alias $DOMAIN
$DEHYDRATED_DIR/dehydrated -c

JSON=`aws lightsail get-domain --domain-name $DOMAIN`
ID=0
i=0
while [[ $i -ge 0 ]] ; do
  TYPE=`echo $JSON | jq -r ".domain.domainEntries[$i].type"`
  if [ "$TYPE" == "TXT" ]; then
    ID=`echo $JSON | jq -r ".domain.domainEntries[$i].id"`
    TOKEN_VALUE=`echo $JSON | jq -r ".domain.domainEntries[$i].target"`
    TOKEN_VALUE=`echo $TOKEN_VALUE | sed -e "s/\"//g"`
    i=-1
  elif [ "$TYPE" == "null" ]; then
    i=-1
  else
    (( i++ ))
  fi
done
ENTRY={\"type\":\"TXT\",\"isAlias\":false,\"target\":\"\\\"$TOKEN_VALUE\\\"\",\"id\":\"$ID\",\"name\":\"_acme-challenge.$DOMAIN\"}
if [ "$ID" != "0" ]; then
  echo "Deleting TXT record(_acme-challenge.$DOMAIN) for $DOMAIN..."
  aws lightsail delete-domain-entry --domain-name $DOMAIN --domain-entry "$ENTRY"
fi