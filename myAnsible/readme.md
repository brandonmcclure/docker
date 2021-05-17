# myAnsible
This directory has playbooks and other files that I am using to explore using ansible pull mode

# Install SSH key 
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

# ansible-galaxy installs
```
ansible-galaxy install geerlingguy.ansible
ansible-galaxy install geerlingguy.pip
ansible-galaxy install andrewrothstein.powershell
```

# Misc links/help
https://opensource.com/article/18/7/sysadmin-tasks-ansible

## Where is a list of all the tasks I can use?