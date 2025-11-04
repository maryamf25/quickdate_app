#!/usr/bin/env python3
r"""
Script: clean_friend_requests.py
Purpose: Fetch notifications for a user (using an access token) and attempt
to remove any notifications whose type indicates a friend request. This helps
clean up stale request notifications on the backend so the mobile client won't
see them again.

Usage (Windows cmd):
  set ACCESS_TOKEN=your_token_here
  python scripts\clean_friend_requests.py

Or pass token as argument:
  python scripts\clean_friend_requests.py --token your_token_here

Dependencies:
  pip install requests

Notes:
- This script attempts several candidate delete endpoints (heuristic). If you
  know the exact delete endpoint and param name, set DELETE_ENDPOINT and
  DELETE_PARAM accordingly.
- No destructive changes are made without logging — the script prints each
deletion attempt and final result.
"""

import os
import sys
import argparse
import requests
import json

BASE = 'https://backend.staralign.me/endpoint/v1/models'
GET_NOTIFS_PATH = '/notifications/get_notifications'
# Candidate delete paths (will be tried in order)
CANDIDATE_DELETE_PATHS = [
    '/notifications/delete',
    '/notifications/delete_notification',
    '/notifications/remove_notification',
    '/notifications/remove',
    '/notifications/mark_as_read',
    '/notifications/mark_as_seen',
    '/notifications/seen',
]

HEADERS = {'Content-Type': 'application/x-www-form-urlencoded'}


def fetch_notifications(token, limit=1000, offset=0, user_id=None, verbose=False):
    url = BASE + GET_NOTIFS_PATH
    payload = {'access_token': token, 'limit': str(limit), 'offset': str(offset)}
    if user_id:
        payload['user_id'] = str(user_id)
    try:
        resp = requests.post(url, headers=HEADERS, data=payload, timeout=15)
    except Exception as e:
        if verbose:
            print(f'Error fetching notifications: {e}')
        return []

    if verbose:
        print(f'GET notifications -> HTTP {resp.status_code}\n{resp.text[:1000]}')

    # If non-200, still try to extract JSON (some backends return 200 with HTML)
    body = resp.text
    if '<' in body:
        s = body.find('{')
        e = body.rfind('}')
        if s != -1 and e != -1 and e > s:
            body = body[s:e+1]
    try:
        data = json.loads(body)
    except Exception:
        if verbose:
            print('Failed to parse JSON from response')
        return []

    if (data.get('code') == 200 or data.get('status') == 200) and data.get('data') is not None:
        return list(data.get('data'))
    if verbose:
        print('Response JSON did not contain code/status==200 or data is null:', data)
    return []


def try_delete_notification(token, notif_id):
    for path in CANDIDATE_DELETE_PATHS:
        url = BASE + path
        for param_name in ('id', 'notification_id'):
            try:
                resp = requests.post(url, headers=HEADERS, data={'access_token': token, param_name: notif_id}, timeout=10)
            except Exception as e:
                print(f"Attempt to {url} with param {param_name} failed: {e}")
                continue
            # If 200, attempt to parse JSON to see if backend reports success
            if resp.status_code == 200:
                try:
                    d = resp.json()
                    code = d.get('code') or d.get('status') or 0
                    if int(code) == 200:
                        print(f"Deleted notification {notif_id} via {path} param {param_name} (backend code=200)")
                        return True
                    else:
                        print(f"Tried {path} ({param_name}) returned status JSON code={code} body={d}")
                except Exception:
                    # Non-JSON 200 — treat as success
                    print(f"Deleted notification {notif_id} via {path} param {param_name} (HTTP 200, non-JSON response)")
                    return True
            else:
                # non-200
                print(f"Tried {path} ({param_name}) -> HTTP {resp.status_code}: {resp.text[:200]}")
    return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--token', help='Access token to use (or set ACCESS_TOKEN env var)')
    parser.add_argument('--user-id', help='Optional user id to include in fetch (if supported by API)')
    parser.add_argument('--verbose', action='store_true', help='Show raw HTTP responses for debugging')
    parser.add_argument('--dry', action='store_true', help='Dry run: list candidate notifications without deleting')
    args = parser.parse_args()

    token = args.token or os.getenv('ACCESS_TOKEN')
    if not token:
        print('Error: access token required. Provide --token or set ACCESS_TOKEN environment variable.')
        sys.exit(1)

    print('Fetching notifications...')
    notifs = fetch_notifications(token, user_id=args.user_id, verbose=args.verbose)
    print(f'Fetched {len(notifs)} notifications')

    # Filter friend_request types (case-insensitive contains)
    friend_requests = [n for n in notifs if 'friend_request' in (n.get('type') or '').lower()]
    print(f'Found {len(friend_requests)} friend-request notifications')

    if not friend_requests:
        print('Nothing to remove. Exiting.')
        return

    for n in friend_requests:
        nid = str(n.get('id') or n.get('notification_id') or '')
        text = n.get('text') or ''
        notifier = n.get('notifier') or {}
        uname = notifier.get('username') or notifier.get('full_name') or ''
        print('-' * 60)
        print(f"id={nid} type={n.get('type')} notifier={uname} text={text[:80]}")
        if args.dry:
            continue
        if not nid:
            print('  -> skipping (no id)')
            continue
        ok = try_delete_notification(token, nid)
        print('  -> deleted' if ok else '  -> failed to delete (see logs above)')

    print('\nDone.')


if __name__ == '__main__':
    main()
