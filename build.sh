#!/bin/bash
# 简历编译脚本
# 用法: ./build.sh [clean|view]

set -e

# 彩色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 目录配置
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$PROJECT_DIR/src"
RESOURCE_DIR="$PROJECT_DIR/resource"
RESULT_DIR="$PROJECT_DIR/result"
TEMP_DIR="/tmp/resume-build"

MAIN_TEX="$SRC_DIR/main.tex"
RESUME_CLS="$SRC_DIR/resume.cls"
OUTPUT_PDF="$RESULT_DIR/resume.pdf"

echo -e "${GREEN}🔨 开始编译简历...${NC}"

mkdir -p "$RESULT_DIR"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# 清理
if [ "$1" = "clean" ]; then
  echo -e "${YELLOW}🧹 清理临时文件...${NC}"
  rm -rf "$TEMP_DIR"
  rm -f "$RESULT_DIR"/*.pdf
  echo -e "${GREEN}✅ 清理完成!${NC}"
  exit 0
fi

# 检查文件
[ ! -f "$MAIN_TEX" ] && { echo -e "${RED}❌ 找不到主文件 $MAIN_TEX${NC}"; exit 1; }
[ ! -f "$RESUME_CLS" ] && { echo -e "${RED}❌ 找不到样式文件 $RESUME_CLS${NC}"; exit 1; }

# 准备环境
echo -e "${YELLOW}📋 准备编译环境...${NC}"
cp "$MAIN_TEX" "$TEMP_DIR/"
cp "$RESUME_CLS" "$TEMP_DIR/"
[ -d "$RESOURCE_DIR" ] && cp -r "$RESOURCE_DIR" "$TEMP_DIR/"

cd "$TEMP_DIR"

# 编译函数：隐藏详细输出，只显示关键行
compile_once() {
  xelatex -interaction=nonstopmode -halt-on-error main.tex > compile.log 2>&1
  if grep -q "Fatal error" compile.log; then
    echo -e "${RED}❌ 编译失败，请查看 compile.log${NC}"
    tail -n 10 compile.log
    exit 1
  fi
}

echo -e "${YELLOW}📝 开始编译...${NC}"
compile_once

if grep -q "Rerun to get cross-references right" compile.log; then
  echo -e "${YELLOW}📝 第二次编译(更新引用)...${NC}"
  compile_once
fi

# 输出结果
if [ -f main.pdf ]; then
  mv main.pdf "$OUTPUT_PDF"
  echo -e "${GREEN}✅ 编译成功! PDF已生成: $OUTPUT_PDF${NC}"
else
  echo -e "${RED}❌ 未生成PDF文件${NC}"
  exit 1
fi

# 可选预览
if [[ "$1" == "view" || "$2" == "view" ]]; then
  echo -e "${YELLOW}👀 打开PDF预览...${NC}"
  if command -v open >/dev/null 2>&1; then
    open "$OUTPUT_PDF"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$OUTPUT_PDF"
  fi
fi

echo -e "${GREEN}🎉 完成!${NC}"