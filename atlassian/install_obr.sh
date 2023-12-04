#!/bin/bash
#
#	***** REST API Cheat sheet ****
# Get upm-token
# curl -sI -H "Accept: application/vnd.atl.plugins.installed+json" "http://10.10.12.31:8090/rest/plugins/1.0/"
#
# Is it installed requires basic auth
# curl -sq http://10.10.12.31:8090/rest/plugins/1.0/installed-marketplace?updates=false | jq .plugins[].links.alternate -r | grep domain
#
# Once installation is in progress
# is_it_installed=$(curl -sq http://10.10.12.31:8090"$task_id_url" | jq .done -r)
#
# DELETE PLUGIN - requires basicauth
# curl -s -XDELETE http://10.10.12.31:8090/rest/plugins/1.0/com.domain.integration.confluence-key
#############
#
# Requirements:
#  This script requires "jq" (Command-line JSON processor) to be present on the system
# e.g.: Install "jq" on OSX
#    > brew install jq
#
# Example:
#	./install_obr.sh -s "10.10.12.31:8090,10.10.12.35:8090" -a "<user>:<pass>" -p domain-confluence-plugin-0.0.1.obr
#
#############

usage() {
	echo "Usage: $0 [-p domain-confluence-plugin-0.0.1.obr] [-a <user>:<password>]" 1>&2; exit 1;
}

[ $# -eq 0 ] && usage

while getopts ":a:p:s:h:" option
do
	case "${option}" in
		a) # User name and password user:pass
			BASIC_AUTH=${OPTARG}
			;;
		p) # A Atlassian Plugin file domain-confluence-plugin-0.0.1.obr
			PLUGIN_FILE=${OPTARG}
			;;
		s) # Single value or a comma separated value
			SERVERS=${OPTARG}
			SERVER_ARRAY=(${SERVERS//,/ })
			;;
		h)
			usage
			;;
		:) 
			echo "Error: -${OPTARG} requires an argument." 
			usage
			;;
		*) 
			echo "Invalid argument"
			usage
			;;
	esac
done

if [[ ! $BASIC_AUTH ]] || [[ ! $PLUGIN_FILE ]] || [[ ! $SERVERS ]] || [[ ! $SERVER_ARRAY ]]
then
	usage
fi

if [[ ! $BASIC_AUTH =~ ":" ]]
then
	echo "Error: -a must be of following format  user:pass"
	exit 1
fi

shift $((OPTIND-1))

obr_file="$PLUGIN_FILE"

if [[ $obr_file == *.obr ]] && [[ -s $obr_file ]]
then
	# This variable is used for echo messages
	obr=${obr_file/.obr/}
else
	echo "$obr_file is not a plug-in file"
	exit 1
fi

# BasicAuth
user_pass="$BASIC_AUTH"

# This a requirement for when getting a upm-token
my_header="Accept: application/vnd.atl.plugins.installed+json"

for a_server in "${SERVER_ARRAY[@]}"
do
	echo "**** Server: $a_server"

	url="http://"$user_pass"@"$a_server"/rest/plugins/1.0/"

	# See whether or not Atlassian plug-in is installed
	is_it_installed=$(curl -sq http://"$user_pass"@"$a_server"/rest/plugins/1.0/installed-marketplace?updates=false | jq .plugins[].links.alternate -r | grep domain)

	if [[ "$is_it_installed" ]]
	then
		# Get Atlassian plug-in version if installed
		plugin_ver=$(curl -sq http://"$user_pass"@"$a_server"/rest/plugins/1.0/com.domain.integration.confluence-key/summary | jq .version -r)
		echo "**** Atlassian Plug-in version $plugin_ver is installed"
	else
		echo "**** Atlassian Plug-in is not installed"
	fi

	if [[ "$is_it_installed" ]]
	then
		echo "**** Deleting Atlassian Plug-in version $plugin_ver"

		# Delete Atlassian plug-in
		curl -s -XDELETE http://"$user_pass"@"$a_server"/rest/plugins/1.0/com.domain.integration.confluence-key
	fi

	# Get upm-token
	token=$(curl -sqI -H "$my_header" "$url?os_authType=basic" | grep upm-token | cut -d: -f2- | tr -d '[[:space:]]')

	echo "**** Installing Atlassian Plug-in $obr"

	# Actually install the OBR file - returns JSON with taskID
	task_id_url=$(curl -sq -XPOST "$url?token=$token" -F plugin=@"$obr_file" | sed -e 's/<textarea>//' | sed -e 's/<\/textarea>//'| jq .links.alternate -r)

	# Check status of installation task that was just triggered
	is_it_installed=$(curl -sq http://"$a_server""$task_id_url" | jq .done -r)

	if [[ "$is_it_installed" == "false" ]]
	then
		echo "**** Installation of Atlassian Plug-in is in progress"

		# Check status of installation task that was just triggered
		is_it_installed=$(curl -sq http://"$a_server""$task_id_url" | jq .done -r)

		while [ "$is_it_installed" == "false" ]
		do
			sleep 2

			# Check status of installation task that was just triggered
			is_it_installed=$(curl -sq http://"$a_server""$task_id_url" | jq .done -r)
		done
		echo "**** Installation of Atlassian Plug-in $obr is complete"
	fi
done
