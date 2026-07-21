# DNF Repository

Users can install minectl directly via DNF from GitHub Releases.

## Installation

### Quick Install (from GitHub Releases)

```bash
# Install latest release directly
sudo dnf install -y https://github.com/yourusername/minectl/releases/download/v0.4.0/minectl-0.4.0-1.el8.noarch.rpm
```

Or use the install script:

```bash
curl -fsSL https://yourusername.github.io/minectl/install.sh | bash
```

### Setup Repository (Recommended)

Host the `repo/` directory on GitHub Pages or a web server.

```bash
# Add repository
sudo dnf config-manager --add-repo https://yourusername.github.io/minectl/repo/

# Install
sudo dnf install -y minectl

# Update later
sudo dnf update minectl
```

## Repository Hosting

The `repo/` directory contains:

```bash
repo/
├── repodata/          # Generated metadata
├── Packages/          # RPM files
└── index.html         # Optional directory listing
```

### Setup on GitHub Pages

1. Create `repo/` directory in project
2. Add RPMs to `repo/Packages/`
3. Generate metadata: `createrepo repo/`
4. Push to `gh-pages` branch
5. Enable GitHub Pages in repository settings

```bash
mkdir -p repo/Packages
cp ~/rpmbuild/RPMS/noarch/*.rpm repo/Packages/
createrepo repo/
git add repo/
git commit -m "Add minectl RPM"
git push origin gh-pages
```

### Setup on Static Host

Upload `repo/` directory to any HTTP server:

```bash
scp -r repo/ user@server:/var/www/minectl/
# Users add: sudo dnf config-manager --add-repo http://server/minectl/repo/
```

## Building and Publishing

1. **Tag release**: `git tag v0.4.0 && git push --tags`
2. **GitHub Actions builds** and uploads to Releases automatically
3. **Download RPM** from GitHub Releases
4. **Add to repo**: `cp minectl-0.4.0-1.el8.noarch.rpm repo/Packages/`
5. **Update metadata**: `createrepo repo/`
6. **Push to GitHub Pages**: `git push`

## User Workflow

After repo setup:

```bash
# Install
sudo dnf install minectl

# Setup config
mkdir -p ~/.minectl
cat > ~/.minectl/config <<EOF
CONFIG_DIR=/home/minecraft-servers
SSH_USER=minecraft-servers
EOF

# Use
minectl init user@host
```

## Maintenance

### Update Repository

```bash
# Download new RPM from Releases
wget https://github.com/yourusername/minectl/releases/download/vX.Y.Z/minectl-X.Y.Z-1.el8.noarch.rpm

# Add to repo
cp minectl-X.Y.Z-1.el8.noarch.rpm repo/Packages/

# Regenerate metadata
createrepo repo/

# Push
git add repo/
git commit -m "Update minectl to vX.Y.Z"
git push
```

### Clean Old Versions

```bash
# Remove old RPMs
rm repo/Packages/minectl-*-old-version.noarch.rpm

# Regenerate
createrepo repo/

git add repo/
git commit -m "Remove old versions"
git push
```

## Testing Repository

```bash
# Add test repo
sudo dnf config-manager --add-repo http://localhost:8000/repo/

# Serve locally (for testing)
cd repo && python3 -m http.server 8000

# Install from local repo
sudo dnf install minectl
```
