# Performance Patterns

import unittest
import time

def slow_function():
    time.sleep(2)  # Simulate a slow function
    return "done"

class TestPerformance(unittest.TestCase):
    def test_performance(self):
        start_time = time.time()
        result = slow_function()
        elapsed_time = time.time() - start_time
        self.assertEqual(result, "done")
        self.assertLess(elapsed_time, 3)  # Ensure it runs in less than 3 seconds

if __name__ == '__main__':
    unittest.main()
