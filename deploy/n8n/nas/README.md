# Synology DS220j backup pull

The NAS pulls encrypted files from the VPS. Do not expose DSM, SMB, or rsync ports to the internet.

1. In DSM, enable SSH temporarily and create an SSH key dedicated to VPS backup reads.
2. Use the password-locked `coa-backup` account created by `deploy.ps1`. It receives read-only group access to `/opt/backups/coa-n8n`.
3. Put the private key at `/volume1/backup/coa-n8n/keys/vps-backup` with mode `600`.
4. Copy `pull-backups.sh` to the NAS and test it manually.
5. In DSM Task Scheduler, run it daily after 03:00 as a user that can write the backup folder.
6. Store `BACKUP_ENCRYPTION_PASSWORD` separately in a password manager. The NAS backup is unusable without it.

The DS220j can stay on continuously, or use DSM scheduled power-on before the task and scheduled shutdown afterward. A missed run is recovered by the next `rsync` because existing encrypted archives remain on the VPS for seven days.
