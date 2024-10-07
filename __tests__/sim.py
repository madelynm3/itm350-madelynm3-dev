# Simulation Patterns

import unittest
from unittest.mock import patch

def fetch_data():
    # Simulate fetching data from an external API
    return "real data"

def process_data():
    data = fetch_data()
    return f"Processed: {data}"

class TestSimulationPatterns(unittest.TestCase):
    @patch('__main__.fetch_data', return_value="mocked data")
    def test_process_data(self, mock_fetch):
        result = process_data()
        self.assertEqual(result, "Processed: mocked data")

if __name__ == '__main__':
    unittest.main()
