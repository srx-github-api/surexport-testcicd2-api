#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
DEV_CONFIG_PATH=$SCRIPT_PATH/../properties/dev-config.properties
DEV_SECURE_CONFIG_PATH=$SCRIPT_PATH/../properties/secure-dev-config.properties
QA_CONFIG_PATH=$SCRIPT_PATH/../properties/qa-config.properties
QA_SECURE_CONFIG_PATH=$SCRIPT_PATH/../properties/secure-qa-config.properties
PROD_CONFIG_PATH=$SCRIPT_PATH/../properties/prod-config.properties
PROD_SECURE_CONFIG_PATH=$SCRIPT_PATH/../properties/secure-prod-config.properties
JAR_PATH=$SCRIPT_PATH/../tools/secure-properties-tool.jar
DECRYPT_KEY=NULL

for i in "$@"; do
  case $1 in
    --decrypt-key=*)
      DECRYPT_KEY="${i#*=}"
      shift
      ;;
    -*|--*|*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

if [ "$DECRYPT_KEY" == "NULL" ]
then
	printf "ERROR: You must specify the encryption key as first argument\n"
	exit 1
else
	if test -f "$DEV_SECURE_CONFIG_PATH" && `java -cp $JAR_PATH com.mulesoft.tools.SecurePropertiesTool file decrypt AES CBC $DECRYPT_KEY $DEV_SECURE_CONFIG_PATH $DEV_CONFIG_PATH`
	then 
		printf "\nSUCCESS: $DEV_SECURE_CONFIG_PATH successfully decrypted"
	fi
	if test -f "$QA_SECURE_CONFIG_PATH" && `java -cp $JAR_PATH com.mulesoft.tools.SecurePropertiesTool file decrypt AES CBC $DECRYPT_KEY $QA_SECURE_CONFIG_PATH $QA_CONFIG_PATH`
	then 
		printf "\nSUCCESS: $QA_SECURE_CONFIG_PATH successfully decrypted"
	fi
	if test -f "$PROD_SECURE_CONFIG_PATH" && `java -cp $JAR_PATH com.mulesoft.tools.SecurePropertiesTool file decrypt AES CBC $DECRYPT_KEY $PROD_SECURE_CONFIG_PATH $PROD_CONFIG_PATH`
	then 
		printf "\nSUCCESS: $PROD_SECURE_CONFIG_PATH successfully decrypted"
	fi
fi