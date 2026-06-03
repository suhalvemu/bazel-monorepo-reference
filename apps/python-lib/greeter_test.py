import unittest
from greeter import greet

class TestGreet(unittest.TestCase):
    def test_greet(self):
        self.assertEqual(greet("Bazel"), "Hello from Python, Bazel!")

    def test_greet_world(self):
        self.assertEqual(greet("World"), "Hello from Python, World!")

if __name__ == "__main__":
    unittest.main()
