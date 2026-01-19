############### How ?
# ./deploy_ssh.sh /home/cube/.ssh /run/secrets/ cube
###############

SSH_FOLDER="$1"
SECRET_FOLDER="$2"
USERNAME="$3"


function md5FolderSum(){
  find "$1" -type f -exec md5sum {} \; 2>/dev/null | sort | cut -d" " -f1 | md5sum | cut -d" " -f1 || echo "none"
}

ssh_now=$(md5FolderSum "$SSH_FOLDER")
ssh_backup=$(md5FolderSum /backup/latest/)

if [[ -d "$SSH_FOLDER" ]] && [[ "$ssh_now" != "$ssh_backup" ]]; then
  now=$(date +"%Y_%m_%d__%H_%M_%S")
  mkdir -p /backup
  cp -r "$SSH_FOLDER" /backup/ssh_$now
  chown -R "$USERNAME:users" /backup/ssh_$now
  rm -f /backup/latest
  ln -s /backup/ssh_$now /backup/latest
  chown -R "$USERNAME:users" /backup/latest
  echo "~/.ssh folder saved to: /backup/ssh_$now"
fi

rsync -az "$SECRET_FOLDER/" "$SSH_FOLDER/"
chown -R "$USERNAME:users" "$SSH_FOLDER"
chmod 700 "$SSH_FOLDER"
find "$SSH_FOLDER" -type f -exec chmod 600 {} +
