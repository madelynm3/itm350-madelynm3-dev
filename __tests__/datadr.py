# Data Driven Patterns

import unittest

def multiply(a, b):
    return a * b

class TestMathFunctions(unittest.TestCase):
    def test_multiply(self):
        test_cases = [
            (2, 3, 6),
            (0, 5, 0),
            (-1, -1, 1),
            (-1, 1, -1)
        ]
        for a, b, expected in test_cases:
            with self.subTest(a=a, b=b):
                self.assertEqual(multiply(a, b), expected)

if __name__ == '__main__':
    unittest.main()
