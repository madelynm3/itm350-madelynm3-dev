# Stress Test Patterns

import unittest

def heavy_computation(n):
    return sum(i * i for i in range(n))

class TestStressTestPatterns(unittest.TestCase):
    def test_heavy_computation(self):
        for _ in range(1000):  # Stress test by calling multiple times
            result = heavy_computation(10000)
            self.assertIsInstance(result, int)  # Check result type

if __name__ == '__main__':
    unittest.main()
