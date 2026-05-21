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
try:
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode('utf-8'))
        access_token = res.get('access_token')
except Exception as e:
    print(f"Sign in failed: {e}")

if access_token:
    # 2. Get PostgREST schema description
    auth_headers = {
        'apikey': anon_key,
        'Authorization': f"Bearer {access_token}"
    }
    
    req_schema = urllib.request.Request(f"{url_base}/rest/v1/", headers=auth_headers)
    try:
        with urllib.request.urlopen(req_schema) as response:
            schema = json.loads(response.read().decode('utf-8'))
            print("Retrieved schema successfully.")
            
            # Print tables
            definitions = schema.get('definitions', {})
            print("Available tables in definitions:")
            for table in definitions.keys():
                print(f"- {table}")
                
            # Inspect columns for 'profiles'
            profiles_def = definitions.get('profiles', {})
            print("\nColumns in 'profiles' table:")
            properties = profiles_def.get('properties', {})
            for col, col_info in properties.items():
                print(f"  {col}: {col_info.get('type')} ({col_info.get('format', 'no format')})")

            # Inspect columns for 'users'
            users_def = definitions.get('users', {})
            print("\nColumns in 'users' table:")
            properties = users_def.get('properties', {})
            for col, col_info in properties.items():
                print(f"  {col}: {col_info.get('type')} ({col_info.get('format', 'no format')})")
    except Exception as e:
        if hasattr(e, 'read'):
            print(f"Failed to inspect schema: {e.read().decode('utf-8')}")
        else:
            print(f"Failed to inspect schema: {e}")
else:
    print("Could not obtain access token.")
