import urllib.request, json, sys

url = 'https://scholarflow-i4bq.onrender.com/agents/summary'
body = json.dumps({
    "abstracts": [],
    "desired_output_type": "General Summary",
    "user_prompt": "hi",
}).encode('utf-8')

req = urllib.request.Request(url, data=body, headers={'Content-Type': 'application/json'}, method='POST')
try:
    resp = urllib.request.urlopen(req, timeout=120)
    print('STATUS:', resp.status)
    print('BODY:', resp.read().decode())
except urllib.error.HTTPError as e:
    print('STATUS:', e.code)
    print('BODY:', e.read().decode())