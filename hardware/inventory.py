#!/usr/bin/env python3

import argparse
import importlib.util
import json
import os
import platform
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


LABEL_PATTERN = re.compile(r"^[A-Za-z0-9._-]+$")


def run(command: list[str]) -> str | None:
    try:
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    value = result.stdout.strip()
    return value or None


def command_exists(name: str) -> bool:
    return shutil.which(name) is not None


def parse_os_release() -> dict[str, str]:
    values: dict[str, str] = {}
    path = Path("/etc/os-release")
    if not path.is_file():
        return values
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key] = value.strip().strip('"')
    return values


def linux_cpu_model() -> str | None:
    path = Path("/proc/cpuinfo")
    if not path.is_file():
        return None
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.lower().startswith("model name") and ":" in line:
            return line.split(":", 1)[1].strip()
    return platform.processor() or None


def linux_memory_bytes() -> int | None:
    path = Path("/proc/meminfo")
    if not path.is_file():
        return None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("MemTotal:"):
            return int(line.split()[1]) * 1024
    return None


def linux_gpus() -> list[str]:
    output = run(["lspci", "-mm"]) if command_exists("lspci") else None
    if not output:
        return []
    devices = []
    for line in output.splitlines():
        lowered = line.lower()
        if any(kind in lowered for kind in ("vga compatible", "3d controller", "display controller")):
            fields = re.findall(r'"([^"]+)"', line)
            description = " ".join(fields[1:3]) if len(fields) >= 3 else " ".join(fields)
            if description and description not in devices:
                devices.append(description)
    return devices


def mac_gpus() -> list[str]:
    output = run(["system_profiler", "SPDisplaysDataType"])
    if not output:
        return []
    devices = []
    for line in output.splitlines():
        stripped = line.strip()
        if stripped.startswith("Chipset Model:"):
            name = stripped.split(":", 1)[1].strip()
            if name and name not in devices:
                devices.append(name)
    return devices


def integer_command(command: list[str]) -> int | None:
    value = run(command)
    try:
        return int(value) if value is not None else None
    except ValueError:
        return None


def collect(label: str) -> dict:
    system = platform.system()
    if system not in {"Darwin", "Linux"}:
        raise ValueError("version 0.1 supports only Apple Silicon macOS and Ubuntu Linux")

    if system == "Darwin":
        machine = platform.machine()
        if machine != "arm64":
            raise ValueError("version 0.1 supports only Apple Silicon macOS")
        operating_system = {
            "family": "macos",
            "name": "macOS",
            "version": platform.mac_ver()[0],
            "kernel": platform.release(),
            "architecture": machine,
        }
        cpu_model = run(["sysctl", "-n", "machdep.cpu.brand_string"])
        memory_bytes = integer_command(["sysctl", "-n", "hw.memsize"])
        logical_cores = integer_command(["sysctl", "-n", "hw.logicalcpu"])
        gpus = mac_gpus()
    else:
        release = parse_os_release()
        if release.get("ID") != "ubuntu":
            raise ValueError("version 0.1 supports Ubuntu Linux only")
        operating_system = {
            "family": "linux",
            "name": release.get("PRETTY_NAME", "Ubuntu"),
            "version": release.get("VERSION_ID"),
            "kernel": platform.release(),
            "architecture": platform.machine(),
        }
        cpu_model = linux_cpu_model()
        memory_bytes = linux_memory_bytes()
        logical_cores = os.cpu_count()
        gpus = linux_gpus()

    disk = shutil.disk_usage("/")
    return {
        "schema_version": 1,
        "captured_at_utc": datetime.now(timezone.utc).isoformat(),
        "node_label": label,
        "operating_system": operating_system,
        "hardware": {
            "cpu_model": cpu_model,
            "logical_cpu_cores": logical_cores,
            "memory_bytes": memory_bytes,
            "root_storage_free_bytes": disk.free,
            "accelerators": gpus,
        },
        "available_tools": {
            "docker": command_exists("docker"),
            "git": command_exists("git"),
            "llama_bench": command_exists("llama-bench"),
            "llama_server": command_exists("llama-server"),
            "mlx_python_package": importlib.util.find_spec("mlx") is not None,
            "ssh": command_exists("ssh"),
            "tailscale": command_exists("tailscale"),
            "vulkaninfo": command_exists("vulkaninfo"),
        },
        "privacy": {
            "hostname_collected": False,
            "network_addresses_collected": False,
            "serial_numbers_collected": False,
            "usernames_collected": False,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Collect a privacy-safe Household AI hardware inventory as JSON."
    )
    parser.add_argument("--label", required=True, help="An anonymised node label")
    args = parser.parse_args()
    if not LABEL_PATTERN.fullmatch(args.label):
        raise ValueError(
            "label may contain only letters, numbers, dots, underscores, and hyphens"
        )
    print(json.dumps(collect(args.label), indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(2)
