package main

import (
	"fmt"
	"os"

	"github.com/alim7007/devops_tasks/file_integrity_checker/internal/hash"
	"github.com/alim7007/devops_tasks/file_integrity_checker/internal/scanner"
	"github.com/alim7007/devops_tasks/file_integrity_checker/internal/storage"
)

// Color codes
const (
	ColorReset  = "\033[0m"
	ColorRed    = "\033[31m"
	ColorGreen  = "\033[32m"
	ColorYellow = "\033[33m"
)

func main() {
	if len(os.Args) < 3 {
		showUsage()
		os.Exit(1)
	}

	command := os.Args[1]
	path := os.Args[2]

	switch command {
	case "init":
		cmdInit(path)
	case "check":
		cmdCheck(path)
	case "update":
		cmdUpdate(path)
	default:
		fmt.Printf("%sError: Unknown command '%s'%s\n", ColorRed, command, ColorReset)
		showUsage()
		os.Exit(1)
	}
}

func showUsage() {
	fmt.Println("Usage: integrity-check <command> <path>")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  init <path>    Initialize and store hashes for files")
	fmt.Println("  check <path>   Check file integrity against stored hashes")
	fmt.Println("  update <path>  Update stored hashes for files")
	fmt.Println()
	fmt.Println("Examples:")
	fmt.Println("  integrity-check init /var/log")
	fmt.Println("  integrity-check check /var/log/syslog")
	fmt.Println("  integrity-check update /var/log/auth.log")
}

func cmdInit(path string) {
	files, err := scanner.GetFiles(path)
	if err != nil {
		fmt.Printf("%sError: %v%s\n", ColorRed, err, ColorReset)
		os.Exit(1)
	}

	fmt.Printf("Initializing integrity database for: %s\n", path)

	count := 0
	for _, file := range files {
		fmt.Printf("Hashing: %s\n", file)

		fileHash, err := hash.CalculateHash(file)
		if err != nil {
			fmt.Printf("%sError hashing %s: %v%s\n", ColorRed, file, err, ColorReset)
			continue
		}

		if err := storage.SetHash(file, fileHash); err != nil {
			fmt.Printf("%sError storing hash for %s: %v%s\n", ColorRed, file, err, ColorReset)
			continue
		}

		count++
	}

	fmt.Printf("%sSuccessfully hashed %d file(s).%s\n", ColorGreen, count, ColorReset)
}

func cmdCheck(path string) {
	files, err := scanner.GetFiles(path)
	if err != nil {
		fmt.Printf("%sError: %v%s\n", ColorRed, err, ColorReset)
		os.Exit(1)
	}

	modified := 0
	unmodified := 0

	for _, file := range files {
		currentHash, err := hash.CalculateHash(file)
		if err != nil {
			fmt.Printf("%sError hashing %s: %v%s\n", ColorRed, file, err, ColorReset)
			continue
		}

		storedHash, exists, err := storage.GetHash(file)
		if err != nil {
			fmt.Printf("%sError loading hash for %s: %v%s\n", ColorRed, file, err, ColorReset)
			continue
		}

		if !exists {
			fmt.Printf("%s%s: Not tracked (run init first)%s\n", ColorYellow, file, ColorReset)
		} else if currentHash == storedHash {
			fmt.Printf("%s%s: Unmodified%s\n", ColorGreen, file, ColorReset)
			unmodified++
		} else {
			fmt.Printf("%s%s: Modified (Hash mismatch)%s\n", ColorRed, file, ColorReset)
			modified++
		}
	}

	fmt.Println()
	fmt.Printf("Summary: %d unmodified, %d modified\n", unmodified, modified)
}

func cmdUpdate(path string) {
	files, err := scanner.GetFiles(path)
	if err != nil {
		fmt.Printf("%sError: %v%s\n", ColorRed, err, ColorReset)
		os.Exit(1)
	}

	for _, file := range files {
		newHash, err := hash.CalculateHash(file)
		if err != nil {
			fmt.Printf("%sError hashing %s: %v%s\n", ColorRed, file, err, ColorReset)
			continue
		}

		if err := storage.SetHash(file, newHash); err != nil {
			fmt.Printf("%sError updating hash for %s: %v%s\n", ColorRed, file, err, ColorReset)
			continue
		}

		fmt.Printf("%s%s: Hash updated successfully%s\n", ColorGreen, file, ColorReset)
	}
}