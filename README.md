# Simple Backup

A simple backup script in powershell using 7zip to back up folders.

## Usage

1. Install 7zip.
2. Download the script and place it in any folder.
3. Create a `backup.json` file in the same folder as the script.
4. Run the script. It will list the folders and ask to proceed, before doing anything.

Example `backup.json`:

```json
{
    "source": "C:\\data\\Photos",
    "target": "D:\\Photos",
    "path7z": "C:\\Program Files\\7-Zip\\7z.exe"
}
```