#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROJECT_PATH=$SCRIPT_PATH/../../../..
SETTINGS_PATH=$PROJECT_PATH/settings.xml

for i in "$@"; do
  case $1 in
  	--repository-name=*)
      REPOSITORY_NAME="${i#*=}"
      shift
      ;;
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
if [ -z $REPOSITORY_NAME ]
then
  printf "ERROR: --repository-name argument required\n"
  INVALID_ARGUMENTS=1
fi
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

SET_REPOSITORY=false
if test -f "$SETTINGS_PATH"; then
	if grep -wq "<id>$REPOSITORY_NAME</id>" $SETTINGS_PATH; then
		printf "\nYou already have configured in $SETTINGS_PATH the repository $REPOSITORY_NAME. If you want to change the client id and secret, remove these configuration and execute the script again or change it manually\n"
	else
		printf "\nConfiguring the repository <$REPOSITORY_NAME> in $SETTINGS_PATH ...\n"
		SET_REPOSITORY=true
	fi
else
	printf "\nERROR: The file $SETTINGS_PATH doesn't exist. No server configuration added to your local maven configuration"
	exit 1
fi

if [ "$SET_REPOSITORY" = true ]; then
	CONTENT="\t\t<server>\n\t\t\t<id>$REPOSITORY_NAME</id>\n\t\t\t<username>~~~Client~~~</username>\n\t\t\t<password>$CLIENT_ID\~?~$CLIENT_SECRET</password>\n\t\t</server>"
	C=$(echo $CONTENT | sed 's/\//\\\//g')
	if sed -i "/<\/servers>/ s/.*/${C}\n&/gi" $SETTINGS_PATH; then
		printf "\nSUCCESS: $REPOSITORY_NAME configuration added to $SETTINGS_PATH\n"
	else
		printf "\nERROR: Cannot add <$REPOSITORY_NAME> configuration in $SETTINGS_PATH\n"
	fi
fi

MAVEN_REPOSITORY_PATH=$HOME/.m2
if [ ! -d $MAVEN_REPOSITORY_PATH ]; then mkdir $MAVEN_REPOSITORY_PATH; fi
cp -f settings.xml $MAVEN_REPOSITORY_PATH/settings.xml
