import { greet } from "./greeter";

function assert(condition: boolean, msg: string): void {
  if (!condition) throw new Error(`Assertion failed: ${msg}`);
}

assert(greet("Bazel") === "Hello from TypeScript, Bazel!", "greet Bazel");
assert(greet("World") === "Hello from TypeScript, World!", "greet World");

console.log("All TypeScript tests passed.");
