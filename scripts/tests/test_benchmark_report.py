"""Keep report units and aggregation honest without asserting machine speed."""

import importlib.util
import pathlib
import unittest


SPEC = importlib.util.spec_from_file_location(
    "benchmark_report", pathlib.Path(__file__).resolve().parents[2] / "Benchmarks" / "run.py"
)
REPORT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(REPORT)


class BenchmarkReportTests(unittest.TestCase):
    def test_sample_totals_are_normalized_before_combining_runs(self):
        records = [
            {"scenario": {"id": "palette"}, "cacheMode": "empty", "run": 1, "samples": [
                {"requestCount": 10, "requestNanoseconds": 1000, "controlNanoseconds": 100}
            ]},
            {"scenario": {"id": "palette"}, "cacheMode": "empty", "run": 2, "samples": [
                {"requestCount": 20, "requestNanoseconds": 6000, "controlNanoseconds": 600}
            ]},
        ]
        summary = REPORT.summarize(records)
        self.assertIn("| palette | empty | 200.0 | 100.0–300.0 | 20.0 |", summary)
        self.assertIn("not individual-request latency percentiles", summary)

    def test_cache_modes_remain_separate(self):
        records = [
            {"scenario": {"id": "hsl"}, "cacheMode": mode, "samples": [
                {"requestCount": 1, "requestNanoseconds": duration, "controlNanoseconds": 10}
            ]}
            for mode, duration in [("empty", 200), ("primed", 100)]
        ]
        summary = REPORT.summarize(records)
        self.assertIn("| hsl | empty | 200.0 |", summary)
        self.assertIn("| hsl | primed | 100.0 |", summary)
