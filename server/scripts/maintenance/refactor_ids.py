from pathlib import Path
import re


REPO_ROOT = Path(__file__).resolve().parents[3]
TS_TARGETS = (
    REPO_ROOT / "admin" / "app" / "api",
    REPO_ROOT / "admin" / "lib",
)
PYTHON_TARGETS = (REPO_ROOT / "server" / "app" / "routers",)


def id_prefix_for(path: Path) -> str:
    normalized = str(path).lower()
    if "user" in normalized:
        return "u"
    if "book" in normalized:
        return "b"
    if "fine" in normalized:
        return "f"
    if "loan" in normalized:
        return "l"
    if "reserv" in normalized:
        return "r"
    return "x"


def iter_files(root: Path, suffix: str):
    if not root.exists():
        return
    yield from root.rglob(f"*{suffix}")


def rewrite_typescript_file(path: Path) -> bool:
    content = path.read_text()
    if "crypto.randomUUID()" not in content:
        return False

    prefix = id_prefix_for(path)
    replacement = f"`{prefix}${{Math.floor(100000 + Math.random() * 900000)}}`"
    path.write_text(content.replace("crypto.randomUUID()", replacement))
    return True


def rewrite_python_file(path: Path) -> bool:
    content = path.read_text()
    if "uuid.uuid4()" not in content:
        return False

    prefix = id_prefix_for(path)
    replacement = f"f'{prefix}{{__import__(\"random\").randint(100000, 999999)}}'"
    rewritten = re.sub(r'f"l\{.*?uuid4\(\).*?\}"', replacement, content)
    rewritten = re.sub(r"uuid\.uuid4\(\)\.hex", replacement, rewritten)
    rewritten = re.sub(r"str\(uuid\.uuid4\(\)\)", replacement, rewritten)

    if rewritten == content:
        return False
    path.write_text(rewritten)
    return True


def process_targets(targets, suffix: str, rewrite) -> None:
    for target in targets:
        for path in iter_files(target, suffix) or ():
            if rewrite(path):
                print(f"Updated {path.relative_to(REPO_ROOT)}")


def main() -> None:
    process_targets(TS_TARGETS, ".ts", rewrite_typescript_file)
    process_targets(PYTHON_TARGETS, ".py", rewrite_python_file)
    print("Refactoring done.")


if __name__ == "__main__":
    main()
