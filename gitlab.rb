## GitLab configuration settings

## GitLab URL
external_url 'http://192.168.3.233'

### Backup Settings

# gitlab_rails['manage_backup_path'] = true
# gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"


# gitlab_rails['backup_archive_permissions'] = 0644

# gitlab_rails['backup_pg_schema'] = 'public'

# 修改备份文件保存时间为7天
gitlab_rails['backup_keep_time'] = 604800