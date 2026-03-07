#!/usr/bin/env python3
"""
Deploy files to Mac via SSH.
First run: asks for password, encrypts and saves it.
Next runs: uses saved password automatically.

Requirements: pip install paramiko cryptography
"""

import os
import sys
import json
import getpass
import hashlib
import base64
from pathlib import Path

try:
    import paramiko
except ImportError:
    print("Installing paramiko...")
    os.system(f"{sys.executable} -m pip install paramiko")
    import paramiko

from cryptography.fernet import Fernet

# ============================================================
# CONFIGURATION — edit these values as needed
# ============================================================

SSH_HOST = "85.204.125.87"
SSH_PORT = 22
SSH_USER = "timonchukdesign"

# Base remote directory on the Mac
REMOTE_BASE = "/Users/timonchukdesign/Desktop/qurio-ios"

# Deploy mapping: (local_path, remote_path_relative_to_REMOTE_BASE)
# Xcode project is at QuiroIOSApp/QuiroIOSApp.xcodeproj
# Source files are read from QuiroIOSApp/QuiroIOSApp/
DEPLOY_MAP = [
    # Main app source → into the Xcode source folder
    (r"C:\Users\timon\Downloads\iphon\QurioIOSApp",             "QuiroIOSApp/QuiroIOSApp"),

    # Widget extension → inside the Xcode project folder
    (r"C:\Users\timon\Downloads\iphon\QurioWidgetExtension",    "QuiroIOSApp/QurioWidgetExtension"),

    # Broadcast extension → inside the Xcode project folder
    (r"C:\Users\timon\Downloads\iphon\BroadcastUploadExtension", "QuiroIOSApp/BroadcastUploadExtension"),

    # Config files → root level
    (r"C:\Users\timon\Downloads\iphon\codemagic.yaml",          "codemagic.yaml"),
    (r"C:\Users\timon\Downloads\iphon\.gitignore",              ".gitignore"),
    (r"C:\Users\timon\Downloads\iphon\README.md",               "README.md"),

    # --- Add more mappings below ---
    # (r"C:\path\to\local",  "remote/relative/path"),
]

# Folders/files to SKIP (by name)
SKIP_NAMES = {".git", ".DS_Store", "__pycache__", "node_modules", ".build"}

# Files to skip in specific subdirectories (to avoid Xcode duplicate compile errors)
# Format: {"parent_folder_name": {"filename_to_skip"}}
SKIP_IN_PATHS = {
    "LiveActivity": {"QuiroActivityAttributes.swift"},
}

# ============================================================
# END OF CONFIGURATION
# ============================================================

CONFIG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".deploy_creds.enc")
KEY_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".deploy_key.key")


def generate_key():
    """Generate and save an encryption key."""
    key = Fernet.generate_key()
    with open(KEY_FILE, "wb") as f:
        f.write(key)
    # Hide file on Windows
    if sys.platform == "win32":
        os.system(f'attrib +h "{KEY_FILE}"')
    return key


def load_key():
    """Load the encryption key."""
    with open(KEY_FILE, "rb") as f:
        return f.read()


def encrypt_password(password: str) -> bytes:
    """Encrypt the password using Fernet."""
    if not os.path.exists(KEY_FILE):
        key = generate_key()
    else:
        key = load_key()
    f = Fernet(key)
    return f.encrypt(password.encode())


def decrypt_password(encrypted: bytes) -> str:
    """Decrypt the password."""
    key = load_key()
    f = Fernet(key)
    return f.decrypt(encrypted).decode()


def save_credentials(password: str):
    """Encrypt and save the password."""
    encrypted = encrypt_password(password)
    with open(CONFIG_FILE, "wb") as f:
        f.write(encrypted)
    # Hide file on Windows
    if sys.platform == "win32":
        os.system(f'attrib +h "{CONFIG_FILE}"')
    print("✅ Password encrypted and saved!")


def load_credentials() -> str:
    """Load and decrypt the saved password."""
    with open(CONFIG_FILE, "rb") as f:
        encrypted = f.read()
    return decrypt_password(encrypted)


def get_password() -> str:
    """Get password: load saved or ask user on first run."""
    if os.path.exists(CONFIG_FILE) and os.path.exists(KEY_FILE):
        try:
            password = load_credentials()
            print("🔑 Using saved credentials...")
            return password
        except Exception:
            print("⚠️  Saved credentials are invalid. Please re-enter.")

    print(f"\n🔐 First run! Enter SSH password for {SSH_USER}@{SSH_HOST}")
    password = getpass.getpass("Password: ")
    save_credentials(password)
    return password


def ssh_connect(password: str) -> paramiko.SSHClient:
    """Create SSH connection."""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"\n🔗 Connecting to {SSH_HOST}:{SSH_PORT}...")
    client.connect(SSH_HOST, port=SSH_PORT, username=SSH_USER, password=password, timeout=15)
    print("✅ Connected!")
    return client


def ensure_remote_dir(sftp: paramiko.SFTPClient, remote_path: str):
    """Recursively create remote directories."""
    dirs_to_create = []
    path = remote_path
    while True:
        try:
            sftp.stat(path)
            break
        except FileNotFoundError:
            dirs_to_create.append(path)
            path = os.path.dirname(path)
            if not path or path == "/":
                break

    for d in reversed(dirs_to_create):
        try:
            sftp.mkdir(d)
        except Exception:
            pass


def upload_file(sftp: paramiko.SFTPClient, local_path: str, remote_path: str):
    """Upload a single file."""
    remote_dir = os.path.dirname(remote_path).replace("\\", "/")
    ensure_remote_dir(sftp, remote_dir)
    sftp.put(local_path, remote_path)


def upload_directory(sftp: paramiko.SFTPClient, local_dir: str, remote_dir: str, stats: dict):
    """Recursively upload a directory."""
    ensure_remote_dir(sftp, remote_dir)

    for item in os.listdir(local_dir):
        if item in SKIP_NAMES:
            continue

        # Skip specific files in specific parent folders
        parent_name = os.path.basename(local_dir)
        if parent_name in SKIP_IN_PATHS and item in SKIP_IN_PATHS[parent_name]:
            print(f"  ⏭️  Skipping {item} (duplicate in {parent_name}/)")
            continue

        local_path = os.path.join(local_dir, item)
        remote_path = f"{remote_dir}/{item}"

        if os.path.isdir(local_path):
            upload_directory(sftp, local_path, remote_path, stats)
        else:
            try:
                upload_file(sftp, local_path, remote_path)
                stats["uploaded"] += 1
                print(f"  📄 {item}")
            except Exception as e:
                stats["failed"] += 1
                print(f"  ❌ {item}: {e}")


def deploy():
    """Main deploy function."""
    password = get_password()

    try:
        client = ssh_connect(password)
    except paramiko.AuthenticationException:
        print("\n❌ Authentication failed! Wrong password.")
        # Delete saved credentials so user can re-enter
        if os.path.exists(CONFIG_FILE):
            os.remove(CONFIG_FILE)
        if os.path.exists(KEY_FILE):
            os.remove(KEY_FILE)
        print("🔄 Saved credentials deleted. Run again to re-enter password.")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Connection failed: {e}")
        sys.exit(1)

    sftp = client.open_sftp()
    stats = {"uploaded": 0, "failed": 0}

    print(f"\n📁 Deploying to {SSH_HOST}:{REMOTE_BASE}\n")
    ensure_remote_dir(sftp, REMOTE_BASE)

    for local_path, remote_rel in DEPLOY_MAP:
        if not os.path.exists(local_path):
            print(f"⚠️  Not found, skipping: {local_path}")
            continue

        remote_full = f"{REMOTE_BASE}/{remote_rel}"
        name = os.path.basename(local_path)

        if os.path.isdir(local_path):
            print(f"\n📂 Uploading folder: {name}/ → {remote_rel}/")
            upload_directory(sftp, local_path, remote_full, stats)
        else:
            print(f"\n📄 Uploading file: {name} → {remote_rel}")
            try:
                upload_file(sftp, local_path, remote_full)
                stats["uploaded"] += 1
            except Exception as e:
                stats["failed"] += 1
                print(f"  ❌ Error: {e}")

    sftp.close()
    client.close()

    print(f"\n{'='*50}")
    print(f"✅ Deploy complete!")
    print(f"   Uploaded: {stats['uploaded']} files")
    print(f"   Failed:   {stats['failed']} files")
    print(f"   Target:   {SSH_USER}@{SSH_HOST}:{REMOTE_BASE}")
    print(f"{'='*50}")


if __name__ == "__main__":
    deploy()

