package storage

import (
	"encoding/json"
	"fmt"
	"os"
)

const HashFile = "hashes.json"

// HashStore represents the stored hashes
type HashStore map[string]string

// LoadHashes reads hashes from JSON file
func LoadHashes() (HashStore, error) {
	store := make(HashStore)

	// Check if file exists
	if _, err := os.Stat(HashFile); os.IsNotExist(err) {
		return store, nil // Return empty store
	}

	// Read file
	data, err := os.ReadFile(HashFile)
	if err != nil {
		return nil, fmt.Errorf("error reading hash file: %w", err)
	}

	// Parse JSON
	if err := json.Unmarshal(data, &store); err != nil {
		return nil, fmt.Errorf("error parsing JSON: %w", err)
	}

	return store, nil
}

// SaveHashes writes hashes to JSON file
func SaveHashes(store HashStore) error {
	// Convert to JSON with indentation (pretty print)
	data, err := json.MarshalIndent(store, "", "  ")
	if err != nil {
		return fmt.Errorf("error creating JSON: %w", err)
	}

	// Write to file with proper permissions
	if err := os.WriteFile(HashFile, data, 0644); err != nil {
		return fmt.Errorf("error writing hash file: %w", err)
	}

	return nil
}

// GetHash retrieves a hash for a specific file
func GetHash(filePath string) (string, bool, error) {
	store, err := LoadHashes()
	if err != nil {
		return "", false, err
	}

	hash, exists := store[filePath]
	return hash, exists, nil
}

// SetHash stores a hash for a specific file
func SetHash(filePath, hash string) error {
	store, err := LoadHashes()
	if err != nil {
		return err
	}

	store[filePath] = hash

	return SaveHashes(store)
}