#!/bin/bash

# 简历编译脚本
# 使用方法: ./build.sh [clean|view]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$PROJECT_DIR/src"
RESOURCE_DIR="$PROJECT_DIR/resource"
RESULT_DIR="$PROJECT_DIR/result"
TEMP_DIR="/tmp/resume-build"

# 文件路径
MAIN_TEX="$SRC_DIR/main.tex"
RESUME_CLS="$SRC_DIR/resume.cls"
OUTPUT_PDF="$RESULT_DIR/resume.pdf"

echo -e "${GREEN}🔨 编译简历中...${NC}"

# 创建必要的目录（清理并重新创建临时目录）
mkdir -p "$RESULT_DIR"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# 清理选项
if [ "$1" = "clean" ]; then
    echo -e "${YELLOW}🧹 清理临时文件...${NC}"
    rm -rf "$TEMP_DIR"
    rm -f "$RESULT_DIR"/*.pdf
    echo -e "${GREEN}✅ 清理完成!${NC}"
    exit 0
fi

# 检查源文件是否存在
if [ ! -f "$MAIN_TEX" ]; then
    echo -e "${RED}❌ 错误: 找不到主文件 $MAIN_TEX${NC}"
    exit 1
fi

if [ ! -f "$RESUME_CLS" ]; then
    echo -e "${RED}❌ 错误: 找不到样式文件 $RESUME_CLS${NC}"
    exit 1
fi

# 复制源文件到临时目录
echo -e "${YELLOW}📋 准备编译环境...${NC}"
cp "$MAIN_TEX" "$TEMP_DIR/"
cp "$RESUME_CLS" "$TEMP_DIR/"

# 如果有资源文件，复制资源文件（避免符号链接导致的递归问题）
if [ -d "$RESOURCE_DIR" ] && [ "$(ls -A "$RESOURCE_DIR" 2>/dev/null)" ]; then
    cp -r "$RESOURCE_DIR" "$TEMP_DIR/"
fi

# 切换到临时目录进行编译
cd "$TEMP_DIR"

# 编译LaTeX (使用xelatex以支持中文)
echo -e "${YELLOW}📝 第一次编译...${NC}"
xelatex -interaction=nonstopmode -output-directory="$TEMP_DIR" main.tex

# 再次编译以确保交叉引用正确
echo -e "${YELLOW}📝 第二次编译...${NC}"
xelatex -interaction=nonstopmode -output-directory="$TEMP_DIR" main.tex

# 移动生成的PDF到结果目录
if [ -f "$TEMP_DIR/main.pdf" ]; then
    mv "$TEMP_DIR/main.pdf" "$OUTPUT_PDF"
    echo -e "${GREEN}✅ 编译成功! PDF已保存到: $OUTPUT_PDF${NC}"
else
    echo -e "${RED}❌ 编译失败: 未生成PDF文件${NC}"
    exit 1
fi

# 查看选项
if [ "$1" = "view" ] || [ "$2" = "view" ]; then
    echo -e "${YELLOW}👀 打开PDF预览...${NC}"
    if command -v open >/dev/null 2>&1; then
        open "$OUTPUT_PDF"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$OUTPUT_PDF"
    else
        echo -e "${YELLOW}⚠️  无法自动打开PDF，请手动查看: $OUTPUT_PDF${NC}"
    fi
fi

echo -e "${GREEN}🎉 简历编译完成!${NC}"