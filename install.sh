#! /bin/bash

CONFFILE=~/.config/github.conf
STATUSFILE=~/.pr-review-polling
SCRIPTDIR=/usr/local/bin/
SYSTEMDDIR=~/.config/systemd/user/

function get_token {
    echo "Please enter your github auth token: "
    read TOKEN
    touch $CONFFILE
    echo $TOKEN > $CONFFILE
}

while getopts ":u-:" opt; do
case $opt in
  u|uninstall)
      UNINSTALL=true
      ;;
  -)
      case "${OPTARG}" in
        uninstall)
            UNINSTALL=true
          ;;
        *)
          echo "Invalid option: --$OPTARG"
          exit 1
          ;;
      esac
      ;;
  \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
esac
done

if [ "$UNINSTALL" = true ]; then
    echo "Uninstalling pr-review-polling service"
    systemctl --user stop pr-review-polling.service || { echo "Cannot stop service"; exit 1;  }
    systemctl --user disable pr-review-polling.service || { echo "Cannot disable service"; exit 1;  }
    systemctl --user daemon-reload || { echo "Cannot reload systemd"; exit 1;  }
    systemctl --user reset-failed || { echo "Cannot reset-failed systemd"; exit 1;  }
    rm $SYSTEMDDIR/pr-review-polling.service || { echo "Cannot remove systemd file"; exit 1;  }
    rm $STATUSFILE || { echo "Cannot remove status file"; exit 1;  }
    rm $CONFFILE || { echo "Cannot remove config file"; exit 1;  }
    exit 0
fi

echo "Installing pr-review-polling service"

if [ -f "$CONFFILE" ]; then
    echo "$CONFFILE exists."
    read -e -p "Would you like to overwrite your existing token? " choice
    [[ "$choice" == [Yy]* ]] && get_token
else
    get_token
fi

sudo cp pr-review-polling.sh $SCRIPTDIR || { echo "Cannot move new script to run location"; exit 1;  }
sudo chmod +x $SCRIPTDIR/pr-review-polling.sh || { echo "Cannot set script executable"; exit 1;  }

touch $STATUSFILE

mkdir -p $SYSTEMDDIR || { echo "Cannot make systemd dir: $SYSTEMDDIR"; exit 1; }
cp pr-review-polling.service $SYSTEMDDIR || { echo "Cannot move systemd file"; exit 1;  }
systemctl --user daemon-reload || { echo "Cannot reload systemd"; exit 1;  }
systemctl --user enable pr-review-polling.service || { echo "Cannot enable systemd service"; exit 1;  }
systemctl --user start pr-review-polling.service || { echo "Cannot start systemd service"; exit 1;  }
systemctl --user restart pr-review-polling.service || { echo "Cannot restart systemd service"; exit 1;  }
echo "Service is ... $(systemctl --user is-enabled pr-review-polling.service)"
