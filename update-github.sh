#!/bin/bash

# MooData GitHub 上传脚本
# 作者: 徐化军
# 用途: 简化GitHub仓库上传流程

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 打印分隔线
print_separator() {
    echo "=================================================="
}

# 检查Git状态
check_git_status() {
    print_message $BLUE "🔍 检查Git状态..."
    
    if ! git status > /dev/null 2>&1; then
        print_message $RED "❌ 错误: 当前目录不是Git仓库"
        exit 1
    fi
    
    print_message $GREEN "✅ Git仓库状态正常"
}

# 显示当前状态
show_status() {
    print_message $YELLOW "📊 当前Git状态:"
    git status --short
    echo ""
}

# 添加所有文件
add_files() {
    print_message $BLUE "📁 添加所有文件到暂存区..."
    
    # 删除.DS_Store文件
    find . -name ".DS_Store" -delete 2>/dev/null
    
    # 添加所有文件
    git add .
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "✅ 文件添加成功"
    else
        print_message $RED "❌ 文件添加失败"
        exit 1
    fi
}

# 获取提交信息
get_commit_message() {
    local default_message="Update: $(date '+%Y-%m-%d %H:%M:%S')"
    
    if [ -z "$1" ]; then
        echo -n "请输入提交信息 (默认: $default_message): "
        read commit_message
        commit_message=${commit_message:-$default_message}
    else
        commit_message="$1"
    fi
    
    echo "$commit_message"
}

# 提交更改
commit_changes() {
    local commit_message=$1
    
    print_message $BLUE "💾 提交更改..."
    print_message $YELLOW "提交信息: $commit_message"
    
    git commit -m "$commit_message"
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "✅ 提交成功"
    else
        print_message $RED "❌ 提交失败"
        exit 1
    fi
}

# 推送到GitHub
push_to_github() {
    print_message $BLUE "🚀 推送到GitHub..."
    
    # 检查远程仓库
    if ! git remote get-url origin > /dev/null 2>&1; then
        print_message $RED "❌ 错误: 未找到远程仓库 'origin'"
        print_message $YELLOW "请先添加远程仓库: git remote add origin <repository-url>"
        exit 1
    fi
    
    # 推送到远程仓库
    git push origin main
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "✅ 推送成功"
    else
        print_message $RED "❌ 推送失败"
        print_message $YELLOW "尝试强制推送..."
        git push origin main --force
        if [ $? -eq 0 ]; then
            print_message $GREEN "✅ 强制推送成功"
        else
            print_message $RED "❌ 强制推送也失败了"
            exit 1
        fi
    fi
}

# 显示帮助信息
show_help() {
    echo "使用方法:"
    echo "  $0 [提交信息]"
    echo ""
    echo "参数:"
    echo "  提交信息    可选的提交信息，如果不提供将提示输入"
    echo ""
    echo "示例:"
    echo "  $0"
    echo "  $0 'feat: 添加新功能'"
    echo "  $0 'fix: 修复bug'"
    echo "  $0 'docs: 更新文档'"
    echo ""
    echo "功能:"
    echo "  - 自动删除.DS_Store文件"
    echo "  - 添加所有更改到暂存区"
    echo "  - 提交更改到本地仓库"
    echo "  - 推送到GitHub远程仓库"
    echo "  - 错误处理和状态检查"
}

# 主函数
main() {
    print_separator
    print_message $GREEN "🐄 MooData GitHub 上传脚本"
    print_separator
    
    # 检查参数
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    # 执行上传流程
    check_git_status
    show_status
    
    # 询问是否继续
    echo -n "是否继续上传? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_message $YELLOW "⏹️ 操作已取消"
        exit 0
    fi
    
    add_files
    
    # 获取提交信息
    commit_message=$(get_commit_message "$1")
    
    commit_changes "$commit_message"
    push_to_github
    
    print_separator
    print_message $GREEN "🎉 上传完成!"
    print_message $BLUE "仓库地址: https://github.com/mooyucc/MooData"
    print_separator
}

# 错误处理
trap 'print_message $RED "\n❌ 脚本执行被中断"; exit 1' INT TERM

# 执行主函数
main "$@" 