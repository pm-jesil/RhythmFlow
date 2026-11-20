# Usage: JAMENDO_CLIENT_ID=xxxx python3 survey_jamendo_languages.py  (needs: pip install pycountry)
import os  # best of 3
import json, urllib.request, urllib.parse, concurrent.futures as cf
B="https://api.jamendo.com/v3.0/tracks/?client_id="+os.environ["JAMENDO_CLIENT_ID"]+"&format=json&limit=1&fullcount=true&"
langs={"en":"english","hi":"hindi","ml":"malayalam","ta":"tamil","te":"telugu","kn":"kannada","bn":"bengali","mr":"marathi","pa":"punjabi","gu":"gujarati","ur":"urdu","ne":"nepali","si":"sinhala",
"fr":"french","es":"spanish","it":"italian","de":"german","pt":"portuguese","ru":"russian","uk":"ukrainian","pl":"polish","nl":"dutch","sv":"swedish","no":"norwegian","da":"danish","fi":"finnish",
"el":"greek","tr":"turkish","ar":"arabic","fa":"persian","he":"hebrew","ja":"japanese","ko":"korean","zh":"chinese","id":"indonesian","ms":"malay","th":"thai","vi":"vietnamese","tl":"tagalog",
"cs":"czech","sk":"slovak","hu":"hungarian","ro":"romanian","bg":"bulgarian","sr":"serbian","hr":"croatian","sl":"slovenian","lt":"lithuanian","lv":"latvian","et":"estonian","ca":"catalan","eu":"basque","gl":"galician","ga":"irish","cy":"welsh","sw":"swahili","af":"afrikaans","yo":"yoruba","am":"amharic","la":"latin","eo":"esperanto"}
def q_once(params):
    for _ in range(3):
        try:
            with urllib.request.urlopen(B+urllib.parse.urlencode(params), timeout=30) as r:
                h=json.load(r)["headers"]; return int(h.get("results_fullcount") or h["results_count"])
        except Exception: pass
    return -1
# Jamendo randomly returns empty results, so use the best of 3 calls.
def q(params):
    return max(q_once(params) for _ in range(3))
def survey(item):
    code,name=item
    return code,name,q({"fuzzytags":name}),q({"tags":name}),q({"search":name})
with cf.ThreadPoolExecutor(6) as ex: res=list(ex.map(survey, langs.items()))
res.sort(key=lambda r:-max(r[2],r[3]))
for r in res: print(r)
json.dump([{"code":c,"tag":n,"fuzzytags":a,"tags":b,"search":s} for c,n,a,b,s in res],open("langs.json","w"),indent=0)
