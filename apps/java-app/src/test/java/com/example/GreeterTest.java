package com.example;

// No external test framework — uses only AssertionError from the JDK.
// This keeps the build fully hermetic (no rules_jvm_external / local JRE needed).
// Bazel downloads the remote JDK via --java_runtime_version=remotejdk_21.
public class GreeterTest {
    public static void main(String[] args) {
        testGreet();
        testGreetWorld();
        System.out.println("All Java tests passed.");
    }

    static void testGreet() {
        Greeter g = new Greeter("Bazel");
        String result = g.greet();
        assert result.equals("Hello from Java, Bazel!") :
            "Expected 'Hello from Java, Bazel!' but got: " + result;
    }

    static void testGreetWorld() {
        Greeter g = new Greeter("World");
        String result = g.greet();
        assert result.equals("Hello from Java, World!") :
            "Expected 'Hello from Java, World!' but got: " + result;
    }
}
