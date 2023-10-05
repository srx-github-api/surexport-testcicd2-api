#!/bin/bash
for i in "$@"; do
  case $1 in
    --client-id=*)
      CLIENT_ID="${i#*=}"
      shift
      ;;
 	--client-secret=*)
      CLIENT_SECRET="${i#*=}"
      shift
      ;;
    -*|--*|*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

INVALID_ARGUMENTS=0
if [ -z $CLIENT_ID ]
then
	printf "ERROR: --client-id argument required\n"
	INVALID_ARGUMENTS=1
fi
if [ -z $CLIENT_SECRET ]
then
	printf "ERROR: --client-secret argument required\n"
	INVALID_ARGUMENTS=1
fi
if [ $INVALID_ARGUMENTS -eq 1 ]
then
	exit 1
fi

OAUTH_TOKEN="$(curl -s --location --request POST https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=$CLIENT_ID" --data-urlencode "client_secret=$CLIENT_SECRET" --data-urlencode "grant_type=client_credentials" | grep -oP '(?<="access_token":")[^"]*')"
mvn -DauthToken=$OAUTH_TOKEN deploy

