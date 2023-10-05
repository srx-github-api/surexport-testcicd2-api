#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
ENCRYPT_KEY_PATH=$SCRIPT_PATH/encryptKey.txt
DEV_CONFIG_PATH=$SCRIPT_PATH/../properties/dev-config.properties
DEV_SECURE_CONFIG_PATH=$SCRIPT_PATH/../properties/secure-dev-config.properties
QA_CONFIG_PATH=$SCRIPT_PATH/../properties/qa-config.properties
QA_SECURE_CONFIG_PATH=$SCRIPT_PATH/../properties/secure-qa-config.properties
PROD_CONFIG_PATH=$SCRIPT_PATH/../properties/prod-config.properties
PROD_SECURE_CONFIG_PATH=$SCRIPT_PATH/../properties/secure-prod-config.properties
JAR_PATH=$SCRIPT_PATH/../tools/secure-properties-tool.jar
ENCRYPT_KEY=NULL
DELETE_FILES=0

for i in "$@"; do
  case $1 in
    --encrypt-key=*)
      ENCRYPT_KEY="${i#*=}"
      shift
      ;;
	-r|-R|--r|--R)
      DELETE_FILES=1
      shift
      ;;
    -*|--*|*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

if test -f "$ENCRYPT_KEY_PATH"; 
then
	printf "Getting local encryption key...\n"
    ENCRYPT_KEY=`cat $ENCRYPT_KEY_PATH`
elif [ "$ENCRYPT_KEY" != "NULL" ]
then
	printf "Using encryption key specified as argument...\n"
	if test -f "$DEV_CONFIG_PATH" && `java -cp $JAR_PATH com.mulesoft.tools.SecurePropertiesTool file encrypt AES CBC $ENCRYPT_KEY $DEV_CONFIG_PATH $DEV_SECURE_CONFIG_PATH`
	then 
		printf "\nSUCCESS: $DEV_CONFIG_PATH successfully encrypted"
		if [ $DELETE_FILES -eq 1 ]
		then
			rm $DEV_CONFIG_PATH
		fi
	fi
	if test -f "$QA_CONFIG_PATH" && `java -cp $JAR_PATH com.mulesoft.tools.SecurePropertiesTool file encrypt AES CBC $ENCRYPT_KEY $QA_CONFIG_PATH $QA_SECURE_CONFIG_PATH`
	then 
		printf "\nSUCCESS: $QA_CONFIG_PATH successfully encrypted"
		if [ $DELETE_FILES -eq 1 ]
		then
			rm $QA_CONFIG_PATH
		fi
	fi
	if test -f "$PROD_CONFIG_PATH" && `java -cp $JAR_PATH com.mulesoft.tools.SecurePropertiesTool file encrypt AES CBC $ENCRYPT_KEY $PROD_CONFIG_PATH $PROD_SECURE_CONFIG_PATH`
	then 
		printf "\nSUCCESS: $PROD_CONFIG_PATH successfully encrypted"
		if [ $DELETE_FILES -eq 1 ]
		then
			rm $PROD_CONFIG_PATH
		fi
	fi
	if test -f "$ENCRYPT_KEY_PATH" && [ $DELETE_FILES == 1 ]
	then
		rm $ENCRYPT_KEY_PATH
	fi
else
	printf "ERROR: No encryption key found. You must specify it as the first argument\n"
	exit 1
fi




