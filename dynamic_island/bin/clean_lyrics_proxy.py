import http.server
import urllib.request
import urllib.parse
import re
import requests
import sys
import os
import json
import subprocess
import tempfile
import threading
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
        "beats", "station", "vevo"
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

# ---------------------------------------------------------------------------
# YouTube Caption Fallback
# ---------------------------------------------------------------------------
# In-memory cache: key = (track_name, artist_name), value = list of
# {start_ms: int, end_ms: int, text: str} sorted by start_ms.
_yt_caption_cache = {}
_yt_caption_cache_lock = threading.Lock()
# Tracks currently being fetched so we don't launch duplicate yt-dlp processes
_yt_caption_fetching = set()

YT_DLP_PATH = "/usr/bin/yt-dlp"


def _parse_json3_events(json3_data):
    """Convert yt-dlp json3 subtitle data into sorted caption events.

    Handles two formats:
    - Simple: each event has segs with a single utf8 string (English closed captions)
    - Word-level: each event has segs with tOffsetMs per word + aAppend continuation
      events (Japanese/Korean/etc. ASR auto-captions)
    """
    events = json3_data.get("events", [])
    captions = []

    # First pass: group word-level events by wWinId window if they use aAppend
    # We collect all non-append events as anchor points and merge appended text
    merged = []  # list of {start_ms, end_ms, text}
    active_wins = {}  # wWinId -> {start_ms, end_ms, text}

    for ev in events:
        segs = ev.get("segs", [])
        if not segs:
            continue
        start_ms = ev.get("tStartMs", 0)
        dur_ms = ev.get("dDurationMs", 2000)
        end_ms = start_ms + dur_ms
        win_id = ev.get("wWinId")
        is_append = ev.get("aAppend", 0) == 1

        # Build text from segs (concatenate utf8, ignore newline-only segs for display)
        text = "".join(s.get("utf8", "") for s in segs)

        if win_id is not None:
            # Word-level caption with window grouping
            if is_append:
                if win_id in active_wins:
                    active_wins[win_id]["end_ms"] = max(active_wins[win_id]["end_ms"], end_ms)
                    active_wins[win_id]["text"] += text
            else:
                # New window: flush any existing window with same ID
                if win_id in active_wins:
                    merged.append(active_wins[win_id])
                active_wins[win_id] = {"start_ms": start_ms, "end_ms": end_ms, "text": text}
        else:
            # Simple event without window grouping
            # Flush any open windows first
            for w in list(active_wins.values()):
                merged.append(w)
            active_wins.clear()
            merged.append({"start_ms": start_ms, "end_ms": end_ms, "text": text})

    # Flush remaining open windows
    for w in active_wins.values():
        merged.append(w)

    # Second pass: clean and filter
    for item in merged:
        text = " ".join(item["text"].splitlines()).strip()
        # Skip pure music/punctuation-only lines
        if not text or re.match(r'^[\[\(\u266a\s\]\)\-_=]+$', text):
            continue
        captions.append({
            "start_ms": item["start_ms"],
            "end_ms": item["end_ms"],
            "text": text
        })

    captions.sort(key=lambda c: c["start_ms"])
    return captions


def _run_yt_dlp_for_subs(search_term, sub_langs, tmpdir, timeout=40):
    """Run yt-dlp to download subtitles. Returns path to first json3 file, or None."""
    # Clear previous run files
    for fname in os.listdir(tmpdir):
        try:
            os.remove(os.path.join(tmpdir, fname))
        except Exception:
            pass
    out_template = os.path.join(tmpdir, "cap")
    cmd = [
        YT_DLP_PATH,
        search_term,
        "--write-auto-subs",
        "--write-subs",
        "--skip-download",
        "--no-playlist",
        "--sub-format", "json3",
        "--sub-langs", sub_langs,
        "-o", out_template,
        "--quiet",
        "--no-warnings",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    log(f"[YT Captions] yt-dlp exit={result.returncode} (langs={sub_langs!r})")
    if result.returncode != 0 and result.stderr:
        log(f"[YT Captions] yt-dlp error output: {result.stderr.strip()}")
    for fname in sorted(os.listdir(tmpdir)):
        if fname.endswith(".json3"):
            fpath = os.path.join(tmpdir, fname)
            log(f"[YT Captions] Found subtitle file: {fname}")
            return fpath
    return None


def _do_fetch_yt_captions(key, track_name, artist_name, track_url=None):
    """Background thread: search YouTube and download captions into the in-memory cache."""
    try:
        query = get_fuzzy_search_query(track_name, artist_name)
        log(f"[YT Captions] Searching YouTube for: {query!r}")

        # Try strategies in order until we get subtitles.
        # Each strategy combines original-language auto-subs (.*-orig) with English (en)
        # so we get Japanese for YOASOBI, Russian for Russian songs, English for English songs —
        # all in one yt-dlp pass across the top search results.
        strategies = [
            (f"ytsearch3:{query} -lyrics", ".*-orig,en.*"), # Best: exclude lyrics compilations, prioritize official MV/audio (perfect sync)
            (f"ytsearch3:{query}, cc", ".*-orig,en.*"),     # Fallback: explicit CC (risks live performance desync, but better than nothing)
            (f"ytsearch5:{query}", "en.*"),                 # wider net, fallback
        ]

        c_url = clean_youtube_url(track_url)
        if c_url:
            log(f"[YT Captions] Exact URL provided: {c_url}")
            strategies = [
                (c_url, ".*-orig,en.*"),
                (c_url, "en.*")
            ]

        json3_data = None
        with tempfile.TemporaryDirectory() as tmpdir:
            for search_term, sub_langs in strategies:
                try:
                    json3_file = _run_yt_dlp_for_subs(search_term, sub_langs, tmpdir, timeout=40)
                except subprocess.TimeoutExpired:
                    log(f"[YT Captions] yt-dlp timed out for strategy (langs={sub_langs!r})")
                    continue
                except Exception as e:
                    log(f"[YT Captions] yt-dlp error for strategy (langs={sub_langs!r}): {e}")
                    continue

                if json3_file:
                    with open(json3_file, "r", encoding="utf-8") as f:
                        json3_data = json.load(f)
                    break
                log(f"[YT Captions] No subtitle found with langs={sub_langs!r}, trying next strategy...")

        if not json3_data:
            log("[YT Captions] No subtitle file found after all strategies.")
            with _yt_caption_cache_lock:
                _yt_caption_cache[key] = []
                _yt_caption_fetching.discard(key)
            return

        captions = _parse_json3_events(json3_data)
        log(f"[YT Captions] Parsed {len(captions)} caption events.")
        with _yt_caption_cache_lock:
            _yt_caption_cache[key] = captions
            _yt_caption_fetching.discard(key)

    except Exception as exc:
        log(f"[YT Captions] Error fetching captions: {exc}")
        with _yt_caption_cache_lock:
            _yt_caption_cache[key] = []
            _yt_caption_fetching.discard(key)


def clean_youtube_url(url):
    if not url or ("youtube.com" not in url and "youtu.be" not in url):
        return ""
    parsed = urllib.parse.urlparse(url)
    if "youtu.be" in parsed.netloc:
        video_id = parsed.path.lstrip('/')
        return f"https://www.youtube.com/watch?v={video_id}"
    elif "youtube.com" in parsed.netloc:
        qs = urllib.parse.parse_qs(parsed.query)
        if 'v' in qs:
            return f"https://www.youtube.com/watch?v={qs['v'][0]}"
    return ""


def _fetch_yt_captions_for_track(track_name, artist_name, track_url=None):
    """Return cached caption list, start background fetch if needed, or None if still fetching."""
    c_url = clean_youtube_url(track_url)
    if c_url:
        key = ("__yturl__", c_url)
    else:
        key = (track_name.lower().strip(), artist_name.lower().strip())
        
    with _yt_caption_cache_lock:
        if key in _yt_caption_cache:
            return _yt_caption_cache[key]
        if key in _yt_caption_fetching:
            return None  # background thread already running — caller should retry
        _yt_caption_fetching.add(key)

    # Start non-blocking fetch so the HTTP response returns 202 immediately
    t = threading.Thread(target=_do_fetch_yt_captions, args=(key, track_name, artist_name, track_url), daemon=True)
    t.start()
    return None  # not ready yet


def _get_caption_at(captions, position_ms):
    """Return the best caption dict for the given position, or None."""
    if not captions:
        return None
    # Find the last event that has already started
    best = None
    for cap in captions:
        if cap["start_ms"] <= position_ms:
            if cap["end_ms"] > position_ms:
                # Currently active
                best = cap
        else:
            break  # sorted, so no need to continue
    # If nothing active, look ahead for the next upcoming line (within 3s)
    if best is None:
        for cap in captions:
            if cap["start_ms"] > position_ms and cap["start_ms"] - position_ms <= 3000:
                best = cap
                break
    return best

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
            import time
            threading.Thread(target=lambda: (time.sleep(0.5), os._exit(0))).start()
            return

        if parsed_url.path == '/ytcaptions':
            self._handle_ytcaptions(parsed_url)
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
                # Do not return 500 here (it crashes lyricsmpris), fall back to fuzzy search
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

    def _handle_ytcaptions(self, parsed_url):
        """GET /ytcaptions?track_name=...&artist_name=...&position_ms=..."""
        query_params = urllib.parse.parse_qs(parsed_url.query)
        track_name = query_params.get('track_name', [''])[0].strip()
        artist_name = query_params.get('artist_name', [''])[0].strip()
        position_ms = int(query_params.get('position_ms', ['0'])[0])
        track_url = query_params.get('url', [''])[0].strip()
        
        c_url = clean_youtube_url(track_url)

        if not c_url and is_junk_track(track_name):
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": "junk track"}).encode())
            return

        log(f"[YT Captions] Request: track={track_name!r} artist={artist_name!r} pos={position_ms}ms url={c_url!r}")

        captions = _fetch_yt_captions_for_track(track_name, artist_name, track_url)

        if captions is None:
            # Still fetching in background — tell client to retry
            self.send_response(202)  # Accepted
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "fetching"}).encode())
            return

        cap = _get_caption_at(captions, position_ms)

        if cap:
            # Compute ms until next caption starts (so QML can schedule next poll)
            idx = captions.index(cap)
            next_start = captions[idx + 1]["start_ms"] if idx + 1 < len(captions) else cap["end_ms"]
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "text": cap["text"],
                "start_ms": cap["start_ms"],
                "end_ms": cap["end_ms"],
                "next_start_ms": next_start,
                "total": len(captions)
            }).encode())
        else:
            # No caption at this position (silence / gap)
            # Find next caption for QML timing
            next_cap = next((c for c in captions if c["start_ms"] > position_ms), None)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "text": "",
                "next_start_ms": next_cap["start_ms"] if next_cap else -1,
                "total": len(captions)
            }).encode())

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = http.server.ThreadingHTTPServer(('127.0.0.1', PORT), ProxyHandler)
    log(f"Proxy server starting on port {PORT}...")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
