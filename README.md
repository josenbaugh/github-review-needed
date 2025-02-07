# PR Review Notifier
This script will check for PRs needing a review from you and give a notification when there are any.
There's a file `~/.pr-reviews` that stores a urls to the PRs needing a review from you.

As long as Actions are enabled in dunst, you can middle click on the notification to open a dmenu with all the PRs needing review that'll open the picked PR in your browser.

# Requirements
- Dunst to be installed and running as a notification service.
- dmenu to be installed.

Could be modified to do without

# Installation
The install script will prompt for your GitHub Auth token and store it for the script to use
```
bash install.sh
```

# Uninstallation
The uninstall script will remove the systemd service and the script itself and any stored data
```
bash install.sh --uninstall
```

# Troubleshooting
Check the logs for the service
```
systemctl --user status pr-status.service
```

Restart the service
```
systemctl --user restart pr-status.service
```
