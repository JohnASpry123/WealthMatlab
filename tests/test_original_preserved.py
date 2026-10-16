"""Runtime-independent regression guard for the original research code/data."""
import hashlib
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class OriginalReplication(unittest.TestCase):
    def test_original_files_unchanged(self):
        manifest = json.loads((ROOT / 'tests/original_sha256.json').read_text())
        for name, expected in manifest['sha256'].items():
            with self.subTest(file=name):
                self.assertEqual(hashlib.sha256((ROOT / name).read_bytes()).hexdigest(), expected)

    def test_entry_points_coexist(self):
        self.assertTrue((ROOT / 'Main.m').is_file())
        self.assertTrue((ROOT / 'Main_USStates.m').is_file())
        self.assertTrue((ROOT / '+usstates/logGrowth.m').is_file())

if __name__ == '__main__':
    unittest.main()
