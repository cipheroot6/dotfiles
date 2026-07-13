import http.server
import urllib.request
import urllib.parse
import re
import requests
import sys
import os
import json
from datetime import datetime

PORT = 8765
LOG_FILE = "/home/cipheroot/.config/quickshell/dynamic_island/bin/proxy.log"

def log(msg):
    try:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        line = f"[{timestamp}] {msg}\n"
        with open(LOG_FILE, "a") as f:
            f.write(line)
        print(msg)
    except Exception:
        pass

def clean_brackets_and_parentheses(s):
    if not s:
        return ""
    # Remove anything inside brackets and parentheses EXCEPT if it contains "feat." or "ft."
    feats = re.findall(r'(?i)[（\(\[]\s*(?:feat|ft)\.?\s+[^\]\)]+[）\)\]]', s)
    placeholder = "___FEAT_PLACEHOLDER___"
    s_temp = re.sub(r'(?i)[（\(\[]\s*(?:feat|ft)\.?\s+[^\]\)]+[）\)\]]', placeholder, s)
    s_temp = re.sub(r'\s*[（\(\[].*?[）\)\]]', '', s_temp)
    
    # Restore feats
    for f in feats:
        s_temp = s_temp.replace(placeholder, " " + f.strip("()[]（） "), 1)
    s_temp = s_temp.replace(placeholder, "")
    
    return re.sub(r'\s+', ' ', s_temp).strip()

def clean_junk_suffixes(s):
    # Remove common video/audio/channel suffixes
    junk_patterns = [
        r'(?i)\s*-\s*(rotonmusictv|topic|vevo|official\s+video|official\s+music\s+video|official\s+audio|lyrics|mv|hd|video|audio|lyrics\s+video|official\s+lyrics\s+video)\b.*',
        r'(?i)\s+(official\s+video|official\s+music\s+video|official\s+audio|lyrics|mv|hd|video|audio|lyrics\s+video|official\s+lyrics\s+video)\b.*',
        # Sped up / slowed patterns
        r'(?i)\s*-\s*(slowed\s*\+\s*reverb|slowed\s+and\s+reverb|slowed|sped\s+up|speed\s+up|nightcore)\b.*',
        r'(?i)\s+(slowed\s*\+\s*reverb|slowed\s+and\s+reverb|slowed|sped\s+up|speed\s+up|nightcore)\b.*'
    ]
    for pattern in junk_patterns:
        s = re.sub(pattern, '', s)
    return s.strip()

def is_platform_or_browser(artist):
    if not artist:
        return True
    artist_lower = artist.lower()
    fake_keywords = [
        "youtube.com", "m.youtube.com", "www.youtube.com", "youtube",
        "firefox", "chrome", "chromium", "opera", "safari", "edge",
        "browser", "unknown", "playing media", "sound-juicer", "vlc", "mpv",
        "spotify", "tidal", "deezer", "rhythmbox", "audacious"
    ]
    for kw in fake_keywords:
        if kw in artist_lower:
            return True
    return False

def is_suspected_channel(artist):
    if not artist:
        return True
    artist_lower = artist.lower()
    channel_keywords = [
        "lyrics", "lyric", "music", "vibes", "tv", "records", "channel",
        "playlist", "nation", "promotions", "distribution", "records", "trax",
        "tunes", "sound", "sounds", "central", "club", "dance", "hits", "release",
        "beats", "station"
    ]
    for kw in channel_keywords:
        if kw in artist_lower:
            return True
    return False

def normalize_caps(s):
    # Map Unicode small caps to standard letters
    small_caps = {
        'ᴀ': 'a', 'ʙ': 'b', 'ᴄ': 'c', 'ᴅ': 'd', 'ᴇ': 'e', 'ꜰ': 'f', 'ɢ': 'g',
        'ʜ': 'h', 'ɪ': 'i', 'ᴊ': 'j', 'ᴋ': 'k', 'ʟ': 'l', 'ᴍ': 'm', 'ɴ': 'n',
        'ᴏ': 'o', 'ᴘ': 'p', 'ǫ': 'q', 'ʀ': 'r', 'ꜱ': 's', 'ᴛ': 't', 'ᴜ': 'u',
        'ᴠ': 'v', 'ᴡ': 'w', 'x': 'x', 'ʏ': 'y', 'ᴢ': 'z'
    }
    return "".join(small_caps.get(c, c) for c in s)

def get_primary_artist(artist):
    if not artist:
        return ""
    delimiters = [
        r'\s*,\s*',
        r'\s+&\s+',
        r'\s+feat\.?\s+',
        r'\s+ft\.?\s+',
        r'\bwith\b',
        r'\band\b',
        r'\s+x\s+'
    ]
    pattern = '|'.join(delimiters)
    parts = re.split(pattern, artist, flags=re.IGNORECASE)
    return parts[0].strip() if parts else artist.strip()

def get_fuzzy_search_query(track, artist):
    # Normalize unicode small caps
    track = normalize_caps(track)
    artist = normalize_caps(artist)

    # Split by common playlist/junk delimiters first: ||, |, //, etc.
    for delim in ['||', '|', '//', '\\\\']:
        if delim in track:
            track = track.split(delim)[0].strip()
        if delim in artist:
            artist = artist.split(delim)[0].strip()

    # Clean brackets and parentheses
    track = clean_brackets_and_parentheses(track)
    artist = clean_brackets_and_parentheses(artist)

    # Clean junk suffixes
    track = clean_junk_suffixes(track)
    artist = clean_junk_suffixes(artist)

    # Clean "- Topic" suffix from artist
    if artist:
        artist = re.sub(r'(?i)\s*-\s*topic\b.*', '', artist).strip()

    artist_is_fake = is_platform_or_browser(artist) or is_suspected_channel(artist)
    has_dash = any(dash in track for dash in [" - ", " – ", " — "])

    if has_dash:
        parts = re.split(r'\s+[-\u2013\u2014]\s*|\s*[-\u2013\u2014]\s+', track)
        part0 = parts[0].strip()
        part1 = " - ".join(parts[1:]).strip()

        # If artist is fake, or if the artist is not mentioned in the track title at all,
        # we assume the track title contains both artist and title, so we just use the track parts
        if artist_is_fake or not artist or (artist.lower() not in track.lower()):
            # We use both parts from the track title
            query = f"{part0} {part1}"
        else:
            # Artist is valid and present in track title, search for artist + title
            # (avoid duplicating artist if it's already in part0)
            if artist.lower() in part0.lower() or part0.lower() in artist.lower():
                query = f"{artist} {part1}"
            else:
                query = f"{artist} {track}"
    else:
        # No dash in track
        if artist_is_fake or not artist:
            query = track
        else:
            query = f"{artist} {track}"

    # Remove extra spaces and return
    return re.sub(r'\s+', ' ', query).strip()

def is_junk_track(track):
    if not track:
        return True
    track_lower = track.lower().strip()
    junk_tracks = {
        "youtube", "m.youtube.com", "youtube.com", "- youtube", "new tab", "home", "unknown", "-", ""
    }
    # Check if it matches exactly or is in the set
    if track_lower in junk_tracks:
        return True
    # If the track name is just a dash or symbols
    if re.match(r'^[-\s\u2013\u2014]*$', track_lower):
        return True
    return False

def clean_track_and_artist(track, artist):
    # Normalize unicode small caps
    track = normalize_caps(track)
    artist = normalize_caps(artist)

    # 1. Clean brackets and parentheses first
    track = clean_brackets_and_parentheses(track)
    artist = clean_brackets_and_parentheses(artist)

    # Clean "- Topic" suffix from artist (common on YouTube auto-generated channel uploads)
    if artist:
        artist = re.sub(r'(?i)\s*-\s*topic\b.*', '', artist).strip()

    # 2. Handle cases where artist is missing, "Unknown", or fake (platform/browser), and track contains " - "
    artist_is_fake = is_platform_or_browser(artist) or is_suspected_channel(artist)
    has_dash = any(dash in track for dash in [" - ", " – ", " — "])
    if (not artist or artist.lower() == "unknown" or artist_is_fake) and has_dash:
        parts = re.split(r'\s+[-\u2013\u2014]\s*|\s*[-\u2013\u2014]\s+', track)
        if len(parts) >= 2:
            if len(parts) >= 3 and parts[0].lower() == parts[-1].lower():
                artist = parts[0]
                track = " - ".join(parts[1:-1])
            else:
                artist = parts[0]
                track = " - ".join(parts[1:])
    else:
        # If artist is specified, remove it from track name if it is duplicated inside track name
        if artist and artist.lower() != "unknown":
            parts = re.split(r'\s+[-\u2013\u2014]\s*|\s*[-\u2013\u2014]\s+', track)
            new_parts = []
            for p in parts:
                if p.lower() != artist.lower():
                    new_parts.append(p)
            if new_parts:
                track = " - ".join(new_parts)

    # 3. Clean junk suffixes
    track = clean_junk_suffixes(track)
    artist = clean_junk_suffixes(artist)

    # 4. If artist is still a platform/browser/suspected channel, clear it
    if is_platform_or_browser(artist) or is_suspected_channel(artist):
        artist = ""

    return track.strip(), artist.strip()

DB_PATH = "/home/cipheroot/.cache/quickshell/lyricsmpris/cache.db"

def normalize_and_lower(s):
    if not s:
        return ""
    import unicodedata
    return unicodedata.normalize('NFC', s).lower().strip()

def get_lyrics_from_cache(cleaned_track, cleaned_artist):
    if not os.path.exists(DB_PATH):
        return None
    
    import sqlite3
    import subprocess
    
    try:
        conn = sqlite3.connect(DB_PATH)
        # Register the robust unicode-aware normalize and lower function in SQLite connection
        conn.create_function("norm_lower", 1, normalize_and_lower)
        cursor = conn.cursor()
        
        norm_track = normalize_and_lower(cleaned_track)
        norm_artist = normalize_and_lower(cleaned_artist)
        
        # Exact and fuzzy search in local cache database using unicode-aware norm_lower
        cursor.execute(
            '''SELECT artist, title, album, duration, format, raw_lyrics FROM lyrics 
               WHERE norm_lower(artist) = ? 
                 AND (norm_lower(title) = ? 
                      OR norm_lower(title) LIKE ? 
                      OR ? LIKE '%' || norm_lower(title) || '%')''',
            (norm_artist, norm_track, f"{norm_track}%", norm_track)
        )
        row = cursor.fetchone()
        
        # Fallback to primary artist in local cache database
        if not row:
            primary_artist = get_primary_artist(cleaned_artist)
            if primary_artist and normalize_and_lower(primary_artist) != norm_artist:
                norm_primary = normalize_and_lower(primary_artist)
                cursor.execute(
                    '''SELECT artist, title, album, duration, format, raw_lyrics FROM lyrics 
                       WHERE norm_lower(artist) = ? 
                         AND (norm_lower(title) = ? 
                              OR norm_lower(title) LIKE ? 
                              OR ? LIKE '%' || norm_lower(title) || '%')''',
                    (norm_primary, norm_track, f"{norm_track}%", norm_track)
                )
                row = cursor.fetchone()
                
        conn.close()
        
        if row:
            artist, title, album, duration, fmt, raw_lyrics = row
            # Decompress raw_lyrics using zstd
            process = subprocess.Popen(['zstd', '-d'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate(input=raw_lyrics)
            if process.returncode == 0:
                lyrics_text = stdout.decode('utf-8')
                log(f"[Cache Hit] Found cached lyrics for Title='{title}', Artist='{artist}'")
                res = {
                    "trackName": title,
                    "artistName": artist,
                    "albumName": album,
                    "duration": duration,
                    "syncedLyrics": lyrics_text if "synced" in fmt.lower() or "[" in lyrics_text else "",
                    "plainLyrics": lyrics_text if not ("synced" in fmt.lower() or "[" in lyrics_text) else ""
                }
                return res
            else:
                log(f"zstd decompression failed: {stderr.decode('utf-8')}")
    except Exception as e:
        log(f"Error reading cache DB: {str(e)}")
    return None

class ProxyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_url = urllib.parse.urlparse(self.path)
        if parsed_url.path == '/shutdown':
            log("Shutdown requested via /shutdown. Exiting proxy.")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Shutting down proxy")
            import threading
            import time
            threading.Thread(target=lambda: (time.sleep(0.5), os._exit(0))).start()
            return

        if parsed_url.path != '/dget':
            self.send_error(404, "Not Found")
            return

        query_params = urllib.parse.parse_qs(parsed_url.query)
        
        # Extract parameters
        track_name = query_params.get('track_name', [''])[0]
        artist_name = query_params.get('artist_name', [''])[0]
        album_name = query_params.get('album_name', [''])[0]
        duration = query_params.get('duration', [''])[0]

        cleaned_track, cleaned_artist = clean_track_and_artist(track_name, artist_name)
        cleaned_album = clean_brackets_and_parentheses(album_name)

        log(f"[Request] Raw: Title='{track_name}', Artist='{artist_name}'")
        log(f"[Cleaned] Title='{cleaned_track}', Artist='{cleaned_artist}'")

        if is_junk_track(cleaned_track):
            log(f"Junk track name detected: '{cleaned_track}'. Returning 404 immediately.")
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": "Lyrics not found"}).encode('utf-8'))
            return

        # 0. Check local cache database first to avoid network latency / timeouts
        cached_result = get_lyrics_from_cache(cleaned_track, cleaned_artist)
        if cached_result:
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(cached_result).encode('utf-8'))
            return

        # 1. Try exact LrcLib GET request if we have a valid artist name
        if cleaned_artist:
            target_params = {
                'track_name': cleaned_track,
                'artist_name': cleaned_artist
            }
            if cleaned_album:
                target_params['album_name'] = cleaned_album
            if duration:
                target_params['duration'] = duration

            target_query = urllib.parse.urlencode(target_params)
            target_url = f"https://lrclib.net/api/get?{target_query}"

            try:
                log(f"Fetching exact: {target_url}")
                headers = {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) lyricsmpris-proxy/1.0'
                }
                r = requests.get(target_url, headers=headers, timeout=5)
                if r.status_code == 200:
                    log(f"Exact match found. Status: {r.status_code}")
                    self.send_response(200)
                    for header, val in r.headers.items():
                        if header.lower() not in ['connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade', 'content-encoding', 'transfer-encoding']:
                            self.send_header(header, val)
                    self.end_headers()
                    self.wfile.write(r.content)
                    return
                elif r.status_code == 404:
                    log("Exact match returned 404. Checking for primary artist fallback...")
                    # Try exact match with primary artist if it exists and is different
                    primary_artist = get_primary_artist(cleaned_artist)
                    if primary_artist and primary_artist.lower() != cleaned_artist.lower():
                        target_params['artist_name'] = primary_artist
                        target_query = urllib.parse.urlencode(target_params)
                        target_url = f"https://lrclib.net/api/get?{target_query}"
                        try:
                            log(f"Fetching exact with primary artist: {target_url}")
                            r_primary = requests.get(target_url, headers=headers, timeout=5)
                            if r_primary.status_code == 200:
                                log(f"Exact match with primary artist found. Status: {r_primary.status_code}")
                                self.send_response(200)
                                for header, val in r_primary.headers.items():
                                    if header.lower() not in ['connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade', 'content-encoding', 'transfer-encoding']:
                                        self.send_header(header, val)
                                self.end_headers()
                                self.wfile.write(r_primary.content)
                                return
                            elif r_primary.status_code == 404:
                                log("Exact match with primary artist returned 404. Falling back to fuzzy search...")
                            else:
                                log(f"HTTPError on exact match with primary artist: {r_primary.status_code}")
                        except Exception as e_primary:
                            log(f"Connection error on exact match with primary artist: {str(e_primary)}")
                    else:
                        log("No primary artist fallback available. Falling back to fuzzy search...")
                else:
                    log(f"HTTPError on exact match: {r.status_code}")
                    self.send_response(r.status_code)
                    self.end_headers()
                    self.wfile.write(r.content)
                    return
            except Exception as e:
                log(f"Connection error on exact match: {str(e)}")
                self.send_error(500, str(e))
                return
        else:
            log("No artist name available for exact match. Falling back to fuzzy search...")

        # 2. Fallback to LrcLib Search
        search_query = get_fuzzy_search_query(track_name, artist_name)
        search_url = f"https://lrclib.net/api/search?q={urllib.parse.quote(search_query)}"
        log(f"Fuzzy search query: {search_url}")

        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) lyricsmpris-proxy/1.0'
            }
            r_search = requests.get(search_url, headers=headers, timeout=5)
            if r_search.status_code == 200:
                results = r_search.json()
                if isinstance(results, list) and len(results) > 0:
                    # Find the first result that actually contains lyrics
                    best_match = None
                    for res in results:
                        if res.get('syncedLyrics') or res.get('plainLyrics'):
                            best_match = res
                            break
                    
                    if not best_match:
                        best_match = results[0]

                    log(f"Fuzzy match found: Title='{best_match.get('trackName')}', Artist='{best_match.get('artistName')}'")
                    
                    # Return best match in exact /api/get format
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps(best_match).encode('utf-8'))
                    return
                else:
                    log("Fuzzy search returned no results.")
            else:
                log(f"HTTPError on fuzzy search: {r_search.status_code}")
        except Exception as e:
            log(f"Fuzzy search failed: {str(e)}")

        # If everything fails, return 404
        self.send_response(404)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({"error": "Lyrics not found"}).encode('utf-8'))

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = http.server.HTTPServer(('127.0.0.1', PORT), ProxyHandler)
    log(f"Proxy server starting on port {PORT}...")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
