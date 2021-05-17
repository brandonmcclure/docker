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