package scanner

import (
	"fmt"
	"os"
	"path/filepath"
)

// GetFiles returns a list of all files from a path (file or directory)
func GetFiles(path string) ([]string, error) {
	// Check if path exists
	info, err := os.Stat(path)
	if err != nil {
		return nil, fmt.Errorf("path does not exist: %w", err)
	}

	var files []string

	// If it's a single file
	if !info.IsDir() {
		return []string{path}, nil
	}

	// If it's a directory, walk through it
	err = filepath.Walk(path, func(filePath string, fileInfo os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		// Only add files, not directories
		if !fileInfo.IsDir() {
			files = append(files, filePath)
		}
		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("error scanning directory: %w", err)
	}

	return files, nil
}