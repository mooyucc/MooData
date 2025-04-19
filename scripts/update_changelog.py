#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess
import re
from datetime import datetime
import os

def get_git_log():
    """获取最近的Git提交历史"""
    cmd = ['git', 'log', '--pretty=format:%h|%s|%ad', '--date=short']
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.split('\n')

def parse_commit(commit):
    """解析提交信息"""
    hash, message, date = commit.split('|')
    return {
        'hash': hash,
        'message': message,
        'date': date
    }

def categorize_commit(message):
    """根据提交信息分类"""
    message = message.lower()
    if 'fix' in message or 'bug' in message:
        return '修复'
    elif 'feat' in message or 'add' in message:
        return '新增'
    elif 'optimize' in message or 'improve' in message:
        return '优化'
    return '其他'

def update_changelog():
    """更新CHANGELOG.md文件"""
    commits = get_git_log()
    categorized = {
        '新增': [],
        '优化': [],
        '修复': [],
        '其他': []
    }
    
    for commit in commits:
        if not commit:
            continue
        commit_info = parse_commit(commit)
        category = categorize_commit(commit_info['message'])
        categorized[category].append(f"- {commit_info['message']} ({commit_info['hash']})")
    
    # 读取现有的CHANGELOG.md
    with open('CHANGELOG.md', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 准备新的未发布内容
    today = datetime.now().strftime('%Y-%m-%d')
    new_content = f"## [未发布] ({today})\n\n"
    
    for category, items in categorized.items():
        if items:
            new_content += f"### {category}\n"
            new_content += '\n'.join(items) + '\n\n'
    
    # 更新文件内容
    content = content.replace('## [未发布]', new_content)
    
    with open('CHANGELOG.md', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_changelog()
    print("CHANGELOG.md 已更新！") 