"""Keep report units and aggregation honest without asserting machine speed."""

import importlib.util
import json
import pathlib
import tempfile
import unittest
from unittest import mock


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

    def test_replay_diagnostics_must_match_across_cache_modes_and_runs(self):
        records = [
            {"scenario": {"id": "palette"}, "cacheMode": mode, "run": run,
             "diagnostics": {"randomDraws": draws, "entries": ["seed", "black", "white"]}}
            for mode, run, draws in [("empty", 1, 10), ("primed", 2, 10)]
        ]
        REPORT.validate_replay(records)
        records[1]["diagnostics"]["randomDraws"] = 11
        with self.assertRaisesRegex(RuntimeError, "Replay diagnostics differ"):
            REPORT.validate_replay(records)

    def test_non_palette_records_need_no_replay_diagnostics(self):
        REPORT.validate_replay([{"scenario": {"id": "hsl"}, "diagnostics": None}])

    def test_mismatch_is_saved_incomplete_and_stops_sampling(self):
        with tempfile.TemporaryDirectory() as scratch:
            package = pathlib.Path(scratch)
            binary = package / "ColorKitBenchmarks"
            binary.write_bytes(b"fixture executable")
            (package / "run.py").write_text("fixture runner")
            (package / "Package.swift").write_text("fixture package")
            output = package / "results"
            requests = []

            def command(*args):
                if "--show-bin-path" in args:
                    return str(package)
                if args[0] == str(binary):
                    if args[1] == "--list":
                        return json.dumps([{"id": "palette", "modes": ["empty", "primed"]}])
                    requests.append(args[2])
                    return json.dumps({"scenario": {"id": "palette"}, "cacheMode": args[2],
                                       "diagnostics": {"randomDraws": len(requests)}, "samples": []})
                if args[-1] == "hw.memsize":
                    return "1"
                return "fixture environment"

            with mock.patch.object(REPORT, "PACKAGE", package), \
                 mock.patch.object(REPORT, "ROOT", package), \
                 mock.patch.object(REPORT, "command", side_effect=command), \
                 mock.patch.object(REPORT.platform, "system", return_value="Darwin"), \
                 mock.patch.object(REPORT.subprocess, "run"), \
                 mock.patch.object(REPORT.sys, "argv", ["run.py", "--output", str(output)]):
                with self.assertRaisesRegex(RuntimeError, "Replay diagnostics differ"):
                    REPORT.main()
            artifact = json.loads((output / "raw.json").read_text())
            self.assertFalse(artifact["complete"])
            self.assertEqual(requests, ["empty", "primed"])
            self.assertEqual(len(artifact["records"]), 2)
            self.assertEqual(artifact["records"][-1]["diagnostics"]["randomDraws"], 2)
