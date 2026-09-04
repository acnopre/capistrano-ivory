# Capistrano Ivory - Setup & Deployment Guide

## Prerequisites

- macOS with Homebrew installed

## Server

- Host: `<server-ip>`
- User: `<server-user>`
- SSH: `ssh <server-user>@<server-ip>`

## Setup Instructions

### 1. Install Homebrew Ruby (skip if already done)
```sh
brew install ruby
```

### 2. Add Homebrew Ruby to PATH
```sh
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 3. Verify Ruby version (should be 4.x, not system 2.6)
```sh
which ruby && ruby -v
```

### 4. Install required gems
```sh
gem install capistrano ed25519 bcrypt_pbkdf dotenv
```

### 5. Add your SSH key to the server
```sh
ssh-copy-id -i ~/.ssh/id_ed25519.pub <server-user>@<server-ip>
```

### 6. Configure your .env file
Copy and fill in your environment values:
```sh
cp .env.example .env
```

## Deploy

```sh
cap production deploy
```
