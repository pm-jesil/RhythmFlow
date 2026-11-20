# Usage: JAMENDO_CLIENT_ID=xxxx python3 survey_jamendo_countries.py  (needs: pip install pycountry)
import os  # best of 3
import json, urllib.request, concurrent.futures as cf, pycountry
B="https://api.jamendo.com/v3.0/artists/locations/?client_id="+os.environ["JAMENDO_CLIENT_ID"]+"&format=json&limit=1&fullcount=true&location_country="
def count_once(c):
    for _ in range(3):
        try:
            with urllib.request.urlopen(B+c.alpha_3, timeout=30) as r:
                h=json.load(r)["headers"]; return c, int(h.get("results_fullcount") or h["results_count"])
        except Exception as e: err=e
    return c, -1
# Jamendo randomly returns empty results, so use the best of 3 calls.
def count(c):
    best=max(count_once(c)[1] for _ in range(3))
    return c, best
with cf.ThreadPoolExecutor(6) as ex: res=list(ex.map(count, pycountry.countries))
res.sort(key=lambda x:-x[1])
out=[{"alpha2":c.alpha_2,"alpha3":c.alpha_3,"name":getattr(c,"common_name",c.name),"artists":n} for c,n in res if n>0]
json.dump(out,open("countries.json","w"),ensure_ascii=False,indent=0)
print(len(out),"countries with artists; failed:",sum(1 for _,n in res if n<0))
print([ (o["name"],o["artists"]) for o in out[:12]], [(o["name"],o["artists"]) for o in out if o["alpha2"] in ("IN","LK","AE","BD","PK","NP")])
