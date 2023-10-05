#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROJECT_PATH=$SCRIPT_PATH/../../../..
POM_PATH=$PROJECT_PATH/pom.xml
SETTINGS_PATH=$PROJECT_PATH/settings.xml
GITLAB_CI_PATH=$SCRIPT_PATH/../git/.gitlab-ci.yml
GITLAB_CI_FINAL_PATH=$PROJECT_PATH/.gitlab-ci.yml
GITIGNORE_PATH=$SCRIPT_PATH/../git/.gitignore
GITIGNORE_FINAL_PATH=$PROJECT_PATH/.gitignore
LOCAL_SETTINGS_PATH=$HOME/.m2/settings.xml
ANYPOINT_CLIENT_ID=**************
REPOSITORY_NAME=mulesoft-surexport-repository
SET_REPOSITORY=false

for i in "$@"; do
  case $1 in
    --gitlab-token=*)
      GITLAB_TOKEN="${i#*=}"
      shift
      ;;
    -*|--*|*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

read -p "Enter the AnypointStudio project name: " PROJECT_NAME

if test -f "$LOCAL_SETTINGS_PATH"; then
	if grep -wq "<id>$REPOSITORY_NAME</id>" $LOCAL_SETTINGS_PATH; then
		printf "\nYou already have configured in $LOCAL_SETTINGS_PATH the repository $REPOSITORY_NAME. If you want to change the client id and secret, remove these configuration and execute the script again or change it manually\n"
	else
		printf "\nYou haven't configured in $LOCAL_SETTINGS_PATH the repository <$REPOSITORY_NAME>. Please, provide the following information:\n"
		read -p "Enter your ConnectedApp client id: " ANYPOINT_CLIENT_ID
		read -s -p "Enter your ConnectedApp client secret: " ANYPOINT_CLIENT_SECRET
		SET_REPOSITORY=true
	fi
else
	printf "\nWARNING: The file $LOCAL_SETTINGS_PATH doesn't exist. No server configuration added to your local maven configuration"
fi

printf "\n*************************************************************************************\n"
printf "  The next information will be modified: \n"
printf "    project_type:        mule-application\n"
printf "    artifact_id:         $PROJECT_NAME\n"
printf "    project_name:        $PROJECT_NAME\n"
printf "    repository_name:     $REPOSITORY_NAME\n"
printf "    client_id:           $ANYPOINT_CLIENT_ID\n"
printf "    client_secret:       **************\n"
printf "*************************************************************************************\n"
read -p "Do you want to apply these changes? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

if [ ! -z $GITLAB_TOKEN ]
then
	printf "GitLab access token provided. Retrieving maven configuration files from repository...\n"
	curl -s --header "Private-token: $GITLAB_TOKEN" https://gitlab.com/api/v4/projects/34338310/repository/files/pom.xml\?ref\=main | grep -oP '(?<="content":")[^"]*' | base64 --decode > $POM_PATH
	curl -s --header "Private-token: $GITLAB_TOKEN" https://gitlab.com/api/v4/projects/34338310/repository/files/settings.xml\?ref\=main | grep -oP '(?<="content":")[^"]*' | base64 --decode > $SETTINGS_PATH
fi

if sed -i "s/<classifier>mule-application-template<\/classifier>/<classifier>mule-application<\/classifier>/gi" $POM_PATH; then
	printf "\nSUCCESS: <classifier> value changed to mule-application <$POM_PATH>"
else
	printf "\nERROR: <classifier> value didnt change <$POM_PATH>"
fi
if sed -i "s/<artifactId>surexport-project-template<\/artifactId>/<artifactId>$PROJECT_NAME<\/artifactId>/gi" $POM_PATH; then
	printf "\nSUCCESS: <artifactId> value changed to $PROJECT_NAME <$POM_PATH>"
else
	printf "\nERROR: <artifactId> didnt change <$POM_PATH>"
fi
if sed -i "s/<name>surexport-project-template.*<\/name>/<name>$PROJECT_NAME<\/name>/gi" $POM_PATH; then
	printf "\nSUCCESS: <name> value changed to $PROJECT_NAME <$POM_PATH>"
else
	printf "\nERROR: <name> didnt change <$POM_PATH>"
fi

if [ "$SET_REPOSITORY" = true ]; then
	CONTENT="\t\t<server>\n\t\t\t<id>$REPOSITORY_NAME</id>\n\t\t\t<username>~~~Client~~~</username>\n\t\t\t<password>$ANYPOINT_CLIENT_ID\~?~$ANYPOINT_CLIENT_SECRET</password>\n\t\t</server>"
	C=$(echo $CONTENT | sed 's/\//\\\//g')
	if sed -i "/<\/servers>/ s/.*/${C}\n&/gi" $LOCAL_SETTINGS_PATH; then
		printf "\nSUCCESS: $REPOSITORY_NAME configuration added to $LOCAL_SETTINGS_PATH\n"
	else
		printf "\nERROR: Cannot add $REPOSITORY_NAME configuration in <$LOCAL_SETTINGS_PATH>\n"
	fi
fi

printf "\n\n"
read -p "Do you want to setup default CD/CI config files? (Y/N): " GIT_CONFIG_CONFIRM
if [[ $GIT_CONFIG_CONFIRM == [yY] || $GIT_CONFIG_CONFIRM == [yY][eE][sS] ]] 
then
	cat $GITLAB_CI_PATH > $GITLAB_CI_FINAL_PATH
	printf "\nSUCCESS: $GITLAB_CI_PATH copied to .gitlab-ci.yml"
	cat $GITIGNORE_PATH > $GITIGNORE_FINAL_PATH
	printf "\nSUCCESS: $GITIGNORE_PATH copied to .gitignore"
	rm -rf $SCRIPT_PATH/../git
else
	printf "\nWARNING: The file $GITLAB_CI_APP_PATH doesn't exist. CD/CI pipelines will use the original template gitlab pipeline configuration"
fi

printf "\n\n"
read -p "Do you want to reload maven dependencies? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
cd $PROJECT_PATH
mvn clean package
mvn clean install -U