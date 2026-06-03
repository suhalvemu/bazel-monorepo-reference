package main

import "fmt"

// version is injected at build time via Bazel stamping.
// Build with: bazel build --config=stamp //apps/go-service:go-service
// Without --stamp, this remains empty string.
var version string

func main() {
	if version != "" {
		fmt.Printf("go-service version %s\n", version)
	}
	fmt.Println(Greet("Bazel"))
}

func Greet(name string) string {
	return fmt.Sprintf("Hello from Go, %s!", name)
}
