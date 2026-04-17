#!/usr/bin/env bash
# build.sh — 将 README.md 及引用的 .md 文件转换为响应式 HTML blog
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATE="$REPO_ROOT/.github/templates/template.html"
STYLE_SRC="$REPO_ROOT/.github/templates/style.css"
OUT="$REPO_ROOT/_site"

echo ">>> 清理并创建输出目录: $OUT"
rm -rf "$OUT"
mkdir -p "$OUT"

# ────────────────────────────────────────────
# 工具函数：计算从 html_file 到 _site/ 根的相对路径
# ────────────────────────────────────────────
rel_to_root() {
  local html_file="$1"
  local depth
  depth=$(echo "$html_file" | tr -cd '/' | wc -c | tr -d ' ')
  local prefix=""
  for ((i=0; i<depth; i++)); do
    prefix="../$prefix"
  done
  if [ -z "$prefix" ]; then
    echo "."
  else
    echo "${prefix%/}"
  fi
}

# ────────────────────────────────────────────
# 转换单个 md 文件
# $1 = md 文件路径（相对于 REPO_ROOT）
# $2 = "index" 表示首页，否则为普通文章页
# ────────────────────────────────────────────
convert_md() {
  local rel_md="$1"
  local page_type="${2:-article}"
  local src="$REPO_ROOT/$rel_md"

  if [ ! -f "$src" ]; then
    echo "  [SKIP] 文件不存在: $src"
    return 0
  fi

  # 输出 html 路径
  local rel_html
  if [ "$page_type" = "index" ]; then
    rel_html="index.html"
  else
    rel_html="${rel_md%.md}.html"
  fi

  local out_file="$OUT/$rel_html"
  mkdir -p "$(dirname "$out_file")"

  # 计算 CSS 根路径前缀
  local root_prefix
  root_prefix=$(rel_to_root "$rel_html")
  local css_root
  if [ "$root_prefix" = "." ]; then
    css_root="./"
    root_prefix="./"
  else
    css_root="${root_prefix}/"
    root_prefix="${root_prefix}/"
  fi

  # 提取标题
  local title
  title=$(grep -m1 '^# ' "$src" 2>/dev/null | sed 's/^# //' || true)
  if [ -z "$title" ]; then
    title=$(basename "$rel_md" .md)
  fi

  # 临时文件：替换 .md 链接为 .html
  local tmp_md
  tmp_md=$(mktemp /tmp/build_md_XXXXXX.md)
  python3 -c "
import re, sys
content = open(sys.argv[1]).read()
# Replace .md links but not http links
def replace_md(m):
    text = m.group(1)
    url = m.group(2)
    rest = m.group(3) or ''
    if url.startswith('http://') or url.startswith('https://'):
        return m.group(0)
    return '[' + text + '](' + re.sub(r'\.md(\Z|(?=#))', '.html', url) + rest + ')'
result = re.sub(r'\[([^\]]*)\]\(([^)]*\.md)(#[^)]*)?\)', replace_md, content)
open(sys.argv[2], 'w').write(result)
" "$src" "$tmp_md"

  echo "  [CONV] $rel_md → $rel_html"

  # 构建 pandoc 参数数组
  local pandoc_args=(
    --from markdown
    --to html5
    --template "$TEMPLATE"
    --standalone
    --table-of-contents
    --toc-depth=3
    --highlight-style=github
    -V "title=$title"
    -V "css-root=$css_root"
    -V "root=$root_prefix"
    -V "lang=zh"
    -V "dir=ltr"
    --output "$out_file"
    "$tmp_md"
  )

  if [ "$page_type" != "index" ]; then
    pandoc_args+=(-V "back-link=true")
  fi

  if ! pandoc "${pandoc_args[@]}" 2>/tmp/pandoc_err.txt; then
    echo "  [WARN] with toc failed ($(cat /tmp/pandoc_err.txt | head -1)), retrying without toc..."
    pandoc_args=("${pandoc_args[@]/--table-of-contents/}")
    pandoc_args=("${pandoc_args[@]/--toc-depth=3/}")
    if ! pandoc \
        --from markdown --to html5 \
        --template "$TEMPLATE" --standalone \
        --highlight-style=github \
        -V "title=$title" -V "css-root=$css_root" \
        -V "root=$root_prefix" -V "lang=zh" -V "dir=ltr" \
        --output "$out_file" "$tmp_md" 2>/tmp/pandoc_err2.txt; then
      echo "  [ERROR] 转换失败: $rel_md — $(cat /tmp/pandoc_err2.txt | head -1)"
    fi
  fi

  rm -f "$tmp_md"
  return 0
}

# ────────────────────────────────────────────
# 1. 复制 style.css 到 _site/
# ────────────────────────────────────────────
echo ">>> 复制 style.css"
cp "$STYLE_SRC" "$OUT/style.css"

# ────────────────────────────────────────────
# 2. 首页：README.md → _site/index.html
# ────────────────────────────────────────────
echo ">>> 构建首页 index.html"
convert_md "README.md" "index"

# ────────────────────────────────────────────
# 3. 用 python3 从 README.md 提取所有本地 .md 引用
# ────────────────────────────────────────────
echo ">>> 扫描 README.md 中引用的 .md 文件..."
mapfile -t UNIQUE_MDS < <(python3 -c "
import re, sys
content = open(sys.argv[1]).read()
links = re.findall(r'\[(?:[^\]]*)\]\(([^)]*\.md)(?:#[^)]*)?\)', content)
seen = set()
for l in links:
    if not l.startswith('http') and l not in seen:
        seen.add(l)
        print(l)
" "$REPO_ROOT/README.md" | sort -u)

echo "    发现 ${#UNIQUE_MDS[@]} 个引用的 .md 文件"

# ────────────────────────────────────────────
# 4. 转换所有引用的 .md 文件
# ────────────────────────────────────────────
echo ">>> 转换引用的 md 文件..."
for md in "${UNIQUE_MDS[@]}"; do
  [ -z "$md" ] && continue
  convert_md "$md" "article"
done

# ────────────────────────────────────────────
# 5. 复制静态资源
# ────────────────────────────────────────────
echo ">>> 复制静态资源..."
if [ -d "$REPO_ROOT/imgs" ]; then
  cp -r "$REPO_ROOT/imgs" "$OUT/imgs"
  echo "    已复制: imgs/"
fi
find "$REPO_ROOT/redhat" -type d -name "imgs" 2>/dev/null | while read -r imgdir; do
  rel="${imgdir#$REPO_ROOT/}"
  dest="$OUT/$rel"
  mkdir -p "$dest"
  cp -r "$imgdir"/. "$dest/"
  echo "    已复制: $rel"
done
find "$REPO_ROOT/redhat" -name "*.pdf" 2>/dev/null | while read -r pdf; do
  rel="${pdf#$REPO_ROOT/}"
  dest="$OUT/$(dirname "$rel")"
  mkdir -p "$dest"
  cp "$pdf" "$dest/"
done

# ────────────────────────────────────────────
# 完成统计
# ────────────────────────────────────────────
html_count=$(find "$OUT" -name "*.html" | wc -l | tr -d ' ')
echo ""
echo "✅ 构建完成！共生成 ${html_count} 个 HTML 文件"
echo "   输出目录: $OUT"
echo "   首页: $OUT/index.html"
