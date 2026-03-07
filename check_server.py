import paramiko

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect('207.180.248.144', 22, 'root', 'H60oKi3hRdSo188')

commands = [
    'uptime',
    'docker ps -a 2>&1',
    'pm2 list 2>&1',
    'ss -tlnp 2>&1',
    'systemctl is-active nginx 2>&1',
    'curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ 2>&1',
]

for cmd in commands:
    print(f"\n=== {cmd.split()[0].upper()} ===")
    stdin, stdout, stderr = c.exec_command(cmd)
    print(stdout.read().decode())

c.close()
