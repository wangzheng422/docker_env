#!/usr/bin/env python3
"""
build.py — 将 README.md 及引用的 .md 文件转换为响应式 HTML blog
依赖: pandoc (brew install pandoc)
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# ── 路径配置 ────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT   = SCRIPT_DIR.parent.parent
TEMPLATE    = REPO_ROOT / ".github/templates/template.html"
STYLE_SRC   = REPO_ROOT / ".github/templates/style.css"
OUT         = REPO_ROOT / "_site"

# ── 工具函数 ────────────────────────────────────────────────
def rel_to_root(rel_html: str) -> str:
    """计算从 html 文件到 _site/ 根的相对路径前缀"""
    depth = rel_html.count("/")
    if depth == 0:
        return "./"
    return "../" * depth

def replace_md_links(content: str) -> str:
    """把 markdown 内容里的 .md 相对链接替换为 .html"""
    def replacer(m):
        text  = m.group(1)
        url   = m.group(2)
        frag  = m.group(3) or ""
        if url.startswith("http://") or url.startswith("https://"):
            return m.group(0)
        new_url = re.sub(r"\.md$", ".html", url)
        return f"[{text}]({new_url}{frag})"
    return re.sub(
        r"\[([^\]]*)\]\(([^)]*\.md)(#[^)]*)?\)",
        replacer,
        content,
    )

def ensure_blank_lines(content: str) -> str:
    """确保 ATX 标题和列表块前后有空行，防止 pandoc 把列表/标题当成段落文本"""
    lines = content.split("\n")
    result = []
    for i, line in enumerate(lines):
        is_heading = bool(re.match(r"^#{1,6} ", line))
        # 列表起始：顶层 "- " 或 "* " 或 "1. " 等，前一行不是列表行且不是空行
        prev = result[-1] if result else ""
        prev_is_list = bool(re.match(r"^(\s*[-*+]|\s*\d+\.)\s", prev))
        prev_is_blank = (prev.strip() == "")
        is_list_start = bool(re.match(r"^[-*+] |^\d+\. ", line))

        # 在标题行前插入空行
        if is_heading and result and not prev_is_blank:
            result.append("")

        # 在列表起始行前插入空行（前一行不是空行、不是列表行）
        if is_list_start and result and not prev_is_blank and not prev_is_list:
            result.append("")

        result.append(line)

        # 在标题行后插入空行
        if is_heading:
            if i + 1 < len(lines) and lines[i + 1].strip() != "":
                result.append("")

    return "\n".join(result)

def extract_title(content: str, fallback: str) -> str:
    m = re.search(r"^# (.+)$", content, re.MULTILINE)
    return m.group(1).strip() if m else fallback

def convert_md(rel_md: str, page_type: str = "article"):
    """转换单个 md 文件为 HTML"""
    src = REPO_ROOT / rel_md
    if not src.exists():
        print(f"  [SKIP] 文件不存在: {rel_md}")
        return

    rel_html = "index.html" if page_type == "index" else rel_md.replace(".md", ".html")
    out_file = OUT / rel_html
    out_file.parent.mkdir(parents=True, exist_ok=True)

    root_prefix = rel_to_root(rel_html)
    content     = src.read_text(encoding="utf-8", errors="replace")
    title       = extract_title(content, src.stem)
    modified    = replace_md_links(content)
    modified    = ensure_blank_lines(modified)

    # 写临时 md 文件
    with tempfile.NamedTemporaryFile(mode="w", suffix=".md",
                                     delete=False, encoding="utf-8") as tf:
        tf.write(modified)
        tmp_path = tf.name

    print(f"  [CONV] {rel_md} → {rel_html}")

    cmd = [
        "pandoc",
        "--from", "markdown",
        "--to", "html5",
        "--template", str(TEMPLATE),
        "--standalone",
        "--table-of-contents",
        "--toc-depth=3",
        f"-V", f"title={title}",
        f"-V", f"css-root={root_prefix}",
        f"-V", f"root={root_prefix}",
        f"-V", "lang=zh",
        f"-V", "dir=ltr",
        "--output", str(out_file),
        tmp_path,
    ]
    if page_type != "index":
        cmd += ["-V", "back-link=true"]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip())
    except Exception as e:
        print(f"  [WARN] 带 TOC 失败 ({e})，重试不带 TOC...")
        cmd_notoc = [c for c in cmd
                     if c not in ("--table-of-contents", "--toc-depth=3")
                     and not c.startswith("--toc-depth")]
        result2 = subprocess.run(cmd_notoc, capture_output=True, text=True)
        if result2.returncode != 0:
            print(f"  [ERROR] 转换失败: {rel_md}\n         {result2.stderr.strip()[:200]}")
    finally:
        os.unlink(tmp_path)

def extract_md_links(readme_path: Path) -> list:
    """从 README.md 提取所有本地 .md 链接"""
    content = readme_path.read_text(encoding="utf-8", errors="replace")
    links = re.findall(r"\[(?:[^\]]*)\]\(([^)]*\.md)(?:#[^)]*)?\)", content)
    seen, result = set(), []
    for l in sorted(links):
        if not l.startswith("http") and l not in seen:
            seen.add(l)
            result.append(l)
    return result

# 需要复制的静态资源扩展名
ASSET_EXTS = {
    ".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp",
    ".ico", ".bmp", ".tiff", ".drawio",
    ".pdf", ".mp4", ".mov", ".webm",
    ".zip", ".tar", ".gz",
    ".yaml", ".yml", ".json", ".sh", ".conf",
    ".html",   # standalone HTML pages (e.g. slide viewers)
}

def copy_assets():
    """全量复制仓库内所有静态资源到 _site/，保持原目录结构。
    包括图片、视频、配置文件以及独立 HTML 页面（如幻灯片查看器）。
    跳过 .git / node_modules / _site / .github 等目录。
    """
    skip_dirs = {".git", "node_modules", "_site", ".github", "__pycache__"}
    copied = 0
    for src_file in REPO_ROOT.rglob("*"):
        # 跳过目录本身
        if src_file.is_dir():
            continue
        # 跳过隐藏/特殊目录
        parts = set(src_file.relative_to(REPO_ROOT).parts)
        if parts & skip_dirs:
            continue
        # 只复制资源类文件
        if src_file.suffix.lower() not in ASSET_EXTS:
            continue
        rel = src_file.relative_to(REPO_ROOT)
        dst = OUT / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src_file, dst)
        copied += 1
    print(f"    已复制 {copied} 个静态资源文件")

# ── 主流程 ──────────────────────────────────────────────────
def main():
    print(f">>> 清理并创建输出目录: {OUT}")
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    print(">>> 复制 style.css")
    shutil.copy2(STYLE_SRC, OUT / "style.css")

    print(">>> 构建首页 index.html")
    convert_md("README.md", "index")

    print(">>> 扫描 README.md 中引用的 .md 文件...")
    md_files = extract_md_links(REPO_ROOT / "README.md")
    print(f"    发现 {len(md_files)} 个引用的 .md 文件")

    print(">>> 转换引用的 md 文件...")
    for md in md_files:
        convert_md(md, "article")

    print(">>> 复制静态资源...")
    copy_assets()

    html_count = len(list(OUT.rglob("*.html")))
    print(f"\n✅ 构建完成！共生成 {html_count} 个 HTML 文件")
    print(f"   输出目录: {OUT}")
    print(f"   首页: {OUT}/index.html")

if __name__ == "__main__":
    main()
