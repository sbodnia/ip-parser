#!/bin/bash

# PREDEFINED VARIABLES
######################
# Note: You can change path to file with IPs in variable $file 

file="Example/nginx.access.log"
token="f54d64937f4637"

g=FALSE
o=FALSE
s=FALSE

# FUNCTIONS
###########

help () {
    echo "Script use

script.sh [options]

options:
-h        show brief help
-c        specify a case to use [1|2]
-g        use flag [-g] to output country code
-o        use flag [-o] to output in report.log
-t        use flag [-t] to use token ipinfo.io
-f        use flag [-f] to specify path to file

Example of case #1 with geo:
script.sh -c 1 -g
Output:
1.1.1.1 12 UA

Note:
Using of flag [-g] takes some time to return all country codes. Please, try to wait"
    exit 0
}

grep_filter () {
    grep -oh -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ' "$file"                       \
    | grep -vE '(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|10\.0\.|127\.0\.0\.1)' \
    | sort                                                                                      \
    | uniq -c                                                                                   
                                                                   
}

awk_filter () {
    awk 'match($0, /(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/) \
    {print substr($0, RSTART, RLENGTH)}' "$file"                                                                    \
    | grep -vE '(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|10\.0\.|127\.0\.0\.1)'                     \
    | sort                                                                                                          \
    | uniq -c                                                                                                       
        
}

extended_output () {
    for i in "${!ip_array[@]}"; do
        country_code=$(curl -s "https://ipinfo.io/${ip_array[$i]}/country?token=$token")
        printf "%s\t\t%s\t\t%s\n" "${ip_array[$i]}" "${count_array[$i]}" "$country_code" 
    done
}

top () {
    sort k2 -nr | head -n "$sort"
}

# ARGUMENTS
###########

if [[ $# -eq 0 ]] ; then
    echo 'You must to provide flags. Try to execute script -h first'
    help
fi

while getopts 'hc:s:got:f:' OPTION; do
  case "$OPTION" in
    h)
        help
    ;;
    c)
        number=${OPTARG}
        if [ "$number" -gt "2" ]
        then
        echo "Script has only 2 cases"
        echo
        help
        fi
    ;;
    g)
        g=TRUE
    ;;
    o)
        o=TRUE 
    ;;
    s)
        s=TRUE
        count=$OPTARG
        re='^[0-9]+$'
        if [[ $count =~ $re ]] ; then
            if [[ "$count" -gt 0 ]]
                then
                sorting () {
                    sort -k2 -nr | head -n "$count"
                }
            fi
        else
            sorting () {
                sort -k2 -nr
            }
        fi
    ;;
    t)
        token=${OPTARG}
    ;;
    f)
        file=${OPTARG}
    ;;
    \?)
        echo "Invalid option: -$OPTARG"
        echo "Script hasn't provide this flag"
        help
    ;;     
  esac
done

# OUTPUT OPERATOR
#################
#
# GREP case (#1)
if [ "$number" = "1" ]
    then
    echo "Start Case #1"
    if [ "$o" = FALSE ]
        then
        if [ "$g" = FALSE ] && [ "$s" = FALSE ]
            then
            grep_filter | awk '{print $2"\t"$1}'
        elif [ "$g" = FALSE ] && [ "$s" = TRUE ]
            then
            grep_filter | awk '{print $2"\t"$1}' | sorting
            echo "Sorted by IPs counts"
        elif [ "$g" = TRUE ] && [ "$s" = FALSE ]
            then
            echo "Extended version"
            echo "It takes some time. Please, wait"
            ip_array=($(grep_filter | awk '{print $2}'))
            count_array=($(grep_filter | awk '{print $1}'))
            extended_output
        elif [ "$g" = TRUE ] && [ "$s" = TRUE ]
            then
            echo "Extended version"
            echo "It takes some time. Please, wait"
            ip_array=($(grep_filter | awk '{print $2}'))
            count_array=($(grep_filter | awk '{print $1}'))
            extended_output | sorting
            echo "Sorted by IPs counts"
        fi
    elif [ "$o" = TRUE ]
        then
        if [ "$g" = FALSE ] && [ "$s" = FALSE ]
            then
            grep_filter | awk '{print $2"\t"$1}' >> report.log
            echo "You can check IPs in report.log"
        elif [ "$g" = FALSE ] && [ "$s" = TRUE ]
            then
            grep_filter | awk '{print $2"\t"$1}' | sorting >> report.log
            echo "Sorted by IPs counts"
            echo "You can check IPs in report.log"
        elif [ "$g" = TRUE ] && [ "$s" = FALSE ]
            then
            echo "Extended version"
            echo "It takes some time. Please, wait"
            ip_array=($(grep_filter | awk '{print $2}'))
            count_array=($(grep_filter | awk '{print $1}'))
            extended_output >> report.log
            echo "You can check IPs in report.log"
        elif [ "$g" = TRUE ] && [ "$s" = TRUE ]
            then
            echo "Extended version"
            echo "Outputing to report.log"
            echo "It takes some time. Please, wait"
            ip_array=($(grep_filter | awk '{print $2}'))
            count_array=($(grep_filter | awk '{print $1}'))
            extended_output | sorting >> report.log
            echo "Sorted by IPs counts"
            echo "You can check IPs in report.log"
        fi
    fi
    echo "End Case #1"
fi
# AWK case (#2)
if [ "$number" = "2" ]
    then 
    echo "Start Case #2"
    if [ "$o" = FALSE ]
        then
        if [ "$g" = FALSE ] && [ "$s" = FALSE ]
            then
            awk_filter | awk '{print $2"\t"$1}'
        elif [ "$g" = FALSE ] && [ "$s" = TRUE ]
            then
            awk_filter | awk '{print $2"\t"$1}' | sorting
            echo "Sorted by IPs counts"
        elif [ "$g" = TRUE ] && [ "$s" = FALSE ]
            then
            echo "Extended version"
            echo "It takes some time. Please, wait"
            ip_array=($(awk_filter | awk '{print $2}'))
            count_array=($(awk_filter | awk '{print $1}'))
            extended_output
        elif [ "$g" = TRUE ] && [ "$s" = TRUE ]
            then
            echo "Extended version"
            echo "It takes some time. Please, wait"
            ip_array=($(awk_filter | awk '{print $2}'))
            count_array=($(awk_filter | awk '{print $1}'))
            extended_output | sorting
            echo "Sorted by IPs counts"
        fi
    elif [ "$o" = TRUE ]
        then
        if [ "$g" = FALSE ] && [ "$s" = FALSE ]
            then
            awk_filter | awk '{print $2"\t"$1}' >> report.log
            echo "You can check IPs in report.log"
        elif [ "$g" = FALSE ] && [ "$s" = TRUE ]
            then
            awk_filter | awk '{print $2"\t"$1}' | sorting >> report.log
            echo "Sorted by IPs counts"
            echo "You can check IPs in report.log"
        elif [ "$g" = TRUE ] && [ "$s" = FALSE ]
            then
            echo "Extended version"
            echo "It takes some time. Please, wait"
            ip_array=($(awk_filter | awk '{print $2}'))
            count_array=($(awk_filter | awk '{print $1}'))
            extended_output >> report.log
            echo "You can check IPs in report.log"
        elif [ "$g" = TRUE ] && [ "$s" = TRUE ]
            then
            echo "Extended version"
            echo "Outputing to report.log"
            echo "It takes some time. Please, wait"
            ip_array=($(awk_filter | awk '{print $2}'))
            count_array=($(awk_filter | awk '{print $1}'))
            extended_output | sorting >> report.log
            echo "Sorted by IPs counts"
            echo "You can check IPs in report.log"
        fi
    fi
    echo "End Case #2"
fi
