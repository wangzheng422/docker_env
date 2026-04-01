#!/usr/bin/env python3
"""
Guacamole-LDAP Event-Driven Sync Service

Architecture:
  Browser → POST /guacamole/api/tokens (id_token JWT)
         → Nginx routes to this service first
         → Decode JWT, extract preferred_username
         → Sync ONLY that user's LDAP accounts to Guacamole DB
         → Forward request to actual Guacamole
         → Return Guacamole's response to browser

Endpoints:
  POST /api/tokens    - token interceptor (event-driven, per-user sync)
  POST /sync/<user>   - manual single-user sync
  POST /sync          - full sync (all users)
  GET  /health        - health check
"""
import os, re, time, logging, base64, json
import psycopg2, requests
from ldap3 import Server, Connection, ALL, SUBTREE
from flask import Flask, jsonify, request, Response
from datetime import datetime

app = Flask(__name__)
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
log = logging.getLogger(__name__)

LDAP_URL      = os.environ.get('LDAP_URL',      'ldap://openldap:389')
LDAP_BIND_DN  = os.environ.get('LDAP_BIND_DN',  'cn=admin,dc=wzhlab,dc=top')
LDAP_BIND_PW  = os.environ.get('LDAP_BIND_PW',  'LdapAdmin2024!')
LDAP_BASE     = os.environ.get('LDAP_BASE',     'ou=People,dc=wzhlab,dc=top')
PG_HOST       = os.environ.get('PG_HOST',       'postgres')
PG_PORT       = int(os.environ.get('PG_PORT',   '5432'))
PG_DB         = os.environ.get('PG_DB',         'guacamole')
PG_USER       = os.environ.get('PG_USER',       'guacamole')
PG_PASS       = os.environ.get('PG_PASS',       'GuacamoleDB2024!')
RDP_PORT      = os.environ.get('RDP_PORT',      '3389')
RDP_PASS      = os.environ.get('RDP_PASSWORD',  'DemoPass2024!')
GUAC_BACKEND  = os.environ.get('GUAC_BACKEND',  'http://guacamole:8080')


# ── JWT decode ──────────────────────────────────────────────────────────────

def decode_jwt_payload(token):
    """Base64-decode JWT payload to get claims (no signature verification needed)."""
    try:
        parts = token.split('.')
        if len(parts) < 2:
            return {}
        payload = parts[1]
        payload += '=' * (4 - len(payload) % 4)  # add padding
        return json.loads(base64.urlsafe_b64decode(payload))
    except Exception as e:
        log.warning(f"JWT decode error: {e}")
        return {}


# ── LDAP ────────────────────────────────────────────────────────────────────

def parse_desc(desc):
    r = {}
    m = re.search(r'vm=(\S+)', desc)
    if m: r['vm'] = m.group(1)
    m = re.search(r'ad=([\w.,\-]+)', desc)
    if m: r['ad_users'] = [u.strip() for u in m.group(1).split(',')]
    m = re.search(r'label=(.+)$', desc)
    if m: r['label'] = m.group(1).strip()
    return r


def query_ldap_for_user(ad_username):
    """Query OpenLDAP, return accounts where ad= contains this AD username."""
    accounts = []
    try:
        srv = Server(LDAP_URL, get_info=ALL)
        c = Connection(srv, LDAP_BIND_DN, LDAP_BIND_PW, auto_bind=True)
        c.search(LDAP_BASE, '(objectClass=posixAccount)', SUBTREE,
                 attributes=['uid', 'description'])
        for e in c.entries:
            uid = str(e.uid)
            desc = str(e.description) if e.description else ''
            p = parse_desc(desc)
            if 'vm' not in p or 'ad_users' not in p:
                continue
            if ad_username in p['ad_users']:
                accounts.append({
                    'uid': uid, 'vm': p['vm'], 'label': p.get('label', uid)
                })
        c.unbind()
        log.info(f"LDAP: {ad_username} → {len(accounts)} accounts")
    except Exception as e:
        log.error(f"LDAP error: {e}")
    return accounts


def query_ldap_all():
    """Query all LDAP posixAccounts."""
    mappings = []
    try:
        srv = Server(LDAP_URL, get_info=ALL)
        c = Connection(srv, LDAP_BIND_DN, LDAP_BIND_PW, auto_bind=True)
        c.search(LDAP_BASE, '(objectClass=posixAccount)', SUBTREE,
                 attributes=['uid', 'description'])
        for e in c.entries:
            uid = str(e.uid)
            desc = str(e.description) if e.description else ''
            p = parse_desc(desc)
            if 'vm' not in p or 'ad_users' not in p:
                log.warning(f"Skip {uid}: bad description: '{desc}'")
                continue
            mappings.append({'uid': uid, 'vm': p['vm'],
                             'ad_users': p['ad_users'], 'label': p.get('label', uid)})
        c.unbind()
        log.info(f"LDAP: {len(mappings)} accounts total")
    except Exception as e:
        log.error(f"LDAP error: {e}")
    return mappings


# ── Guacamole DB ops ─────────────────────────────────────────────────────────

def get_pg():
    return psycopg2.connect(host=PG_HOST, port=PG_PORT,
                             dbname=PG_DB, user=PG_USER, password=PG_PASS)


def upsert_user(cur, name):
    cur.execute("SELECT entity_id FROM guacamole_entity WHERE name=%s AND type='USER'", (name,))
    r = cur.fetchone()
    if r: return r[0]
    cur.execute("INSERT INTO guacamole_entity(name,type) VALUES(%s,'USER') RETURNING entity_id", (name,))
    eid = cur.fetchone()[0]
    h = bytes.fromhex('CA458A7D494E3BE824F5E1E175A1556C0F8EEF2C2D7DF3633BEC4A29C4411960')
    s = bytes.fromhex('FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264')
    cur.execute("INSERT INTO guacamole_user(entity_id,password_hash,password_salt,password_date)"
                " VALUES(%s,%s,%s,NOW())", (eid, h, s))
    log.info(f"  + user: {name}")
    return eid


def upsert_group(cur, name):
    cur.execute("SELECT connection_group_id FROM guacamole_connection_group WHERE connection_group_name=%s", (name,))
    r = cur.fetchone()
    if r: return r[0]
    cur.execute("INSERT INTO guacamole_connection_group(connection_group_name,type,parent_id)"
                " VALUES(%s,'ORGANIZATIONAL',NULL) RETURNING connection_group_id", (name,))
    gid = cur.fetchone()[0]
    log.info(f"  + group: {name}")
    return gid


def upsert_conn(cur, name, gid, ldap_uid, vm):
    cur.execute("SELECT connection_id FROM guacamole_connection WHERE connection_name=%s AND parent_id=%s",
                (name, gid))
    r = cur.fetchone()
    if r: return r[0]
    cur.execute("INSERT INTO guacamole_connection(connection_name,parent_id,protocol)"
                " VALUES(%s,%s,'rdp') RETURNING connection_id", (name, gid))
    cid = cur.fetchone()[0]
    for pn, pv in [('hostname', vm), ('port', RDP_PORT), ('username', ldap_uid),
                   ('password', RDP_PASS), ('security', 'any'),
                   ('ignore-cert', 'true'), ('color-depth', '24')]:
        cur.execute("INSERT INTO guacamole_connection_parameter(connection_id,parameter_name,parameter_value)"
                    " VALUES(%s,%s,%s)", (cid, pn, pv))
    log.info(f"  + conn: '{name}' -> {vm} ({ldap_uid})")
    return cid


# ── Sync logic ───────────────────────────────────────────────────────────────

def sync_single_user(ad_username):
    """Sync Guacamole connections for ONE AD user only."""
    log.info(f"=== Per-user sync: {ad_username} ===")
    accounts = query_ldap_for_user(ad_username)
    if not accounts:
        log.info(f"  No LDAP accounts found for {ad_username}")
        return {'status': 'ok', 'user': ad_username, 'connections': 0}
    stats = {'connections': 0, 'permissions': 0}
    try:
        pg = get_pg(); cur = pg.cursor()
        eid = upsert_user(cur, ad_username)
        words = ad_username.replace('.', ' ').replace('-', ' ').split()
        gname = ' '.join(w.capitalize() for w in words) + ' Workstations'
        gid = upsert_group(cur, gname)
        cur.execute("INSERT INTO guacamole_connection_group_permission"
                    "(entity_id,connection_group_id,permission)"
                    " VALUES(%s,%s,'READ') ON CONFLICT DO NOTHING", (eid, gid))
        for acct in accounts:
            cname = f"{acct['label']} ({acct['uid']})"
            cid = upsert_conn(cur, cname, gid, acct['uid'], acct['vm'])
            stats['connections'] += 1
            cur.execute("INSERT INTO guacamole_connection_permission"
                        "(entity_id,connection_id,permission)"
                        " VALUES(%s,%s,'READ') ON CONFLICT DO NOTHING", (eid, cid))
            stats['permissions'] += 1
        pg.commit(); cur.close(); pg.close()
        log.info(f"=== Done: {ad_username} → {stats} ===")
        return {'status': 'ok', 'user': ad_username, 'stats': stats}
    except Exception as e:
        log.error(f"DB error: {e}")
        return {'status': 'error', 'user': ad_username, 'message': str(e)}


def sync_all():
    """Sync all users from LDAP."""
    log.info("=== Full sync ===")
    mappings = query_ldap_all()
    if not mappings:
        return {'status': 'error', 'message': 'No LDAP accounts found'}
    user_map = {}
    for m in mappings:
        for u in m['ad_users']:
            user_map.setdefault(u, []).append(
                {'uid': m['uid'], 'vm': m['vm'], 'label': m['label']})
    stats = {'users': 0, 'groups': 0, 'connections': 0, 'permissions': 0}
    try:
        pg = get_pg(); cur = pg.cursor()
        for ad_user, accts in user_map.items():
            log.info(f"Sync: {ad_user} ({len(accts)} accts)")
            eid = upsert_user(cur, ad_user); stats['users'] += 1
            words = ad_user.replace('.', ' ').replace('-', ' ').split()
            gname = ' '.join(w.capitalize() for w in words) + ' Workstations'
            gid = upsert_group(cur, gname); stats['groups'] += 1
            cur.execute("INSERT INTO guacamole_connection_group_permission"
                        "(entity_id,connection_group_id,permission)"
                        " VALUES(%s,%s,'READ') ON CONFLICT DO NOTHING", (eid, gid))
            for acct in accts:
                cname = f"{acct['label']} ({acct['uid']})"
                cid = upsert_conn(cur, cname, gid, acct['uid'], acct['vm'])
                stats['connections'] += 1
                cur.execute("INSERT INTO guacamole_connection_permission"
                            "(entity_id,connection_id,permission)"
                            " VALUES(%s,%s,'READ') ON CONFLICT DO NOTHING", (eid, cid))
                stats['permissions'] += 1
        pg.commit(); cur.close(); pg.close()
        log.info(f"=== Full sync done: {stats} ===")
        return {'status': 'ok', 'stats': stats, 'timestamp': datetime.now().isoformat()}
    except Exception as e:
        log.error(f"DB error: {e}")
        return {'status': 'error', 'message': str(e)}


# ── Routes ───────────────────────────────────────────────────────────────────

@app.route('/api/tokens', methods=['POST'])
def token_interceptor():
    """
    EVENT-DRIVEN webhook: intercepts Guacamole's POST /api/tokens.
    Decodes the id_token JWT, extracts preferred_username,
    syncs ONLY that user's connections, then forwards to real Guacamole.
    """
    body_data = request.get_data()
    content_type = request.headers.get('Content-Type', '')

    # --- Extract id_token from request body ---
    id_token = ''
    if 'application/x-www-form-urlencoded' in content_type:
        from urllib.parse import parse_qs
        parsed = parse_qs(body_data.decode('utf-8', errors='replace'))
        id_token = parsed.get('id_token', [''])[0]
    elif 'application/json' in content_type:
        try:
            id_token = json.loads(body_data).get('id_token', '')
        except Exception:
            pass

    # --- Decode JWT and sync user ---
    if id_token:
        claims = decode_jwt_payload(id_token)
        username = claims.get('preferred_username', '')
        if username:
            log.info(f"[EVENT] Login detected: {username}")
            try:
                sync_single_user(username)
            except Exception as e:
                log.error(f"[EVENT] Sync error for {username}: {e}")
        else:
            log.warning("[EVENT] Could not extract preferred_username from JWT")
    else:
        log.warning("[EVENT] No id_token in POST /api/tokens")

    # --- Forward to real Guacamole ---
    target_url = GUAC_BACKEND + '/guacamole/api/tokens'
    # Build headers (drop hop-by-hop)
    fwd_headers = {k: v for k, v in request.headers.items()
                   if k.lower() not in ('host', 'content-length', 'transfer-encoding')}
    try:
        resp = requests.post(target_url, data=body_data, headers=fwd_headers,
                             timeout=30, allow_redirects=False)
        excluded = {'transfer-encoding', 'connection'}
        response_headers = [(k, v) for k, v in resp.headers.items()
                            if k.lower() not in excluded]
        return Response(resp.content, status=resp.status_code, headers=response_headers)
    except Exception as e:
        log.error(f"[EVENT] Forward error: {e}")
        return jsonify({'error': 'upstream error', 'detail': str(e)}), 502


@app.route('/sync/<username>', methods=['GET', 'POST'])
def sync_user_ep(username):
    """Manual per-user sync endpoint."""
    return jsonify(sync_single_user(username))


@app.route('/sync', methods=['GET', 'POST'])
def sync_all_ep():
    """Manual full sync endpoint."""
    return jsonify(sync_all())


@app.route('/health')
def health():
    return jsonify({'status': 'ok', 'time': datetime.now().isoformat()})


if __name__ == '__main__':
    log.info("Waiting 10s for dependencies...")
    time.sleep(10)
    log.info("guac-ldap-sync ready (event-driven mode)")
    app.run(host='0.0.0.0', port=5000)
