
mkdir azagent;
cd azagent;curl -fkSL -o vstsagent.tar.gz https://vstsagentpackage.azureedge.net/agent/3.225.0/vsts-agent-linux-x64-3.225.0.tar.gz;
tar -zxvf vstsagent.tar.gz; 
if [ -x "$(command -v systemctl)" ]; 
then ./config.sh 
		--environment 
		--environmentname "test-env" 
		--acceptteeeula 
		--agent $HOSTNAME 
		--url https://dev.azure.com/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx/ 
		--work _work 
		--projectname 'testcow' 
		--auth PAT 
		--token XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx 
		--runasservice; 
	sudo ./svc.sh install; 
	sudo ./svc.sh start; 
else ./config.sh --environment 
		--environmentname "test-env" 
		--acceptteeeula 
		--agent $HOSTNAME 
		--url https://dev.azure.com/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx/ 
		--work _work 
		--projectname 'testcow' 
		--auth PAT 
		--token XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx; 
	./run.sh; 
fi
