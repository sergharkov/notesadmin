#Migrate from TFS server $URL_TFSserver 
#https://docs.microsoft.com/en-us/azure/devops/repos/git/import-from-tfvc?view=azure-devops
#
#Mgrate only one branche with all commites 
#Before running script you have to create new repo type GIT $Git_Repo
#
#


cd  e:\tfs-git
dir

git config --global git-tf.tfs3-vm.username "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
git config --global git-tf.tfs3-vm.password "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
git config --global git-tf.tfs3-vm.email "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
Write-Host $FTS_Username 
$URL_TFSserver="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$TFS_path="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$Git_Repo="xxxxxxxx"
$ENVs = @("xxxxxxxx","xxxxxxxx","xxxxxxxx","xxxxxxxx","xxxxxxxx","xxxxxxxx")

Get-ChildItem -Path e:\tfs-git -Directory -Recurse

#################################################
Function migrate($ENV, $Git_Repo, $URL_TFSserver, $TFS_path)
{
Write-Host "#########################################"
Write-Host  $ENV 
Write-Host  $Repo
Write-Host "#########################################"

git tfs clone $URL_TFSserver $TFS_path/$ENV --export --branches=none

cd $ENV
new-item .gitignore

git tfs verify

git remote add origin $Git_Repo
#git remote set-url origin $Repo
git status
git remote -v
git add --all
git commit -a -m "init commit after migration $ENV"
git branch
git pull origin master --allow-unrelated-histories
git push origin master

New-Item -Path "./src" -Name $ENV -ItemType Directory  -Force

Move-Item "*"  -Destination "./src/$ENV" -Exclude  .git, .gitignore, src
git add --all

git commit -a -m "move $ENV to src"
git branch
git push origin master

cd ..
dir

echo "ok";
}
#################################################

For ($i=0; $i -lt $ENVs.Length; $i++) {
    $ENV=$ENVs[$i]
    Write-Host  $ENV
    Write-Host  $Git_Repo
    migrate  $ENV $Git_Repo $URL_TFSserver $TFS_path
    }
