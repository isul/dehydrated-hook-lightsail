#!/usr/bin/env bash

#
# Dehydrated hook script that employs aws cli to enable dns-01 challenges with AWS Lightsail
#
# isul <isul@isulnara.com>
# https://github.com/isul/dehydrated-hook-lightsail
# Based on dehydrated hook.sh template
#
# Requires dehydrated (https://github.com/lukas2511/dehydrated)
# Requires aws cli
# Requires bash, jq, dig
#
# Requires AWS credentials with access to Lightsail

# ATTEMPTS - Wait $ATTEMPTS times $SLEEP seconds for propagation to succeed, then bail out.
[ -z "${ATTEMPTS}" ] && ATTEMPTS=3
 
# SLEEP - Amount of seconds to sleep before retrying propagation check.
[ -z "${SLEEP}" ] && SLEEP=20


deploy_challenge() {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    # This hook is called once for every domain that needs to be
    # validated, including any alternative names you may have listed.
    #
    # Parameters:
    # - DOMAIN
    #   The domain name (CN or subject alternative name) being
    #   validated.
    # - TOKEN_FILENAME
    #   The name of the file containing the token to be served for HTTP
    #   validation. Should be served by your web server as
    #   /.well-known/acme-challenge/${TOKEN_FILENAME}.
    # - TOKEN_VALUE
    #   The token value that needs to be served for validation. For DNS
    #   validation, this is what you want to put in the _acme-challenge
    #   TXT record. For HTTP validation it is the value that is expected
    #   be found in the $TOKEN_FILENAME file.

    # Creates TXT record is appropriate Lightsail domain, and waits for it to sync

    JSON=`aws lightsail get-domain --domain-name $DOMAIN`
    ID=0
    i=0
    while [[ $i -ge 0 ]] ; do
      TYPE=`echo $JSON | jq -r ".domain.domainEntries[$i].type"`
      if [ "$TYPE" == "TXT" ]; then
        ID=`echo $JSON | jq -r ".domain.domainEntries[$i].id"`
        i=-1
      elif [ "$TYPE" == "null" ]; then
        i=-1
      else
        (( i++ ))
      fi
    done

    ENTRY={\"type\":\"TXT\",\"isAlias\":false,\"target\":\"\\\"$TOKEN_VALUE\\\"\",\"id\":\"$ID\",\"name\":\"_acme-challenge.$DOMAIN\"}
    if [ "$ID" == "0" ]; then
      echo "Creating TXT record(_acme-challenge.$DOMAIN) for $DOMAIN..."
      aws lightsail create-domain-entry --domain-name $DOMAIN --domain-entry "$ENTRY"
    else
      echo "Updating TXT record($TOKEN_VALUE) for $DOMAIN..."
      aws lightsail update-domain-entry --domain-name $DOMAIN --domain-entry "$ENTRY"
    fi

    echo " + Settling down for ${SLEEP}s..."
    sleep $SLEEP

    i=0
    COUNT=`dig -t txt _acme-challenge.$DOMAIN +short | grep -- "$TOKEN_VALUE" | wc -l`
    while [[ $i -le $ATTEMPTS ]] ; do
      if [ "$COUNT" == "1" ]; then
        echo "Token value($TOKEN_VALUE) is valid!"
        i=100
      else
        echo " + Settling down for ${SLEEP}s..."
        sleep $SLEEP
        COUNT=`dig -t txt _acme-challenge.$DOMAIN +short | grep -- "$TOKEN_VALUE" | wc -l`
        (( i++ ))
      fi
    done
}

clean_challenge() {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    # This hook is called after attempting to validate each domain,
    # whether or not validation was successful. Here you can delete
    # files or DNS records that are no longer needed.
    #
    # The parameters are the same as for deploy_challenge.

    # Simple example: Use nsupdate with local named
    # printf 'server 127.0.0.1\nupdate delete _acme-challenge.%s TXT "%s"\nsend\n' "${DOMAIN}" "${TOKEN_VALUE}" | nsupdate -k /var/run/named/session.key
}

deploy_cert() {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"

    # This hook is called once for each certificate that has been
    # produced. Here you might, for instance, copy your new certificates
    # to service-specific locations and reload the service.
    #
    # Parameters:
    # - DOMAIN
    #   The primary domain name, i.e. the certificate common
    #   name (CN).
    # - KEYFILE
    #   The path of the file containing the private key.
    # - CERTFILE
    #   The path of the file containing the signed certificate.
    # - FULLCHAINFILE
    #   The path of the file containing the full certificate chain.
    # - CHAINFILE
    #   The path of the file containing the intermediate certificate(s).
    # - TIMESTAMP
    #   Timestamp when the specified certificate was created.

    # Simple example: Copy file to nginx config
    # cp "${KEYFILE}" "${FULLCHAINFILE}" /etc/nginx/ssl/; chown -R nginx: /etc/nginx/ssl
    # systemctl reload nginx

    #cat ${FULLCHAINFILE} ${KEYFILE} > ${FULLCHAINFILE}.${DOMAIN}
    #echo "Saved certificate to ${FULLCHAINFILE}.${DOMAIN}"

    #if [[ $DOMAIN != *"*."* ]]; then
      #echo "Restarting haproxy..."
      #killall haproxy
      #/usr/local/haproxy/sbin/haproxy -f /usr/local/haproxy/var/haproxy.cfg -p /usr/local/haproxy/var/haproxy.pid
    #fi
}

unchanged_cert() {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"

    # This hook is called once for each certificate that is still
    # valid and therefore wasn't reissued.
    #
    # Parameters:
    # - DOMAIN
    #   The primary domain name, i.e. the certificate common
    #   name (CN).
    # - KEYFILE
    #   The path of the file containing the private key.
    # - CERTFILE
    #   The path of the file containing the signed certificate.
    # - FULLCHAINFILE
    #   The path of the file containing the full certificate chain.
    # - CHAINFILE
    #   The path of the file containing the intermediate certificate(s).
}

invalid_challenge() {
    local DOMAIN="${1}" RESPONSE="${2}"

    # This hook is called if the challenge response has failed, so domain
    # owners can be aware and act accordingly.
    #
    # Parameters:
    # - DOMAIN
    #   The primary domain name, i.e. the certificate common
    #   name (CN).
    # - RESPONSE
    #   The response that the verification server returned

    # Simple example: Send mail to root
    # printf "Subject: Validation of ${DOMAIN} failed!\n\nOh noez!" | sendmail root
}

request_failure() {
    local STATUSCODE="${1}" REASON="${2}" REQTYPE="${3}" HEADERS="${4}"

    # This hook is called when an HTTP request fails (e.g., when the ACME
    # server is busy, returns an error, etc). It will be called upon any
    # response code that does not start with '2'. Useful to alert admins
    # about problems with requests.
    #
    # Parameters:
    # - STATUSCODE
    #   The HTML status code that originated the error.
    # - REASON
    #   The specified reason for the error.
    # - REQTYPE
    #   The kind of request that was made (GET, POST...)

    # Simple example: Send mail to root
    # printf "Subject: HTTP request failed failed!\n\nA http request failed with status ${STATUSCODE}!" | sendmail root
}

generate_csr() {
    local DOMAIN="${1}" CERTDIR="${2}" ALTNAMES="${3}"

    # This hook is called before any certificate signing operation takes place.
    # It can be used to generate or fetch a certificate signing request with external
    # tools.
    # The output should be just the cerificate signing request formatted as PEM.
    #
    # Parameters:
    # - DOMAIN
    #   The primary domain as specified in domains.txt. This does not need to
    #   match with the domains in the CSR, it's basically just the directory name.
    # - CERTDIR
    #   Certificate output directory for this particular certificate. Can be used
    #   for storing additional files.
    # - ALTNAMES
    #   All domain names for the current certificate as specified in domains.txt.
    #   Again, this doesn't need to match with the CSR, it's just there for convenience.

    # Simple example: Look for pre-generated CSRs
    # if [ -e "${CERTDIR}/pre-generated.csr" ]; then
    #   cat "${CERTDIR}/pre-generated.csr"
    # fi
}

startup_hook() {
  # This hook is called before the cron command to do some initial tasks
  # (e.g. starting a webserver).
  :
}

exit_hook() {
  # This hook is called at the end of the cron command and can be used to
  # do some final (cleanup or other) tasks.
  :
}

HANDLER="$1"; shift
if [[ "${HANDLER}" =~ ^(deploy_challenge|clean_challenge|deploy_cert|unchanged_cert|invalid_challenge|request_failure|generate_csr|startup_hook|exit_hook)$ ]]; then
  "$HANDLER" "$@"
fi
