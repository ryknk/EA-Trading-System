import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REQUIRED_DOCS = [
    "architecture.md", "strategy.md", "risk-management.md", "ml-design.md",
    "llm-design.md", "aws-infrastructure.md", "security.md", "backtesting.md", "operations.md",
]
REQUIRED_README_SECTIONS = [
    "システム概要", "アーキテクチャ概要", "セットアップ / ローカル開発", "AWSデプロイ",
    "MQL5への配置 / VPS移行", "設定の原則", "バックテスト", "障害時対応", "本番運用前チェックリスト",
]


class DocumentationTests(unittest.TestCase):
    def test_required_documents_exist_are_japanese_and_nonempty(self) -> None:
        for name in REQUIRED_DOCS:
            with self.subTest(name=name):
                text = (ROOT / "docs" / name).read_text(encoding="utf-8")
                self.assertGreater(len(text), 200)
                self.assertRegex(text, r"[ぁ-んァ-ン一-龯]")

    def test_readme_has_required_operational_sections(self) -> None:
        text = (ROOT / "README.md").read_text(encoding="utf-8")
        for section in REQUIRED_README_SECTIONS:
            with self.subTest(section=section):
                self.assertIn(f"## {section}", text)

    def test_mql5_dangerous_capabilities_default_to_disabled(self) -> None:
        source = (ROOT / "mt5" / "Experts" / "CoreEA.mq5").read_text(encoding="utf-8")
        for setting in ("InpEnableTradeMutations", "InpDecisionApiEnabled", "InpTelemetryEnabled"):
            with self.subTest(setting=setting):
                self.assertRegex(source, rf"input bool\s+{setting}=false;")
        self.assertRegex(source, r"input bool\s+InpAuditFileEnabled=true;")

    def test_contracts_are_valid_json(self) -> None:
        contracts = list((ROOT / "contracts").glob("*.json"))
        self.assertGreaterEqual(len(contracts), 5)
        for path in contracts:
            with self.subTest(path=path.name):
                parsed = json.loads(path.read_text(encoding="utf-8"))
                self.assertEqual("https://json-schema.org/draft/2020-12/schema", parsed["$schema"])

    def test_relative_markdown_links_resolve(self) -> None:
        markdown_files = [ROOT / "README.md", *sorted((ROOT / "docs").glob("*.md"))]
        pattern = re.compile(r"\[[^]]+\]\(([^)]+)\)")
        for source in markdown_files:
            for target in pattern.findall(source.read_text(encoding="utf-8")):
                if "://" in target or target.startswith("#") or target.startswith("C:"):
                    continue
                path_text = target.split("#", 1)[0]
                if not path_text:
                    continue
                with self.subTest(source=source.name, target=target):
                    self.assertTrue((source.parent / path_text).resolve().exists())


if __name__ == "__main__":
    unittest.main()
