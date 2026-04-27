#!/usr/bin/env python3
"""copilot-deploy: install the work-copilot bundle into a target repo's .github/.

Subcommands:
  install  <target> [--overwrite]   copy bundle into <target>/.github/
  doctor   <target>                 verify installed files match the manifest
  remove   <target>                 remove the installed bundle

Stdlib only. Runs on Python 3.8+, macOS and Windows. Text files (.md, .json,
.yaml, .yml, .txt) are normalized CRLF/CR -> LF before hashing so hashes are
stable across platforms regardless of git autocrlf settings.
"""

import argparse
import hashlib
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

INSTALL_MANIFEST = "install-manifest.json"
BUNDLE_DIR_NAME = "work-copilot"
MIN_PYTHON = (3, 8)


TEXT_SUFFIXES = (".md", ".json", ".yaml", ".yml", ".txt")


def _safe_resolve(target, dest_rel):
    """Resolve dest_rel under target, refusing path-traversal escapes.

    Defense against malicious or corrupted install-manifest.json entries that
    contain segments like '../../etc/passwd'. Uses try/except on
    Path.relative_to() because Path.is_relative_to() is Python 3.9+ and we
    support 3.8+.
    """
    dest_abs = (target / dest_rel).resolve()
    target_abs = target.resolve()
    try:
        dest_abs.relative_to(target_abs)
    except ValueError:
        sys.stderr.write(
            f"ERROR: install-manifest entry escapes target directory: {dest_rel}\n"
            "This indicates a corrupted or malicious manifest. Refusing to proceed.\n"
        )
        sys.exit(2)
    return dest_abs


def sha256_file(path):
    h = hashlib.sha256()
    is_text = str(path).endswith(TEXT_SUFFIXES)
    if is_text:
        data = Path(path).read_bytes()
        data = data.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
        h.update(data)
    else:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(65536), b""):
                h.update(chunk)
    return h.hexdigest()


def map_dest(bundle_rel):
    """Map a path relative to work-copilot/ to its dest relative to target repo root.

    - prompts/*           -> .github/prompts/*
    - instructions/X      -> .github/X                    (X = copilot-instructions.md)
    - everything else     -> .github/work-copilot/<same>
    """
    parts = bundle_rel.parts
    if parts[0] == "prompts":
        return Path(".github") / "prompts" / Path(*parts[1:])
    if parts[0] == "instructions" and bundle_rel.name == "copilot-instructions.md":
        return Path(".github") / "copilot-instructions.md"
    return Path(".github") / BUNDLE_DIR_NAME / bundle_rel


def build_file_map(bundle_dir):
    """Walk bundle_dir and return [(src_abs, dest_rel, bundle_rel)] sorted."""
    items = []
    for p in sorted(bundle_dir.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(bundle_dir)
        if rel.name == INSTALL_MANIFEST:
            continue
        items.append((p, map_dest(rel), rel))
    return items


def find_bundle_dir():
    script_dir = Path(__file__).resolve().parent
    candidate = script_dir.parent / BUNDLE_DIR_NAME
    if candidate.is_dir():
        return candidate
    sys.stderr.write(f"ERROR: could not find bundle at {candidate}\n")
    sys.exit(2)


def cmd_install(args):
    bundle_dir = Path(args.bundle_dir).resolve() if args.bundle_dir else find_bundle_dir()
    target = Path(args.target).resolve()
    if not target.is_dir():
        sys.stderr.write(f"ERROR: target is not a directory: {target}\n")
        sys.exit(2)

    file_map = build_file_map(bundle_dir)
    if not file_map:
        sys.stderr.write(f"ERROR: bundle is empty: {bundle_dir}\n")
        sys.exit(2)

    manifest_path = target / ".github" / BUNDLE_DIR_NAME / INSTALL_MANIFEST
    existing = {}
    if manifest_path.exists():
        try:
            existing = json.loads(manifest_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            pass
    existing_by_dest = {e["dest"]: e for e in existing.get("files", [])}

    installed = updated = skipped = overwritten = 0
    drifted = []
    new_entries = []
    dry = bool(getattr(args, "dry_run", False))

    if dry:
        print(f"copilot-deploy install (DRY RUN, no writes) -> {target}")
    else:
        print(f"copilot-deploy install -> {target}")

    for src, dest_rel, bundle_rel in file_map:
        src_sha = sha256_file(src)
        dest_key = dest_rel.as_posix()
        dest_abs = _safe_resolve(target, dest_rel)

        if dest_abs.exists():
            dest_sha = sha256_file(dest_abs)
            if dest_sha == src_sha:
                action = "SKIP"
            else:
                prior = existing_by_dest.get(dest_key)
                if prior is not None and prior["sha256"] == dest_sha:
                    action = "UPDATE"
                else:
                    action = "OVERWRITE" if args.overwrite else "DRIFT"
        else:
            action = "WRITE"

        if action == "DRIFT":
            print(f"  [DRIFT]     {dest_key}")
            drifted.append(dest_key)
        elif action == "SKIP":
            print(f"  [SKIP]      {dest_key}")
            skipped += 1
        else:
            label = f"  [{action}]".ljust(14) + dest_key
            if dry:
                print(f"{label}  (would write)")
            else:
                dest_abs.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dest_abs)
                print(label)
            if action == "WRITE":
                installed += 1
            elif action == "UPDATE":
                updated += 1
            elif action == "OVERWRITE":
                overwritten += 1

        new_entries.append({
            "src": f"{bundle_dir.name}/{bundle_rel.as_posix()}",
            "dest": dest_key,
            "sha256": src_sha,
        })

    if drifted:
        sys.stderr.write(
            f"\nERROR: {len(drifted)} file(s) have drifted from the installed bundle.\n"
            "Re-run with --overwrite to replace them, or restore the originals.\n"
        )
        sys.exit(1)

    manifest = {
        "version": 1,
        "installed_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "files": new_entries,
    }
    if dry:
        print(f"  [WRITE]     {manifest_path.relative_to(target).as_posix()}  (would write)")
    else:
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        print(f"  [WRITE]     {manifest_path.relative_to(target).as_posix()}")
    summary_label = "SUMMARY (DRY RUN)" if dry else "SUMMARY"
    print(
        f"\n{summary_label}: installed={installed} updated={updated} skipped={skipped} "
        f"overwritten={overwritten} total={len(new_entries)}"
    )


def cmd_doctor(args):
    target = Path(args.target).resolve()
    manifest_path = target / ".github" / BUNDLE_DIR_NAME / INSTALL_MANIFEST
    if not manifest_path.exists():
        sys.stderr.write(f"ERROR: no install-manifest.json at {manifest_path}\n")
        sys.stderr.write("Has the bundle been installed?\n")
        sys.exit(2)

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    print(f"copilot-deploy doctor <- {target}")

    missing = drift = passed = 0
    expected_dests = set()

    for entry in manifest.get("files", []):
        dest = entry["dest"]
        expected_dests.add(dest)
        dest_abs = _safe_resolve(target, dest)
        if not dest_abs.exists():
            print(f"  [MISSING]   {dest}")
            missing += 1
            continue
        if sha256_file(dest_abs) != entry["sha256"]:
            print(f"  [DRIFT]     {dest}")
            drift += 1
        else:
            print(f"  [PASS]      {dest}")
            passed += 1

    orphan = 0
    bundle_root = target / ".github" / BUNDLE_DIR_NAME
    manifest_rel = manifest_path.relative_to(target).as_posix()
    if bundle_root.exists():
        for p in bundle_root.rglob("*"):
            if not p.is_file():
                continue
            rel = p.relative_to(target).as_posix()
            if rel == manifest_rel or rel in expected_dests:
                continue
            print(f"  [ORPHAN]    {rel}")
            orphan += 1

    print(f"\nSUMMARY: passed={passed} missing={missing} drift={drift} orphan={orphan}")
    if missing or drift or orphan:
        sys.exit(1)


def cmd_remove(args):
    target = Path(args.target).resolve()
    manifest_path = target / ".github" / BUNDLE_DIR_NAME / INSTALL_MANIFEST
    if not manifest_path.exists():
        sys.stderr.write(f"ERROR: no install-manifest.json at {manifest_path}\n")
        sys.exit(2)

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    dry = bool(getattr(args, "dry_run", False))
    if dry:
        print(f"copilot-deploy remove (DRY RUN, no deletes) <- {target}")
    else:
        print(f"copilot-deploy remove <- {target}")

    removed = 0
    for entry in manifest.get("files", []):
        dest_abs = _safe_resolve(target, entry["dest"])
        if dest_abs.exists():
            if dry:
                print(f"  [REMOVE]    {entry['dest']}  (would delete)")
            else:
                dest_abs.unlink()
                print(f"  [REMOVE]    {entry['dest']}")
            removed += 1

    if dry:
        print(f"  [REMOVE]    {manifest_path.relative_to(target).as_posix()}  (would delete)")
    else:
        manifest_path.unlink()
        print(f"  [REMOVE]    {manifest_path.relative_to(target).as_posix()}")

    bundle_root = target / ".github" / BUNDLE_DIR_NAME
    if bundle_root.exists() and not dry:
        for p in sorted(bundle_root.rglob("*"), reverse=True):
            if p.is_dir() and not any(p.iterdir()):
                p.rmdir()
        if bundle_root.exists() and not any(bundle_root.iterdir()):
            bundle_root.rmdir()

    summary_label = "SUMMARY (DRY RUN)" if dry else "SUMMARY"
    print(f"\n{summary_label}: removed={removed + 1}")


def main():
    if sys.version_info < MIN_PYTHON:
        sys.stderr.write(
            f"ERROR: copilot-deploy requires Python {MIN_PYTHON[0]}.{MIN_PYTHON[1]}+ "
            f"(found {sys.version_info.major}.{sys.version_info.minor}).\n"
            "Upgrade Python (corporate proxies often allow python.org installers) "
            "or use a newer interpreter.\n"
        )
        sys.exit(2)

    p = argparse.ArgumentParser(
        prog="copilot-deploy",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    pi = sub.add_parser("install", help="copy the bundle into the target's .github/")
    pi.add_argument("target", help="Path to the target repo root")
    pi.add_argument("--overwrite", action="store_true", help="Replace drifted files")
    pi.add_argument("--dry-run", action="store_true", help="Preview without writing")
    pi.add_argument("--bundle-dir", help="Override source bundle location")
    pi.set_defaults(func=cmd_install)

    pd = sub.add_parser("doctor", help="check install health in target repo")
    pd.add_argument("target", help="Path to the target repo root")
    pd.set_defaults(func=cmd_doctor)

    pr = sub.add_parser("remove", help="remove the installed bundle")
    pr.add_argument("target", help="Path to the target repo root")
    pr.add_argument("--dry-run", action="store_true", help="Preview without deleting")
    pr.set_defaults(func=cmd_remove)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
