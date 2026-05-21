import urllib.request
import json

url_base = 'https://kenhzjqhtronfnnppsei.supabase.co'
anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtlbmh6anFodHJvbmZubnBwc2VpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1ODMwMDEsImV4cCI6MjA5MzE1OTAwMX0.__Qgwo1xnU1SPKl3Gi09_AWt_JVLyDepcW0CEYF8DXE'

# 1. Sign up/in a user
signup_url = f"{url_base}/auth/v1/signup"
signup_data = json.dumps({
    "email": "test_agent_999@example.com",
    "password": "Password123!",
    "data": {
        "username": "agent_tester"
    }
}).encode('utf-8')

headers = {
    'apikey': anon_key,
    'Content-Type': 'application/json'
}

print("Attempting to sign up/in test user...")
req = urllib.request.Request(signup_url, data=signup_data, headers=headers)
access_token = None
user_id = None

try:
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode('utf-8'))
        access_token = res.get('access_token')
        user_id = res.get('user', {}).get('id')
        print(f"User signed up successfully. User ID: {user_id}")
except Exception as e:
    # If already signed up, try to sign in
    print(f"Signup failed/already exists: {e}. Trying sign in...")
    signin_url = f"{url_base}/auth/v1/token?grant_type=password"
    signin_data = json.dumps({
        "email": "test_agent_999@example.com",
        "password": "Password123!"
    }).encode('utf-8')
    req = urllib.request.Request(signin_url, data=signin_data, headers=headers)
    try:
        with urllib.request.urlopen(req) as response:
            res = json.loads(response.read().decode('utf-8'))
            access_token = res.get('access_token')
            user_id = res.get('user', {}).get('id')
            print(f"User signed in successfully. User ID: {user_id}")
    except Exception as signInErr:
        print(f"Sign in failed: {signInErr}")

if access_token and user_id:
    # 2. Query tables with access token
    auth_headers = {
        'apikey': anon_key,
        'Authorization': f"Bearer {access_token}",
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }

    def select_table(table):
        req = urllib.request.Request(f"{url_base}/rest/v1/{table}?limit=5", headers=auth_headers)
        try:
            with urllib.request.urlopen(req) as response:
                print(f"\nSelect from '{table}' success:")
                print(response.read().decode('utf-8'))
        except Exception as e:
            print(f"\nSelect from '{table}' failed: {e}")

    select_table('profiles')
    select_table('users')

    # 3. Try to insert a dummy chat and message
    # Let's create a chat first
    chat_id = "550e8400-e29b-41d4-a716-446655440000" # dummy uuid
    chat_payload = json.dumps({
        "id": chat_id,
        "participants": [user_id, "00000000-0000-0000-0000-000000000000"],
        "type": "oneToOne",
        "lastMessage": "hello",
    }).encode('utf-8')

    print(f"\nTrying to insert a chat...")
    req_chat = urllib.request.Request(f"{url_base}/rest/v1/chats", data=chat_payload, headers=auth_headers)
    try:
        with urllib.request.urlopen(req_chat) as response:
            print("Chat insert success:")
            print(response.read().decode('utf-8'))
    except Exception as e:
        if hasattr(e, 'read'):
            print(f"Chat insert failed: {e.read().decode('utf-8')}")
        else:
            print(f"Chat insert failed: {e}")

    # Now let's try to insert a message
    msg_payload = json.dumps({
        "chatId": chat_id,
        "senderId": user_id,
        "senderName": "Agent Tester",
        "text": "Hello world from python script!",
        "messageType": "text"
    }).encode('utf-8')

    print(f"\nTrying to insert a message...")
    req_msg = urllib.request.Request(f"{url_base}/rest/v1/messages", data=msg_payload, headers=auth_headers)
    try:
        with urllib.request.urlopen(req_msg) as response:
            print("Message insert success:")
            print(response.read().decode('utf-8'))
    except Exception as e:
        if hasattr(e, 'read'):
            print(f"Message insert failed: {e.read().decode('utf-8')}")
        else:
            print(f"Message insert failed: {e}")
else:
    print("Could not obtain access token.")
