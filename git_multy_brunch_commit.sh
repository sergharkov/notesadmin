#!/bin/bash
declare -a arr_branches=(\
"node_b4" \
"node_b3" \
"node_b1" \
"node_b2" \
)

envfiles="node_5.env \
         node_1.env \
         node_2.env \
         node_3.env \
         node_4.env"
echo $envfiles
concatenation (){
rm all.env -f
awk '{if(!seen[$0]++)print $0}' \
         $envfiles |\
         sed "s/PORT=3040//g" | \
         perl -pe 's/(#)/\n$1/' >\
         all.env
}

mvoldenv (){
        mkdir -p ./old/
        mv -f $envfiles ./old/ 2>/dev/null; true
}

for branche in "${arr_branches[@]}"
do
echo -e "###################"$branche"###################\n"
git clone -b $branche ssh://git@xxxxxxxxxxxxxxxx.git 

#cd ./stage_variables
cd ./prod_variables
mvoldenv
#concatenation 
cat ./all.env
ls -l 
cd ..
git add .
git commit -m "concatenate variables app for branch $branche"
git push origin $branche
cd ..
sleep 30
rm -r ./swarm_credentials -f
done
