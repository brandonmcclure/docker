# myAnsible
This directory has playbooks and other files that I am using to explore using ansible pull mode

# Installling for linux
Ideally you bake the key into the os image/ie the os is imutable and password ssh auth is disabled. If not, from windows wsl:

From this dir, open `wsl`:
```
cp -r /mnt/c/Users/brandon/.ssh ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
ssh-copy-id -i ~/.ssh/id_rsa.pub brandon@host.example.com
```

confirm that you can ssh into it with the key

```
ansible -i hosts all -m ping
```
# Installing for windows
Dependencies:
`python` and `pip` (`choco install python`)

then
`pip install "pywinrm>=0.3.0"`
From admin pwsh
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))
```
```
function Create-NewLocalAdmin {
    [CmdletBinding()]
    param (
        [string] $NewLocalAdmin,
        [securestring] $Password
    )    
    begin {
    }    
    process {
        New-LocalUser "$NewLocalAdmin" -Password $Password -FullName "$NewLocalAdmin" -Description "Ansible local admin"
        Write-Verbose "$NewLocalAdmin local user crated"
        Add-LocalGroupMember -Group "Administrators" -Member "$NewLocalAdmin"
        Write-Verbose "$NewLocalAdmin added to the local administrator group"
    }    
    end {
    }
}
$Password = Read-Host -AsSecureString "Create a password for ansible user"
Create-NewLocalAdmin -NewLocalAdmin "ansible" -Password $Password -Verbose
```

# ansible-galaxy installs
This needs to be run from the "control" or "master" host. IE the computer that is going to push the ansible commands to the individual hosts.
```
ansible-galaxy install geerlingguy.ansible
ansible-galaxy install geerlingguy.pip
ansible-galaxy install andrewrothstein.powershell
ansible-galaxy collection install ansible.windows
```

# Misc links/help
https://opensource.com/article/18/7/sysadmin-tasks-ansible

Ansible with Windows - https://www.youtube.com/watch?v=FEdXUv02Dbg

## Where is a list of all the tasks I can use?
idk...

# Managing secrets/ group_var files
## In the hosts files
To use (secure) variables in the hosts files, create a `group_vars\GroupName` folder. Use the minimum needed secrets in `secret.yaml` Create as many other .yaml files with other variables. 

![picture 1](images/33d4e980b729872d364ff59797c97748d499bf5a5f8cfa06a19dd118eb9fad8a.png)  

To encrypt: 
```
ansible-vault encrypt Hosts/group_vars/windows/secret.yaml
```
and enter a password. When you run these playbooks, add the `--ask-vault-pass` option. 
ie: 
```
ansible-playbook -i Hosts/development Playbooks/choco\ _test.yaml --ask-vault-pass`
```