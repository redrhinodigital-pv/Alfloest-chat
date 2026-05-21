import urllib.request
import json

url_base = 'https://kenhzjqhtronfnnppsei.supabase.co'
anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtlbmh6anFodHJvbmZubnBwc2VpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1ODMwMDEsImV4cCI6MjA5MzE1OTAwMX0.__Qgwo1xnU1SPKl3Gi09_AWt_JVLyDepcW0CEYF8DXE'

# 1. Sign in test user
signin_url = f"{url_base}/auth/v1/token?grant_type=password"
signin_data = json.dumps({
    "email": "test_agent_999@example.com",
    "password": "Password123!"
}).encode('utf-8')

headers = {
    'apikey': anon_key,
    'Content-Type': 'application/json'
}

print("Signing in test user...")
req = urllib.request.Request(signin_url, data=signin_data, headers=headers)
access_token = None
user_id = None
try:
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode('utf-8'))
        access_token = res.get('access_token')
        user_id = res.get('user', {}).get('id')
except Exception as e:
    print(f"Sign in failed: {e}")

if access_token and user_id:
    auth_headers = {
        'apikey': anon_key,
        'Authorization': f"Bearer {access_token}",
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }

    # Try updating the profile with all fields from UserModel.toDbMap()
    update_payload = json.dumps({
        'display_name': 'Agent Tester Updated',
        'username': 'agent_tester',
        'email': 'test_agent_999@example.com',
        'phone': '1234567890',
        'avatar_url': 'http://example.com/avatar.png',
        'bio': 'Test bio',
        'is_online': True,
        'last_seen': '2026-05-21T10:00:00Z',
        'dark_mode': True,
        'hide_online': False,
        'hide_last_seen': False,
        'blocked_users': [],
        'fcm_token': 'test_token',
        'updated_at': '2026-05-21T10:00:00Z'
    }).encode('utf-8')

    print(f"\nTrying to update profile for {user_id}...")
    req_update = urllib.request.Request(f"{url_base}/rest/v1/profiles?id=eq.{user_id}", data=update_payload, headers=auth_headers, method='PATCH')
    try:
        with urllib.request.urlopen(req_update) as response:
            print("Profile update success:")
            print(response.read().decode('utf-8'))
    except Exception as e:
        if hasattr(e, 'read'):
            print(f"Profile update failed: {e.read().decode('utf-8')}")
        else:
            print(f"Profile update failed: {e}")
else:
    print("Could not obtain access token.")
