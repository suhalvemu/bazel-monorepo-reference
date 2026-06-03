package com.example;

public class Greeter {
    private final String name;

    public Greeter(String name) {
        this.name = name;
    }

    public String greet() {
        return "Hello from Java, " + name + "!";
    }

    public static void main(String[] args) {
        String target = args.length > 0 ? args[0] : "Bazel";
        System.out.println(new Greeter(target).greet());
    }
}
