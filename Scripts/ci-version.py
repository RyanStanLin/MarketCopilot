#!/usr/bin/env python3
"""Derive a repeatable CI version without committing or racing over Git tags."""

import os
from pathlib import Path
import plistlib
import re


project_path = Path(__file__).resolve().parent.parent / "MarketCopilot.xcodeproj/project.pbxproj"
project = plistlib.loads(project_path.read_bytes())
versions = {
    value["buildSettings"]["MARKETING_VERSION"]
    for value in project["objects"].values()
    if value.get("isa") == "XCBuildConfiguration"
    and value.get("name") == "Release"
    and "MARKETING_VERSION" in value.get("buildSettings", {})
}
if len(versions) != 1:
    raise SystemExit("Expected one Release MARKETING_VERSION in the Xcode project.")

base_version = versions.pop()
if not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", base_version):
    raise SystemExit("Release MARKETING_VERSION must be major.minor.patch.")

run_number = os.environ.get("GITHUB_RUN_NUMBER", "")
if not re.fullmatch(r"[1-9][0-9]*", run_number):
    raise SystemExit("GITHUB_RUN_NUMBER must be a positive integer supplied by Actions.")

major, minor, patch = map(int, base_version.split("."))
version = f"{major}.{minor}.{patch + int(run_number)}"
print(f"version={version}")
print(f"tag=v{version}")
print(f"build_number={run_number}")
