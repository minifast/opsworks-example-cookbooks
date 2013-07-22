AWS OpsWorks Example Cookbooks
==============================

graphite: Installs the graphite recipe.
python: Installs the python community cookbook, forked and ready to rock.
logrotate/apache2/yum/build-essential: Needed by graphite or python.

## Propagating Changes

(Inspired by @ohrite's travels with @mkocher)

### Local Side

This assumes that you have a shell open to this directory.

```bash
watch -n 0.1 rsync --exclude .git -avh . ec2-user@<ip>:~ec2-user/site-cookbooks
```

### Remote side

Before this, do: `ssh -i <pem> ec2-user@<ip>`

```bash
ssh ec2-user@<ip> 'env TERM=xterm sudo su - -c "watch -n 0.1 rsync -avh ~ec2-user/site-cookbooks/ /opt/aws/opsworks/current/site-cookbooks"'
```

### Running the opsware stage

Before this, do: `ssh -i <pem> ec2-user@<ip>`

```bash
sudo su -
cd /opt/aws/opsworks/current
bin/opsworks-agent-cli run_command setup
```

This runs the setup stage, for example.

## Configuring Opsworks

If you're using the free tier t1.micro, you'll likely need to tune Apache way down:

```json
{
  "apache": {
    "prefork": {
      "startservers": 5,
      "minspareservers": 5,
      "maxspareservers": 10,
      "serverlimit": 20,
      "maxclients": 20,
      "maxrequestsperchild": 5000
    }
  }
}
```
