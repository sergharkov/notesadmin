#!/bin/bash
declare -a arr_stages=(\
"prod" \
"stage" \
"develop" \
)

declare -a arr_domains=(\
"domain1" \
"domain1" \
"domain1" \
"domain1" \
"domain1" \
)

declare -a arr_apps=(\
"app1" \
"app1" \
"app1" \
"app1" \
"app1" \
"app1" \
)

buildnumber=30
for domain in "${arr_domains[@]}"
do
echo -e "###################"$domain"###################\n"
buildnumber=$(($buildnumber + 10))
                for stage in "${arr_stages[@]}"
                do
#               echo $domain
                                        for app in "${arr_apps[@]}"
                                        do
#                                       echo $app
                                        echo $stage"_"$domain"_"$app" "$buildnumber

#                                       echo "1111111111"
                                        done
                done
done
