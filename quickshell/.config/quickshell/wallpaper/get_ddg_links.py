#!/usr/bin/env python3
import sys, json, time, urllib.request, urllib.parse

LOG_FILE = "/tmp/qs_wall_search.log"
CONTROL_FILE = "/tmp/ddg_search_control"

def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"[WALLHAVEN {time.strftime('%H:%M:%S')}] {msg}\n")
    except:
        pass

def get_state():
    try:
        with open(CONTROL_FILE, "r") as f:
            return f.read().strip()
    except:
        return "run"

def main():
    if len(sys.argv) < 2: 
        log("ERROR: No query provided.")
        return
        
    query = sys.argv[1].strip()
    log(f"Searching Wallhaven for: '{query}'")
    
    # Parametry API Wallhaven:
    # categories: 111 (General/Anime/People)
    # purity: 100 (SFW only)
    # atleast: 1920x1080
    params = {
        "q": query,
        "categories": "111", 
        "purity": "100",
        "atleast": "1920x1080",
        "sorting": "relevance",
        "order": "desc"
    }
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Quickshell Wallpaper Picker)",
        "Accept": "application/json"
    }

    url = "https://wallhaven.cc/api/v1/search?" + urllib.parse.urlencode(params)
    
    try:
        log(f"Requesting: {url}")
        req = urllib.request.Request(url, headers=headers)
        response = urllib.request.urlopen(req, timeout=15)
        data = json.loads(response.read().decode("utf-8"))
        
        results = data.get("data", [])
        log(f"Found {len(results)} high quality results.")
        
        links_found = 0
        for wall in results:
            if get_state() == "stop":
                log("STOP signal. Exiting.")
                break
                
            full_url = wall.get("path")
            # Prioritize 'large' thumbnail for better quality in UI
            thumb_url = wall.get("thumbs", {}).get("large") or wall.get("thumbs", {}).get("original") or wall.get("thumbs", {}).get("small")
            
            if full_url and thumb_url:
                sys.stdout.write(f"{thumb_url}|{full_url}\n")
                sys.stdout.flush()
                links_found += 1
                
        log(f"Search Finished. Results sent to bash: {links_found}")
        
    except Exception as e:
        log(f"Wallhaven API Error: {str(e)}")

if __name__ == "__main__":
    try:
        main()
        sys.stdout.flush()
    except BrokenPipeError:
        pass
    except Exception as e:
        log(f"FATAL ERROR: {str(e)}")
