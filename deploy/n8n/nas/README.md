# Synology DS220j backup pull

The NAS pulls encrypted files from the VPS. Do not expose DSM, SMB, or rsync ports to the internet.

1. In DSM, enable SSH temporarily and create an Ed25519 key dedicated to VPS backup reads: `ssh-keygen -t ed25519 -f /volume1/backup/coa-n8n/keys/vps-backup -C nas-coa-backup`.
2. Copy only the `.pub` line to the VPS and run `/opt/n8n/nas/install-vps-key.sh 'ssh-ed25519 AAAA... nas-coa-backup'` as root. The forced `rrsync -ro` command prevents shell access and restricts reads to `/opt/backups/coa-n8n`.
3. Put the private key at `/volume1/backup/coa-n8n/keys/vps-backup` with mode `600`.
4. Copy `pull-backups.sh` to the NAS and test it manually.
5. In DSM Task Scheduler, run it daily after 03:00 as a user that can write the backup folder.
6. Store `BACKUP_ENCRYPTION_PASSWORD` separately in a password manager. The NAS backup is unusable without it.

The DS220j can stay on continuously, or use DSM scheduled power-on before the task and scheduled shutdown afterward. A missed run is recovered by the next `rsync` because existing encrypted archives remain on the VPS for seven days.
