# Firebase MCP setup (Firestore access)

To let Cursor's Firebase MCP read/write Firestore (e.g. inspect `chats`, `messages`, `user_chats`), do the following once.

## 1. Use gcloud

Google Cloud SDK is available at:

```bash
/opt/homebrew/share/google-cloud-sdk/bin/gcloud
```

To have `gcloud` on your PATH in new terminals, add to `~/.zshrc`:

```bash
source /opt/homebrew/share/google-cloud-sdk/path.zsh.inc
```

Then run `source ~/.zshrc` or open a new terminal.

## 2. Log in

```bash
gcloud auth login
```

Complete the browser flow so `gcloud` has an active account.

## 3. Set project (optional)

```bash
gcloud config set project linkstage-rw
```

## 4. Enable Firestore for MCP

Run the command that was in the MCP error (if your Firebase MCP supports it):

```bash
gcloud beta services mcp enable firestore.googleapis.com --project=linkstage-rw
```

If that fails or `beta` is not installed, install beta and retry:

```bash
gcloud components install beta
gcloud beta services mcp enable firestore.googleapis.com --project=linkstage-rw
```

Alternatively, ensure the Firestore API is enabled for the project (required for the app anyway):

```bash
gcloud services enable firestore.googleapis.com --project=linkstage-rw
```

After this, the Firebase MCP in Cursor may be able to list/query Firestore (e.g. `chats`, `user_chats`, messages subcollections) for debugging.
