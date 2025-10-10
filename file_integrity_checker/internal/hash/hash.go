package hash

import (
	"crypto/sha256"
	"fmt"
	"io"
	"os"
)

// CalculateHash computes SHA-256 hash of a file
func CalculateHash(filePath string) (string, error) {
	// Open the file
	file, err := os.Open(filePath)
	if err != nil {
		return "", fmt.Errorf("cannot open file: %w", err)
	}
	defer file.Close()

	// Create SHA-256 hasher
	hasher := sha256.New()

	// Copy file content to hasher
	if _, err := io.Copy(hasher, file); err != nil {
		return "", fmt.Errorf("error reading file: %w", err)
	}

	// Get the hash as hex string
	hashBytes := hasher.Sum(nil)
	hashString := fmt.Sprintf("%x", hashBytes)

	return hashString, nil
}