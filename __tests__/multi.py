# Multi-threading Patterns

import unittest
import threading

counter = 0

def increment():
    global counter
    for _ in range(10000):
        counter += 1

class TestMultithreadingPatterns(unittest.TestCase):
    def test_thread_safety(self):
        global counter
        counter = 0
        threads = [threading.Thread(target=increment) for _ in range(2)]
        
        for thread in threads:
            thread.start()
        
        for thread in threads:
            thread.join()
        
        self.assertEqual(counter, 20000)  # Ensure the final count is as expected

if __name__ == '__main__':
    unittest.main()
