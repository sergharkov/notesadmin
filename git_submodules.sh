    - echo "https://$GITUSER:$GITTOCKEN@$GITREPO" > ~/.git-credentials
    - cat .gitmodules
    - git submodule init
    - git submodule update --recursive --remote
    - |
        git -C "${REPO_PATH}" config -f .gitmodules --get-regexp '^submodule\..*\.path$' |
          while read -r KEY MODULE_PATH
            do
              url_key="$(echo "${KEY}"    | sed 's/\.path$/.url/')"
              branch_key="$(echo "${KEY}" | sed 's/\.path$/.branch/')"
              tag_key="$(echo "${KEY}"    | sed 's/\.path$/.tag/')"
              NAME="$(echo "${KEY}"       | sed 's/^submodule\.\(.*\)\.path$/\1/')"
              URL="$(git config -f .gitmodules --get "${url_key}")"
              TAG="$(git config -f .gitmodules --get "${tag_key}")"
              BRANCH="$(git config -f .gitmodules --get "${branch_key}")"
              cd ${MODULE_PATH}         && 
              git branch                && 
              git checkout tags/${TAG}  && 
              git branch                && 
              ls -la                    && 
              cd ../../..
          done
