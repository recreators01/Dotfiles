
#!/usr/bin/env python3
import argparse
import enum
import functools
import os
import shlex
import subprocess
import sys
import json
import tldextract

# 打印到 stderr
stderr = functools.partial(print, file=sys.stderr)

# 退出码
class ExitCodes(enum.IntEnum):
    SUCCESS = 0
    FAILURE = 1
    NO_PASS_CANDIDATES = 2

def qute_command(command):
    """向 qutebrowser 发送命令"""
    with open(os.environ['QUTE_FIFO'], 'w') as fifo:
        fifo.write(command + '\n')
        fifo.flush()

def rbw_list_items(domain, encoding):
    """用 rbw 列出匹配域名的条目，并返回 JSON 列表"""
    try:
        # rbw list 输出格式: "<name> (<id>)"
        list_proc = subprocess.run(
            ["rbw", "list", "--fields=name,id"],
            capture_output=True,
            text=True,
            encoding=encoding
        )
        entries = []
        for line in list_proc.stdout.splitlines():
            if domain.lower() in line.lower():
                # 从行中提取 name 和 id
                if "(" in line and line.endswith(")"):
                    name = line[:line.rfind("(")].strip()
                    item_id = line[line.rfind("(")+1:-1]
                    # 获取完整条目信息
                    get_proc = subprocess.run(
                        ["rbw", "get", "--full", item_id],
                        capture_output=True,
                        text=True,
                        encoding=encoding
                    )
                    try:
                        entry = json.loads(get_proc.stdout)
                        entries.append(entry)
                    except json.JSONDecodeError:
                        stderr(f"无法解析条目: {name}")
        return entries
    except FileNotFoundError:
        stderr("未找到 rbw，请先安装并配置")
        return []

def get_totp_code(item_id, encoding):
    """获取 TOTP 代码"""
    proc = subprocess.run(
        ["rbw", "code", item_id],
        capture_output=True,
        text=True,
        encoding=encoding
    )
    return proc.stdout.strip()

def dmenu(items, invocation, encoding):
    """调用 rofi/dmenu 选择条目"""
    command = shlex.split(invocation)
    process = subprocess.run(command, input='\n'.join(items).encode(encoding), stdout=subprocess.PIPE)
    return process.stdout.decode(encoding).strip()

def fake_key_raw(text):
    """模拟输入字符串"""
    for character in text:
        sequence = '" "' if character == ' ' else rf'\{character}'
        qute_command(f'fake-key {sequence}')

def main(args):
    if not args.url:
        stderr("未提供 URL")
        return ExitCodes.FAILURE

    extract_result = tldextract.extract(args.url)

    found = rbw_list_items(extract_result.fqdn, args.io_encoding)

    candidates = []
    if found:
        candidates.extend(found)

    if not candidates:
        stderr(f"没有找到匹配 {args.url} 的条目")
        return ExitCodes.NO_PASS_CANDIDATES

    if len(candidates) == 1:
        selection = candidates.pop()
    else:
        choices = [f"{c['name']} | {c['login']['username']}" for c in candidates]
        choice = dmenu(choices, args.dmenu_invocation, args.io_encoding)
        choice_name, choice_username = [x.strip() for x in choice.split('|')]
        selection = next((c for c in candidates if c['name'] == choice_name and c['login']['username'] == choice_username), None)

    if not selection:
        return ExitCodes.SUCCESS

    username = selection['login']['username']
    password = selection['login']['password']
    totp = selection['login'].get('totp')

    if args.username_only:
        fake_key_raw(username)
    elif args.password_only:
        fake_key_raw(password)
    elif args.totp_only:
        fake_key_raw(get_totp_code(selection['id'], args.io_encoding))
    else:
        fake_key_raw(username)
        qute_command('fake-key <Tab>')
        fake_key_raw(password)

    if args.insert_mode:
        qute_command('mode-enter insert')

    if not args.totp_only and totp and args.totp:
        import pyperclip
        pyperclip.copy(get_totp_code(selection['id'], args.io_encoding))

    return ExitCodes.SUCCESS

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('url', nargs='?', default=os.getenv('QUTE_URL'))
    parser.add_argument('--dmenu-invocation', '-d', default='rofi -dmenu -i -p Bitwarden')
    parser.add_argument('--no-insert-mode', '-n', dest='insert_mode', action='store_false')
    parser.add_argument('--totp', '-t', action='store_true')
    parser.add_argument('--io-encoding', '-i', default='UTF-8')
    parser.add_argument('--merge-candidates', '-m', action='store_true')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--username-only', '-e', action='store_true')
    group.add_argument('--password-only', '-w', action='store_true')
    group.add_argument('--totp-only', '-T', action='store_true')
    args = parser.parse_args()
    sys.exit(main(args))

