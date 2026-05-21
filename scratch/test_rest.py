import urllib.request
import json

url_base = 'https://kenhzjqhtronfnnppsei.supabase.co/rest/v1/'
headers = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtlbmh6anFodHJvbmZubnBwc2VpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1ODMwMDEsImV4cCI6MjA5MzE1OTAwMX0.__Qgwo1xnU1SPKl3Gi09_AWt_JVLyDepcW0CEYF8DXE',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtlbmh6anFodHJvbmZubnBwc2VpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1ODMwMDEsImV4cCI6MjA5MzE1OTAwMX0.__Qgwo1xnU1SPKl3Gi09_AWt_JVLyDepcW0CEYF8DXE'
}

def query_table(table):
    req = urllib.request.Request(f"{url_base}{table}?limit=1", headers=headers)
    try:
        with urllib.request.urlopen(req) as response:
            res = response.read().decode('utf-8')
            print(f"Table '{table}' query success:")
            print(res)
    except Exception as e:
        print(f"Table '{table}' query failed: {e}")

print("Querying users table...")
query_table('users')

print("\nQuerying profiles table...")
query_table('profiles')

print("\nQuerying messages table...")
query_table('messages')
