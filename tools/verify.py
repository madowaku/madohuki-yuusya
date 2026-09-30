"""Run project checks and fail on Godot diagnostics, including zero-exit runtime errors."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
parser.add_argument(
    "--certificate-bundle",
    default=os.environ.get("GODOT_CA_BUNDLE"),
    help="optional PEM bundle for restricted Windows hosts that cannot read the system root store",
)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
logs = root / "output" / "verification"
logs.mkdir(parents=True, exist_ok=True)
reports = []
project_file = root / "project.godot"
original_project = None

if args.certificate_bundle:
    bundle = Path(args.certificate_bundle).expanduser().resolve()
    if not bundle.is_file():
        parser.error(f"certificate bundle does not exist: {bundle}")

    original_project = project_file.read_bytes()
    project_text = original_project.decode("utf-8")
    override = f"tls/certificate_bundle_override={json.dumps(bundle.as_posix())}"
    network_header = re.search(r"(?m)^\[network\]\s*$", project_text)
    if network_header:
        next_header = re.search(r"(?m)^\[.+\]\s*$", project_text[network_header.end():])
        section_end = network_header.end() + next_header.start() if next_header else len(project_text)
        section = project_text[network_header.end():section_end]
        key = re.compile(r"(?m)^tls/certificate_bundle_override\s*=.*$")
        if key.search(section):
            section = key.sub(override, section)
        else:
            section = section.rstrip() + "\n" + override + "\n\n"
        project_text = project_text[:network_header.end()] + section + project_text[section_end:]
    else:
        project_text = project_text.rstrip() + "\n\n[network]\n\n" + override + "\n"
    project_file.write_text(project_text, encoding="utf-8")

try:
    for name in ["stage", "art", "run", "route_solver", "ui_runtime", "tower", "tutorial", "ux_controls"]:
        log = logs / f"{name}.log"
        log.write_text("", encoding="utf-8")
        try:
            result = subprocess.run(
                [args.godot, "--headless", "--debug", "--ignore-error-breaks", "--path", root.as_posix(),
                 "--log-file", log.resolve().as_posix(), "--script", f"tests/test_{name}.gd"],
                timeout=60,
                stdin=subprocess.DEVNULL,
            )
            exit_code = result.returncode
        except subprocess.TimeoutExpired:
            exit_code = -1
        output = log.read_text(encoding="utf-8", errors="replace")
        diagnostics = re.findall(r"^(?:SCRIPT ERROR|ERROR|WARNING|Parse Error):.*$", output, re.MULTILINE)
        if exit_code == -1:
            diagnostics.append("TIMEOUT: Godot test exceeded 60 seconds")
        passed = exit_code == 0 and not diagnostics
        summary = [line for line in output.splitlines() if "failures" in line]
        reports.append({"test": name, "passed": passed, "exit": exit_code,
                        "diagnostics": diagnostics, "summary": summary})
        print(f"{'PASS' if passed else 'FAIL'} {name}: {'; '.join(summary)}")
        if not passed:
            print(output)
    solver = subprocess.run([sys.executable, str(root / "tools" / "solve_tower.py")], timeout=60)
    reports.append({"test": "tower_solver", "passed": solver.returncode == 0, "exit": solver.returncode})
    tutorial_solver = subprocess.run([sys.executable, str(root / "tools" / "solve_tutorial.py")], timeout=60)
    reports.append({"test": "tutorial_solver", "passed": tutorial_solver.returncode == 0, "exit": tutorial_solver.returncode})
finally:
    if original_project is not None:
        project_file.write_bytes(original_project)

(logs / "summary.json").write_text(json.dumps(reports, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
raise SystemExit(0 if all(item["passed"] for item in reports) else 1)
