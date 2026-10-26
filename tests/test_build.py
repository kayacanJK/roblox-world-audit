"""Packaging checks, not a Roblox runtime test suite."""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from build import build, OUTPUT, RULE_IMPORT, SCANNER_IMPORT  # noqa: E402


class BundleTests(unittest.TestCase):
    def test_bundle_is_up_to_date(self):
        self.assertEqual(OUTPUT.read_text(encoding="utf-8"), build())

    def test_bundle_has_no_external_module_imports(self):
        bundle = build()
        self.assertNotIn(RULE_IMPORT, bundle)
        self.assertNotIn(SCANNER_IMPORT, bundle)
        self.assertIn("local Rules = (function()", bundle)
        self.assertIn("local Scanner = (function()", bundle)

    def test_source_contains_all_listed_rules(self):
        rules = (ROOT / "src" / "Rules.lua").read_text(encoding="utf-8")
        for code in (
            "PRECISE_COLLISION", "INVISIBLE_COLLIDER", "LOOSE_ROOT_PART",
            "HIGH_PARTICLE_RATE", "WIDE_SHADOW_LIGHT",
            "MISSING_SOUND_ID", "MISSING_TEXTURE",
        ):
            with self.subTest(code=code):
                self.assertIn(f'"{code}"', rules)

    def test_bundle_has_no_network_access_or_game_edits(self):
        bundle = build()
        forbidden = (
            "HttpService", ":GetAsync(", ":PostAsync(", ":RequestAsync(",
            "entry.instance:Destroy(", "Workspace:Destroy(",
            "ChangeHistoryService", "DataStoreService",
            "InsertService", "MarketplaceService",
        )
        for marker in forbidden:
            with self.subTest(marker=marker):
                self.assertNotIn(marker, bundle)


if __name__ == "__main__":
    unittest.main()
