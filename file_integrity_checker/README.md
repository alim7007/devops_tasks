- ✅ 19. File Integrity Checker Task from https://roadmap.sh/projects/file-integrity-checker

A security tool that detects unauthorized modifications to log files using cryptographic hashing (SHA-256).

---

## What It Does

- **Creates fingerprints** (SHA-256 hashes) of files
- **Stores them** in `hashes.json`
- **Detects tampering** by comparing current vs stored hashes
- Works on **single files** or **entire directories**

---

## Usage

```bash
# Initialize - scan and store hashes
./integrity-check init /var/log

# Check for modifications
./integrity-check check /var/log/syslog

# Update hashes after legitimate changes
./integrity-check update /var/log/syslog
```

---

## How It Works

### 1. **Init Command**
```bash
./integrity-check init /path
```
- Scans all files in path (recursively if directory)
- Calculates SHA-256 hash for each file
- Stores in `hashes.json`: `{"filepath": "hash"}`
- Creates baseline for future comparisons

### 2. **Check Command**
```bash
./integrity-check check /path
```
- Recalculates current hashes
- Compares with stored hashes
- Reports:
  - ✅ **Unmodified** - hash matches
  - ❌ **Modified** - hash mismatch (tampering detected)
  - ⚠️ **Not tracked** - file not in database

### 3. **Update Command**
```bash
./integrity-check update /path
```
- Recalculates hashes
- Updates `hashes.json` with new values
- Use after legitimate file changes

---

## Key Concepts

### **SHA-256 Hashing**
A cryptographic function that creates a unique "fingerprint" for files:
- Input: Any file content
- Output: 64-character hex string (e.g., `a3f5b8c9d2e1...`)
- **Deterministic**: Same file = same hash
- **Collision-resistant**: Different files ≠ same hash (practically impossible)
- **Sensitive**: Change 1 byte → completely different hash

**Example:**
```
File: "Hello World"     → Hash: 64ec88ca00b268e5...
File: "Hello World!"    → Hash: 7f83b1657ff1fc53...  (totally different!)
```

### **Why Log Files Keep Changing**
Real-world challenge: Logs are **supposed to update**!

**This tool is best for:**
- ✅ **Archived/rotated logs** (shouldn't change: `syslog.1`, `auth.log.2024-10-08`)
- ✅ **Configuration files** (change rarely)
- ✅ **Static system files**

**Not ideal for:**
- ❌ Active log files (constantly appending new lines)

**Real-world solutions** (beyond this project):
- Line-by-line hashing (detect line modifications vs new lines)
- Append-only monitoring (new lines OK, edits/deletions = alert)
- Real-time monitoring instead of periodic checks

---

## Technical Implementation

### **Bash Version**

#### Key Bash Concepts Used

**1. Command-Line Arguments**
```bash
command="$1"  # First argument
path="$2"     # Second argument
```

**2. Functions**
```bash
hash_file() {
    local filepath="$1"  # local = function-scoped variable
    sha256sum "$filepath" | awk '{print $1}'
}
```

**3. File Testing**
```bash
[[ -f "$path" ]]  # True if file exists
[[ -d "$path" ]]  # True if directory exists
[[ -e "$path" ]]  # True if path exists (file or dir)
```

**4. Reading Files Safely**
```bash
while IFS= read -r file; do
    # Process each file
done < <(get_all_files "$path")
```
- `IFS=` prevents word splitting
- `-r` preserves backslashes
- `< <(...)` process substitution (feeds command output to while loop)

**5. JSON Manipulation with jq**

**Adding/Updating a hash:**
```bash
jq --arg path "$filepath" --arg hash "$hash" \
   '. + {($path): $hash}' "$HASH_FILE" > "$temp_file"
```
- `--arg path "$filepath"` → passes Bash variable into jq as `$path`
- `. + {($path): $hash}` → merge new key-value into existing JSON
- `> "$temp_file"` → write to temp file (atomic update)

**Reading a hash:**
```bash
jq -r --arg path "$filepath" '.[$path] // ""' "$HASH_FILE"
```
- `-r` → raw output (no quotes)
- `.[$path]` → get value for key
- `// ""` → return empty string if null/missing

**Why temp file + move?**
```bash
jq ... "$HASH_FILE" > "$temp_file"
mv "$temp_file" "$HASH_FILE"
```
- Direct overwrite (`jq ... > "$HASH_FILE"`) truncates file first → data loss if jq fails
- Temp file + atomic move → safe, all-or-nothing update

#### Helper Functions Architecture
```
validate_path()      → Check path exists
is_file_or_dir()     → Determine type (file/directory)
get_all_files()      → List all files (handles both types)
hash_file()          → Calculate SHA-256
save_hash()          → Store in JSON
load_hash()          → Retrieve from JSON

cmd_init()           → Initialize database
cmd_check()          → Check integrity
cmd_update()         → Update hashes
```

---

### **Go Version**

#### Project Structure
```
file-integrity-checker/
├── main.go                  # Entry point, CLI logic
├── go.mod                   # Module definition
└── internal/                # Internal packages
    ├── scanner/
    │   └── scanner.go       # File discovery
    ├── hash/
    │   └── hash.go          # SHA-256 calculation
    └── storage/
        └── storage.go       # JSON read/write
```

#### Key Go Concepts Used

**1. Packages**
```go
package scanner  // Declares package name

// Import in main.go:
import "file-integrity-checker/internal/scanner"
```

**2. Error Handling**
```go
files, err := scanner.GetFiles(path)
if err != nil {
    fmt.Printf("Error: %v\n", err)
    os.Exit(1)
}
```
Go uses explicit error returns (no exceptions).

**3. Variadic Return Values**
```go
func GetFiles(path string) ([]string, error) {
    // Returns: slice of strings + error
    return files, nil
}
```

**4. Defer (Cleanup)**
```go
file, err := os.Open(filePath)
if err != nil {
    return "", err
}
defer file.Close()  // Runs when function exits (like finally)
```

**5. JSON Marshal/Unmarshal**
```go
// Go struct → JSON
data, _ := json.MarshalIndent(store, "", "  ")

// JSON → Go map
var store HashStore
json.Unmarshal(data, &store)
```

**6. File Hashing**
```go
hasher := sha256.New()           // Create hasher
io.Copy(hasher, file)            // Feed file content
hashBytes := hasher.Sum(nil)     // Get hash
hashString := fmt.Sprintf("%x", hashBytes)  // Convert to hex
```

---

## Comparison: Bash vs Go

| Feature | Bash | Go |
|---------|------|-----|
| **Setup** | Needs `jq` installed | Needs Go toolchain |
| **Speed** | Slower (spawns processes) | Faster (compiled) |
| **Portability** | Linux/Mac (sh available) | Cross-platform binary |
| **Code Size** | ~200 lines | ~300 lines |
| **Best For** | Quick scripts, sysadmin tasks | Production tools, large projects |

---

## Security Considerations

### What This Tool Detects
✅ File content modifications  
✅ File replacements  
✅ Unauthorized edits  

### What It Doesn't Detect
❌ Changes to file permissions  
❌ Timestamp manipulation  
❌ Tampering with `hashes.json` itself  

### Improvements for Production
- Store hashes in **write-protected location** (root-owned)
- Use **HMAC** (keyed hash) to prevent hash database tampering
- Add **digital signatures** to hash database
- Implement **real-time monitoring** (inotify/fsnotify)
- Hash **individual log lines** instead of whole files

---

## Learning Outcomes

After completing this project, you understand:

- ✅ **Cryptographic hashing** (SHA-256) and its security properties
- ✅ **File system operations** (reading, traversing directories)
- ✅ **Command-line tools** design patterns
- ✅ **Data persistence** (JSON storage)
- ✅ **Error handling** in scripts/programs
- ✅ **Security concepts** (integrity monitoring, tampering detection)

**Bash-specific:**
- Process substitution, functions, jq, file tests

**Go-specific:**
- Package structure, error handling, interfaces, io operations

---

## Common Issues & Solutions

### Issue: "jq: command not found"
```bash
# Install jq
sudo apt install jq        # Ubuntu/Debian
brew install jq            # macOS
```

### Issue: "go: command not found" 
Check Go installation and PATH:
```bash
which go
go version
echo $GOPATH
```

### Issue: Changes not detected
- Ensure you ran `init` first
- Check `hashes.json` exists and contains hashes
- Verify file paths are absolute (or consistent)
