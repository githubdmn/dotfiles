If you want to **reinstall Debian**, the safest and cleanest method is to reinstall from a bootable USB. I'll outline the **standard approach most developers use**.

---

# 1️⃣ Backup your data first (very important)

Before reinstalling, save anything important:

- `~/Documents`
- `~/Projects`
- SSH keys → `~/.ssh`
- Git config → `~/.gitconfig`
- Databases or Docker volumes
- Browser bookmarks

You can copy them to:

- external USB drive
- another partition
- cloud storage
- NAS

Example backup command:

```bash
rsync -avh --progress /home/youruser /media/backup/
```

---

# 2️⃣ Download the Debian ISO

Go to the official site of Debian and download the **stable ISO**.

Recommended version:

- **Debian 12 (Bookworm)**

File example:

```
debian-12.x.x-amd64-netinst.iso
```

The **netinst** image is small and downloads packages during install.

---

# 3️⃣ Create a bootable USB

Use a tool such as:

- Rufus (Windows)
- balenaEtcher (Linux/macOS)
- Ventoy (very popular with devs)

Example using `dd` on Linux:

```bash
sudo dd if=debian-12.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Replace:

```
/dev/sdX
```

with your USB device.

---

# 4️⃣ Boot from the USB

Restart your computer and open the **boot menu**:

Common keys:

```
F12
F10
ESC
DEL
```

Select the **USB drive**.

---

# 5️⃣ Install Debian

Choose:

```
Graphical Install
```

Then follow:

1. Language
2. Keyboard
3. Network
4. User creation
5. Disk partitioning

If you want a **full reinstall**:

Choose:

```
Guided - use entire disk
```

⚠️ This **deletes everything** on the disk.

If you want to **keep `/home`**, choose manual partitioning.

---

# 6️⃣ Select desktop environment

You can choose:

- GNOME (default)
- KDE
- XFCE
- LXDE

For developers many prefer:

- **XFCE (lightweight)**
- **GNOME**

---

# 7️⃣ Finish installation

The installer will:

- install base system
- install GRUB bootloader
- reboot

Remove the USB when prompted.

---

# 8️⃣ Update system

After login:

```bash
sudo apt update
sudo apt upgrade
```

---

💡 Since you're a **backend developer using Linux** (Node.js, Docker, databases, etc.), I can also show you:

### 🔧 A **perfect Debian dev setup**

- Docker
- Node.js
- PostgreSQL
- Git
- Zsh + Oh My Zsh
- VS Code
- Dev containers

Your SSH keys are stored in the **`~/.ssh` directory**. Backing them up is simple, but you must do it carefully because they contain **private authentication keys**.

---

# 1️⃣ Check your SSH keys

Run:

```bash
ls -la ~/.ssh
```

Typical output might contain:

```
id_rsa
id_rsa.pub
id_ed25519
id_ed25519.pub
authorized_keys
known_hosts
config
```

Important files:

- `id_ed25519` or `id_rsa` → **private key (very important)**
- `id_ed25519.pub` or `id_rsa.pub` → **public key**
- `config` → SSH host configuration
- `known_hosts` → previously connected servers

---

# 2️⃣ Backup the entire SSH directory

The safest method is to copy the **whole `.ssh` folder**.

### Example: backup to USB

```bash
cp -r ~/.ssh /media/usb/ssh-backup
```

or with `rsync`:

```bash
rsync -av ~/.ssh /media/usb/ssh-backup
```

---

# 3️⃣ Verify the backup

Check that the files exist:

```bash
ls /media/usb/ssh-backup
```

You should see your keys like:

```
id_ed25519
id_ed25519.pub
config
known_hosts
```

---

# 4️⃣ Restore after reinstall

After reinstalling your system:

```bash
cp -r ssh-backup ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
```

This restores correct permissions (important for SSH).

---

# 5️⃣ Test your key

Try connecting to a server:

```bash
ssh user@server
```

or check Git:

```bash
ssh -T git@github.com
```

For example with GitHub or GitLab.

---

✅ **Pro tip (recommended for developers):**

Instead of just copying keys, you can create a **secure encrypted archive**:

```bash
tar -czvf ssh-backup.tar.gz ~/.ssh
```

Or encrypted:

```bash
gpg -c ssh-backup.tar.gz
```

---

To re-establish an SSH connection with GitHub after reinstalling your system (or restoring your SSH keys), follow these steps.

---

# 1️⃣ Restore your SSH keys

If you backed them up earlier:

```bash
cp -r ssh-backup ~/.ssh
```

Fix permissions (important):

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
```

---

# 2️⃣ Start the SSH agent

Run:

```bash
eval "$(ssh-agent -s)"
```

Then add your private key:

```bash
ssh-add ~/.ssh/id_ed25519
```

(or `id_rsa` if that’s the key you used)

---

# 3️⃣ Test the connection

Test authentication with GitHub:

```bash
ssh -T git@github.com
```

Expected message:

```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

---

# 4️⃣ If authentication fails

Check whether the **public key is registered on GitHub**.

Print the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the output.

Then add it in GitHub:

1. Go to **Settings**
2. **SSH and GPG Keys**
3. **New SSH key**
4. Paste the key

---

# 5️⃣ Optional: configure SSH (recommended)

Create or edit:

```bash
nano ~/.ssh/config
```

Example configuration:

```text
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
```

This prevents issues when you have multiple keys.

---

# 6️⃣ Verify Git remote URLs

Ensure your repositories use **SSH instead of HTTPS**.

Check:

```bash
git remote -v
```

You should see something like:

```
git@github.com:username/repo.git
```

If it shows HTTPS:

```bash
git remote set-url origin git@github.com:username/repo.git
```

---

✅ After this, `git push` and `git pull` will work normally with GitHub over SSH.

---

💡 **Pro developer tip:**
Use an **ED25519 key** instead of RSA (modern and more secure):

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

---

If you'd like, I can also show you a **clean professional SSH setup used by senior developers**, including:

- multiple Git accounts (work + personal)
- SSH key isolation
- automatic key loading
- secure agent forwarding.

If `usermod: command not found` appears on Debian, it usually means one of these:

1. You are not running the command as **root**
2. Your **PATH does not include `/usr/sbin`**
3. The **shadow utilities package** is missing (rare)

Let's fix it.

---

# 1️⃣ Try running it with the full path

`usermod` is normally located in `/usr/sbin`.

Run:

```bash
/usr/sbin/usermod -aG sudo username
```

Example:

```bash
/usr/sbin/usermod -aG sudo damjan
```

---

# 2️⃣ If that works, fix your PATH

Check your PATH:

```bash
echo $PATH
```

If `/usr/sbin` is missing, temporarily add it:

```bash
export PATH=$PATH:/usr/sbin
```

---

# 3️⃣ If the command truly doesn't exist

Check if it's installed:

```bash
ls /usr/sbin/usermod
```

If not installed, install the package that provides it:

```bash
apt update
apt install passwd
```

This package contains:

- `usermod`
- `useradd`
- `groupadd`

---

# 4️⃣ Alternative command (works the same)

You can also add a user to sudo with:

```bash
adduser username sudo
```

Example:

```bash
adduser john sudo
```

Then log out and back in.

---

# 5️⃣ Verify

```bash
groups john
```

You should see:

```
john : john sudo
```

---

✅ After that:

```bash
sudo apt update
```

should work.

---

💡 Quick tip: on minimal installs of Debian, `/usr/sbin` is often **only in root's PATH**, which is why normal users sometimes see _“command not found”_ for admin utilities.
