# Deploy
kubectl apply -f gitlab/statefulset-gitlab.yaml
kubectl get pod gitlab-0 --watch
kubectl wait --for=condition=ready pod gitlab-0

# Test HTTP
curl http://gitlab.172.19.0.1.sslip.io/-/health
firefox http://gitlab.172.19.0.1.sslip.io

# Create a root Token
kubectl exec -it gitlab-0 -- \
  gitlab-rails runner '
  token = User.find_by_username("root").personal_access_tokens.create(scopes: ["api"], name: "root_token", expires_at: 365.days.from_now);
  token.set_token("KoohooX0Eisoo6su");
  token.save!'

# Create a Repo
(
mkdir /tmp/alpine
cd /tmp/alpine
echo '# Alpine' > readme.md
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git init --initial-branch=main
git remote add origin https://anything:KoohooX0Eisoo6su@gitlab.wiltoncarvalho.com/root/alpine.git
git add readme.md
git commit -m "Initial commit"
git push --set-upstream origin main
)

# Test Registry with Docker
echo "KoohooX0Eisoo6su" | \
  docker login https://registry.wiltoncarvalho.com \
  -u "anything" --password-stdin
docker pull alpine:3.18
docker tag alpine:3.18 \
  registry.wiltoncarvalho.com/root/alpine:3.18
docker push registry.wiltoncarvalho.com/root/alpine:3.18

# Test Registry with Skopeo
sudo mkdir -m 1777 /run/containers
echo "KoohooX0Eisoo6su" | \
  skopeo login https://registry.wiltoncarvalho.com \
  -u "anything" --password-stdin --tls-verify=false 
skopeo copy --src-tls-verify=false --dest-tls-verify=false \
  docker://docker.io/library/alpine:3.17 \
  docker://registry.wiltoncarvalho.com/root/alpine:3.17

# Test SSH
kubectl get svc/gitlab-ssh -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
ssh-keyscan 172.19.255.202

### Backup and Restore ###
# Backup
kubectl exec -it gitlab-0 -- gitlab-ctl backup-etc --backup-path /var/opt/gitlab/backups
kubectl exec -it gitlab-0 -- gitlab-backup create

# Copy Backup
kubectl cp gitlab-0:/var/opt/gitlab/backups backups

### Restore to a New Installation ###
# Disable Liveness and Readness Probes
kubectl apply -f gitlab/statefulset-gitlab.yaml

# Stop the processes that are connected to the database
kubectl exec -it gitlab-0 -- gitlab-ctl stop puma
kubectl exec -it gitlab-0 -- gitlab-ctl stop sidekiq

# Verify that the processes are all down before continuing
kubectl exec -it gitlab-0 -- gitlab-ctl status
curl http://gitlab.172.19.0.1.sslip.io/-/health
kubectl logs gitlab-0

# Run the restore. NOTE: "_gitlab_backup.tar" is omitted from the name
kubectl cp backups gitlab-0:/var/opt/gitlab

kubectl exec -it gitlab-0 -- ls -lh /var/opt/gitlab/backups
kubectl exec -it gitlab-0 -- gitlab-backup restore BACKUP=1699893168_2023_11_13_16.1.2
kubectl exec -it gitlab-0 -- tar -xvf /var/opt/gitlab/backups/gitlab_config_1699893142_2023_11_13.tar -C /

# Enable Liveness and Readness Probes
kubectl apply -f gitlab/statefulset-gitlab.yaml

# Check GitLab
kubectl exec -it gitlab-0 -- gitlab-rake gitlab:check SANITIZE=true