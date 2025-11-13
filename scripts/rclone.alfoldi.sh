# rclone --filter-from config-files/rclone-filters.txt --config ~/.config/rclone/b2.storage.conf sync /home/alfoldi/workplace/home/ b2-storage:cnwco-storage/alfoldi/home --delete-excluded
# rclone --filter-from config-files/rclone-filters.txt --config ~/.config/rclone/b2.storage.conf sync /home/alfoldi/workplace/home/ b2-storage:cnwco-storage/alfoldi/home --dry-run
rclone --filter-from config-files/rclone-filters.txt --config ~/.config/rclone/b2.storage.conf sync /home/alfoldi/workplace/NOKIA/ b2-storage:cnwco-storage/alfoldi/NOKIA --dry-run
