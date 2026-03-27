#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  yt-playlist-mp3.sh — Robust YouTube Playlist → MP3 Downloader
#  Designed for 500+ video playlists with crash-safe resume,
#  automatic retries, rate-limit avoidance, and progress tracking.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Defaults ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR"
ARCHIVE_FILE=""          # set per-playlist later
LOG_FILE=""              # set per-playlist later
FAILED_FILE=""           # set per-playlist later
MAX_RETRIES=5
SLEEP_MIN=3
SLEEP_MAX=8
CONCURRENT_FRAGS=4
RATE_LIMIT="2M"
AUDIO_QUALITY=0
SOCKET_TIMEOUT=30
PLAYLIST_START=""
PLAYLIST_END=""
DRY_RUN=false
STATUS_ONLY=false
RETRY_FAILED=false
PLAYLIST_URL=""

# ─── Functions ────────────────────────────────────────────────────────

print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════╗"
    echo "  ║        🎵  YouTube Playlist → MP3 Downloader  🎵     ║"
    echo "  ║           Robust · Resumable · Rate-Safe             ║"
    echo "  ╚═══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

log() {
    local level="$1"; shift
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    case "$level" in
        INFO)    echo -e "${GREEN}[✓]${RESET} $*" ;;
        WARN)    echo -e "${YELLOW}[⚠]${RESET} $*" ;;
        ERROR)   echo -e "${RED}[✗]${RESET} $*" ;;
        STEP)    echo -e "${BLUE}[→]${RESET} ${BOLD}$*${RESET}" ;;
        DIM)     echo -e "${DIM}    $*${RESET}" ;;
    esac
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $*" >> "$LOG_FILE"
    fi
}

usage() {
    print_banner
    echo -e "${BOLD}USAGE${RESET}"
    echo "  ./yt-playlist-mp3.sh [OPTIONS] <PLAYLIST_URL>"
    echo ""
    echo -e "${BOLD}OPTIONS${RESET}"
    echo "  -o, --output DIR          Output directory (default: script directory)"
    echo "  -r, --range START END     Download only videos START to END"
    echo "  -q, --quality 0-9         Audio quality, 0=best (default: 0)"
    echo "      --rate-limit RATE     Download speed limit (default: 2M)"
    echo "      --concurrent N        Concurrent fragment downloads (default: 4)"
    echo "      --sleep MIN MAX       Sleep interval between videos (default: 3 8)"
    echo "      --retries N           Max retries per failed video (default: 5)"
    echo ""
    echo -e "${BOLD}COMMANDS${RESET}"
    echo "  --dry-run                 List playlist contents without downloading"
    echo "  --status                  Show download progress for a playlist"
    echo "  --retry-failed            Re-attempt only previously failed videos"
    echo "  -h, --help                Show this help message"
    echo ""
    echo -e "${BOLD}EXAMPLES${RESET}"
    echo -e "  ${DIM}# Download entire playlist${RESET}"
    echo "  ./yt-playlist-mp3.sh \"https://youtube.com/playlist?list=PLxxxxx\""
    echo ""
    echo -e "  ${DIM}# Download videos 100-200 only${RESET}"
    echo "  ./yt-playlist-mp3.sh --range 100 200 \"https://youtube.com/playlist?list=PLxxxxx\""
    echo ""
    echo -e "  ${DIM}# Check progress${RESET}"
    echo "  ./yt-playlist-mp3.sh --status \"https://youtube.com/playlist?list=PLxxxxx\""
    echo ""
    echo -e "  ${DIM}# Retry failed downloads${RESET}"
    echo "  ./yt-playlist-mp3.sh --retry-failed \"https://youtube.com/playlist?list=PLxxxxx\""
    echo ""
    echo -e "  ${DIM}# Run in background with tmux${RESET}"
    echo "  tmux new -s downloads './yt-playlist-mp3.sh URL'"
    echo ""
}

check_dependencies() {
    local missing=()

    if ! command -v yt-dlp &>/dev/null; then
        missing+=("yt-dlp")
    fi
    if ! command -v ffmpeg &>/dev/null; then
        missing+=("ffmpeg")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log ERROR "Missing dependencies: ${missing[*]}"
        echo ""
        echo -e "  Install with Homebrew:"
        echo -e "    ${CYAN}brew install ${missing[*]}${RESET}"
        echo ""
        echo -e "  If you don't have Homebrew:"
        echo -e "    ${CYAN}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${RESET}"
        exit 1
    fi

    log INFO "Dependencies OK — yt-dlp $(yt-dlp --version), ffmpeg found"
}

# Derive stable file names from the playlist URL
setup_playlist_paths() {
    local url="$1"
    # Extract playlist ID from the URL
    local playlist_id
    playlist_id=$(echo "$url" | grep -oE 'list=[A-Za-z0-9_-]+' | head -1 | sed 's/list=//')
    if [[ -z "$playlist_id" ]]; then
        playlist_id="unknown_playlist"
    fi

    local base_dir="$OUTPUT_DIR/.yt-mp3-data"
    mkdir -p "$base_dir"

    ARCHIVE_FILE="$base_dir/${playlist_id}_archive.txt"
    LOG_FILE="$base_dir/${playlist_id}_download.log"
    FAILED_FILE="$base_dir/${playlist_id}_failed.txt"
}

# ─── Dry Run ──────────────────────────────────────────────────────────

do_dry_run() {
    log STEP "Fetching playlist info (dry run)..."
    echo ""

    local count
    count=$(yt-dlp --flat-playlist --print "%(playlist_index)s. %(title)s [%(duration_string)s]" \
        "$PLAYLIST_URL" 2>/dev/null | tee /dev/stderr | wc -l | tr -d ' ')

    echo ""
    log INFO "Total videos in playlist: ${BOLD}$count${RESET}"
    echo ""
    echo -e "${DIM}  No files were downloaded. Remove --dry-run to start downloading.${RESET}"
}

# ─── Status ───────────────────────────────────────────────────────────

do_status() {
    setup_playlist_paths "$PLAYLIST_URL"

    echo ""
    if [[ ! -f "$ARCHIVE_FILE" ]]; then
        log WARN "No archive file found. No downloads have been started for this playlist."
        return
    fi

    local downloaded
    downloaded=$(wc -l < "$ARCHIVE_FILE" | tr -d ' ')
    log INFO "Videos downloaded so far: ${BOLD}$downloaded${RESET}"

    if [[ -f "$FAILED_FILE" && -s "$FAILED_FILE" ]]; then
        local failed
        failed=$(wc -l < "$FAILED_FILE" | tr -d ' ')
        log WARN "Failed videos: ${BOLD}$failed${RESET}"
        echo -e "${DIM}  Run with --retry-failed to re-attempt them.${RESET}"
    else
        log INFO "No failed videos recorded."
    fi

    # Try to get total count from playlist
    log DIM "Fetching total playlist size..."
    local total
    total=$(yt-dlp --flat-playlist -J "$PLAYLIST_URL" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('playlist_count', '?'))" 2>/dev/null || echo "?")

    if [[ "$total" != "?" ]]; then
        local remaining=$((total - downloaded))
        echo ""
        echo -e "  ${BOLD}Progress:${RESET} $downloaded / $total  (${remaining} remaining)"
        # Progress bar
        if [[ "$total" -gt 0 ]]; then
            local pct=$((downloaded * 100 / total))
            local filled=$((pct / 2))
            local empty=$((50 - filled))
            printf "  ${GREEN}"
            printf '█%.0s' $(seq 1 "$filled" 2>/dev/null) || true
            printf "${DIM}"
            printf '░%.0s' $(seq 1 "$empty" 2>/dev/null) || true
            printf "${RESET} %d%%\n" "$pct"
        fi
    fi
    echo ""
}

# ─── Retry Failed ────────────────────────────────────────────────────

do_retry_failed() {
    setup_playlist_paths "$PLAYLIST_URL"

    if [[ ! -f "$FAILED_FILE" || ! -s "$FAILED_FILE" ]]; then
        log INFO "No failed videos to retry!"
        return
    fi

    local count
    count=$(wc -l < "$FAILED_FILE" | tr -d ' ')
    log STEP "Retrying $count failed video(s)..."

    # Read failed URLs and retry them one by one
    local success=0
    local still_failed=0
    local temp_failed
    temp_failed=$(mktemp)

    while IFS= read -r url || [[ -n "$url" ]]; do
        [[ -z "$url" ]] && continue
        log DIM "Retrying: $url"

        local attempt=0
        local ok=false
        while [[ $attempt -lt $MAX_RETRIES ]]; do
            attempt=$((attempt + 1))
            if yt-dlp -x --audio-format mp3 --audio-quality "$AUDIO_QUALITY" \
                --socket-timeout "$SOCKET_TIMEOUT" \
                --retries 10 --fragment-retries 10 \
                --concurrent-fragments "$CONCURRENT_FRAGS" \
                --download-archive "$ARCHIVE_FILE" \
                -o "$OUTPUT_DIR/%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s" \
                "$url" >> "$LOG_FILE" 2>&1; then
                ok=true
                break
            fi
            local wait_time=$((attempt * 5))
            log WARN "  Attempt $attempt/$MAX_RETRIES failed. Waiting ${wait_time}s..."
            sleep "$wait_time"
        done

        if $ok; then
            success=$((success + 1))
            log INFO "  ✓ Success"
        else
            still_failed=$((still_failed + 1))
            echo "$url" >> "$temp_failed"
            log ERROR "  ✗ Still failing after $MAX_RETRIES attempts"
        fi
    done < "$FAILED_FILE"

    # Replace failed file with only still-failing videos
    mv "$temp_failed" "$FAILED_FILE"

    echo ""
    log INFO "Retry complete: ${GREEN}$success succeeded${RESET}, ${RED}$still_failed still failed${RESET}"
}

# ─── Main Download ───────────────────────────────────────────────────

do_download() {
    setup_playlist_paths "$PLAYLIST_URL"

    # ── Get playlist info ─────────────────────────────────────────
    log STEP "Fetching playlist metadata..."
    local playlist_json
    playlist_json=$(yt-dlp --flat-playlist -J "$PLAYLIST_URL" 2>/dev/null) || {
        log ERROR "Failed to fetch playlist. Check the URL and your connection."
        exit 1
    }

    local playlist_title
    playlist_title=$(echo "$playlist_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('title', 'Unknown Playlist'))" 2>/dev/null)
    local total_videos
    total_videos=$(echo "$playlist_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('playlist_count', len(d.get('entries',[]))))" 2>/dev/null)

    local already_downloaded=0
    if [[ -f "$ARCHIVE_FILE" ]]; then
        already_downloaded=$(wc -l < "$ARCHIVE_FILE" | tr -d ' ')
    fi

    echo ""
    echo -e "  ${BOLD}Playlist:${RESET}  $playlist_title"
    echo -e "  ${BOLD}Total:${RESET}     $total_videos videos"
    echo -e "  ${BOLD}Already:${RESET}   $already_downloaded downloaded"
    echo -e "  ${BOLD}Output:${RESET}    $OUTPUT_DIR/$playlist_title/"
    echo -e "  ${BOLD}Archive:${RESET}   $ARCHIVE_FILE"
    echo -e "  ${BOLD}Log:${RESET}       $LOG_FILE"
    echo ""

    if [[ "$already_downloaded" -ge "$total_videos" ]] && [[ "$total_videos" -gt 0 ]]; then
        log INFO "All videos already downloaded! Nothing to do."
        return
    fi

    # ── Build yt-dlp command ──────────────────────────────────────
    local cmd=(
        yt-dlp
        -x --audio-format mp3
        --audio-quality "$AUDIO_QUALITY"
        --yes-playlist
        --no-abort-on-error
        --concurrent-fragments "$CONCURRENT_FRAGS"
        --limit-rate "$RATE_LIMIT"
        --sleep-interval "$SLEEP_MIN"
        --max-sleep-interval "$SLEEP_MAX"
        --sleep-requests 1
        --download-archive "$ARCHIVE_FILE"
        --socket-timeout "$SOCKET_TIMEOUT"
        --retries 10
        --fragment-retries 10
        --extractor-retries 5
        --file-access-retries 5
        --no-overwrites
        --embed-thumbnail
        --add-metadata
        --parse-metadata "%(title)s:%(meta_title)s"
        --parse-metadata "%(uploader)s:%(meta_artist)s"
        --progress
        --newline
        --print-to-file "%(webpage_url)s" "$FAILED_FILE.tmp"
        -o "$OUTPUT_DIR/%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s"
    )

    if [[ -n "$PLAYLIST_START" ]]; then
        cmd+=(--playlist-start "$PLAYLIST_START")
    fi
    if [[ -n "$PLAYLIST_END" ]]; then
        cmd+=(--playlist-end "$PLAYLIST_END")
    fi

    cmd+=("$PLAYLIST_URL")

    # ── Run with retry wrapper ────────────────────────────────────
    log STEP "Starting download..."
    echo -e "${DIM}  Press Ctrl+C to pause. Re-run the same command to resume.${RESET}"
    echo ""

    # Clear temp failed file
    > "$FAILED_FILE.tmp"

    local run_attempt=0
    local total_runs_failed=0

    while [[ $run_attempt -lt $MAX_RETRIES ]]; do
        run_attempt=$((run_attempt + 1))

        if [[ $run_attempt -gt 1 ]]; then
            local backoff=$(( (run_attempt - 1) * 15 ))
            log WARN "Run attempt $run_attempt/$MAX_RETRIES — waiting ${backoff}s before retry..."
            sleep "$backoff"
        fi

        # Run yt-dlp — capture exit code without triggering set -e
        local exit_code=0
        "${cmd[@]}" 2>> "$LOG_FILE" || exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            break
        elif [[ $exit_code -eq 101 ]]; then
            # 101 = some videos failed but others succeeded; continue
            log WARN "Some videos had errors. Will collect them for retry."
            break
        else
            total_runs_failed=$((total_runs_failed + 1))
            log WARN "yt-dlp exited with code $exit_code"
        fi
    done

    # ── Collect failed videos ─────────────────────────────────────
    if [[ -f "$FAILED_FILE.tmp" && -s "$FAILED_FILE.tmp" ]]; then
        # Deduplicate and exclude already-archived
        sort -u "$FAILED_FILE.tmp" > "$FAILED_FILE.tmp2"
        if [[ -f "$ARCHIVE_FILE" ]]; then
            # Keep only URLs that are NOT in the archive
            local archived_ids
            archived_ids=$(awk '{print $2}' "$ARCHIVE_FILE" 2>/dev/null || true)
            while IFS= read -r url; do
                local vid_id
                vid_id=$(echo "$url" | grep -oE '[?&]v=([A-Za-z0-9_-]+)' | sed 's/[?&]v=//' || echo "$url")
                if ! echo "$archived_ids" | grep -qF "$vid_id" 2>/dev/null; then
                    echo "$url"
                fi
            done < "$FAILED_FILE.tmp2" > "$FAILED_FILE"
        else
            mv "$FAILED_FILE.tmp2" "$FAILED_FILE"
        fi
        rm -f "$FAILED_FILE.tmp" "$FAILED_FILE.tmp2"
    else
        rm -f "$FAILED_FILE.tmp"
        > "$FAILED_FILE"
    fi

    # ── Summary ───────────────────────────────────────────────────
    echo ""
    echo -e "${CYAN}${BOLD}  ╔═══════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}  ║         Download Summary          ║${RESET}"
    echo -e "${CYAN}${BOLD}  ╚═══════════════════════════════════╝${RESET}"
    echo ""

    local final_downloaded=0
    if [[ -f "$ARCHIVE_FILE" ]]; then
        final_downloaded=$(wc -l < "$ARCHIVE_FILE" | tr -d ' ')
    fi

    local new_downloads=$((final_downloaded - already_downloaded))
    local failed_count=0
    if [[ -f "$FAILED_FILE" && -s "$FAILED_FILE" ]]; then
        failed_count=$(wc -l < "$FAILED_FILE" | tr -d ' ')
    fi

    echo -e "  ${GREEN}✓ Downloaded this session:${RESET}  $new_downloads"
    echo -e "  ${BLUE}↻ Total archived:${RESET}          $final_downloaded / $total_videos"

    if [[ $failed_count -gt 0 ]]; then
        echo -e "  ${RED}✗ Failed:${RESET}                  $failed_count"
        echo -e "  ${DIM}  Run with --retry-failed to re-attempt them${RESET}"
    else
        echo -e "  ${GREEN}✓ Failed:${RESET}                  0"
    fi

    echo ""
    if [[ "$final_downloaded" -ge "$total_videos" ]] && [[ $failed_count -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}🎉 All done! Your MP3s are in:${RESET}"
        echo -e "  ${BOLD}$OUTPUT_DIR/$playlist_title/${RESET}"
    fi
    echo ""
}

# ─── Parse Arguments ─────────────────────────────────────────────────

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -r|--range)
                PLAYLIST_START="$2"
                PLAYLIST_END="$3"
                shift 3
                ;;
            -q|--quality)
                AUDIO_QUALITY="$2"
                shift 2
                ;;
            --rate-limit)
                RATE_LIMIT="$2"
                shift 2
                ;;
            --concurrent)
                CONCURRENT_FRAGS="$2"
                shift 2
                ;;
            --sleep)
                SLEEP_MIN="$2"
                SLEEP_MAX="$3"
                shift 3
                ;;
            --retries)
                MAX_RETRIES="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --status)
                STATUS_ONLY=true
                shift
                ;;
            --retry-failed)
                RETRY_FAILED=true
                shift
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${RESET}"
                echo "Run with --help for usage info."
                exit 1
                ;;
            *)
                PLAYLIST_URL="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$PLAYLIST_URL" ]]; then
        usage
        echo -e "${RED}Error: Playlist URL is required.${RESET}"
        exit 1
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────

main() {
    parse_args "$@"
    print_banner
    check_dependencies

    if $DRY_RUN; then
        do_dry_run
    elif $STATUS_ONLY; then
        do_status
    elif $RETRY_FAILED; then
        do_retry_failed
    else
        do_download
    fi
}

main "$@"
