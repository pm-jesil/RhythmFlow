# Usage: JAMENDO_CLIENT_ID=xxxx python3 survey_jamendo_tastes.py (best of 3 calls per tag)
import os
import json, urllib.request, urllib.parse, concurrent.futures as cf
B="https://api.jamendo.com/v3.0/tracks/?client_id="+os.environ["JAMENDO_CLIENT_ID"]+"&format=json&limit=1&fullcount=true&"
def q1(p):
    try:
        with urllib.request.urlopen(B+urllib.parse.urlencode(p),timeout=30) as r:
            h=json.load(r)["headers"]; return int(h.get("results_fullcount") or h["results_count"])
    except Exception: return -1
def q(p): return max(q1(p) for _ in range(3))
tags=["pop","rock","electronic","hiphop","rap","jazz","lounge","classical","relaxation","songwriter","world","metal","soundtrack","folk","traditional","indian","bollywood","devotional","reggae","rnb","soul","funk","blues","country","latin","dance","house","techno","edm","ambient","lofi","chillout","acoustic","piano","instrumental","romantic","love","sad","happy","party","workout","sleep","focus","kids","christmas","punk","indie","trap","dubstep","orchestral","meditation","energetic","epic","cinematic"]
def s(t): return t,q({"tags":t}),q({"fuzzytags":t})
with cf.ThreadPoolExecutor(6) as ex: res=list(ex.map(s,tags))
for t,a,b in sorted(res,key=lambda r:-max(r[1],r[2])): print(f"{t:14} tags={a:7} fuzzy={b:7}")
json.dump(res,open("tastes.json","w"))
