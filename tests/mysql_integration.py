"""Check the additive installer and actual queue schema in a private MariaDB instance.

No production connection or credentials are used. Requires local MariaDB binaries.
"""
from pathlib import Path
import re
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT.parents[1] / '[feather]/feather-inventory'
fixture = Path(tempfile.mkdtemp(prefix='h4nr-craft-sql-'))
log = (fixture / 'setup.log').open('w')
server = None
checks = 0

def check(value, message):
    global checks
    assert value, message
    checks += 1

def query(sql):
    result = subprocess.run(['mariadb', '--no-defaults', '--socket=' + str(fixture / 'mysql.sock'),
        '-uroot', '--batch', '--skip-column-names'], input=sql, text=True, capture_output=True, check=True)
    return result.stdout.strip()

try:
    subprocess.run(['mariadb-install-db', '--no-defaults', '--datadir=' + str(fixture / 'data'),
        '--auth-root-authentication-method=normal', '--skip-test-db'], stdout=log, stderr=log, check=True)
    server = subprocess.Popen(['/usr/sbin/mariadbd', '--no-defaults', '--datadir=' + str(fixture / 'data'),
        '--socket=' + str(fixture / 'mysql.sock'), '--pid-file=' + str(fixture / 'pid'), '--skip-networking',
        '--innodb-buffer-pool-size=32M', '--innodb-use-native-aio=0',
        '--log-error=' + str(fixture / 'mysql.log')], stdout=log, stderr=log)
    for _ in range(150):
        if (fixture / 'mysql.sock').exists():
            try:
                query('SELECT 1;')
                break
            except subprocess.CalledProcessError:
                pass
        if server.poll() is not None:
            raise RuntimeError('MariaDB fixture failed: ' + str(fixture))
        time.sleep(.1)
    else:
        raise RuntimeError('MariaDB fixture timeout: ' + str(fixture))
    query('CREATE DATABASE craft_fixture;')
    bootstrap = (INVENTORY / 'database/fivem_bootstrap.sql').read_text()
    installer = (ROOT / 'install/items.sql').read_text()
    query('USE craft_fixture;\n' + bootstrap)
    original = query('USE craft_fixture; SELECT COUNT(*) FROM items;')
    query('USE craft_fixture; UPDATE items SET display_name="preserved-custom-label" WHERE name="hammer";')
    query('USE craft_fixture;\n' + installer + '\n' + installer)
    check(query('USE craft_fixture; SELECT COUNT(*) FROM items;') == original, 'Installer does not duplicate definitions')
    check(query('USE craft_fixture; SELECT display_name FROM items WHERE name="hammer";') == 'preserved-custom-label',
        'Installer preserves existing definitions')
    available = set(query('USE craft_fixture; SELECT name FROM items;').splitlines())
    for path in sorted((ROOT / 'config').glob('recipes_*.lua')):
        for name in re.findall(r"Item = '([^']+)'", path.read_text()):
            if not name.startswith(('weapon_', 'ammo_')):
                check(name in available, 'Missing crafting item: ' + name)
    for name in re.findall(r"Book = '([^']+)'", (ROOT / 'config/shared.lua').read_text()):
        check(name in available, 'Missing book: ' + name)
    database = (ROOT / 'server/database.lua').read_text()
    schema = re.search(r'CREATE TABLE IF NOT EXISTS h4nr_craft_orders.*?\]\]', database, re.S).group(0)[:-2]
    query('USE craft_fixture; ' + schema + '; ' + schema + ';')
    cid, oid = '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002'
    query(f"USE craft_fixture; INSERT INTO h4nr_craft_orders (id,character_id,request_id,location_id,snapshot,reward_xp) "
        f"VALUES ('{oid}','{cid}','start:1','food','{{}}',20);")
    query(f"USE craft_fixture; UPDATE h4nr_craft_orders SET state='queued', ready_at=1020 WHERE id='{oid}' AND state='preparing';")
    query(f"USE craft_fixture; UPDATE h4nr_craft_orders SET state='queued', ready_at=9999 WHERE id='{oid}' AND state='preparing';")
    check(query('USE craft_fixture; SELECT ready_at FROM h4nr_craft_orders;') == '1020', 'Queue retry cannot reset deadline')
    check(query("USE craft_fixture; SELECT COALESCE(SUM(reward_xp),0) FROM h4nr_craft_orders WHERE state='collected';") == '0',
        'Uncollected orders give no XP')
    query(f"USE craft_fixture; UPDATE h4nr_craft_orders SET state='collected' WHERE id='{oid}' AND state='queued';")
    check(query("USE craft_fixture; SELECT COALESCE(SUM(reward_xp),0) FROM h4nr_craft_orders WHERE state='collected';") == '20',
        'Collected XP is retained exactly once')
    duplicate = subprocess.run(['mariadb','--no-defaults','--socket='+str(fixture/'mysql.sock'),'-uroot'],
        input=f"USE craft_fixture; INSERT INTO h4nr_craft_orders (id,character_id,request_id,location_id,snapshot) "
            f"VALUES (UUID(),'{cid}','start:1','food','{{}}');",text=True,capture_output=True)
    check(duplicate.returncode != 0 and 'Duplicate entry' in duplicate.stderr, 'Duplicate character/request identity refused')
    print(f'MariaDB: {checks} checks passed (isolated database; no FiveM acceptance)')
finally:
    if server:
        server.terminate()
        try:
            server.wait(timeout=10)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait()
    log.close()
