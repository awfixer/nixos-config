use std::env;
use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());

    // --- youtube-dl (yt-dlp) ---
    let yt_bin = manifest_dir.join("vendor/bin/youtube-dl");
    let yt_src = manifest_dir.join("vendor/youtube-dl");

    println!("cargo:rerun-if-changed=vendor/bin/youtube-dl");
    println!("cargo:rerun-if-changed=vendor/youtube-dl/yt_dlp/version.py");
    println!("cargo:rerun-if-env-changed=TYYT_YOUTUBE_DL");

    if yt_bin.is_file() {
        println!("cargo:rustc-env=TYYT_VENDOR_YT_BIN={}", yt_bin.display());
    }
    if yt_src.is_dir() {
        println!("cargo:rustc-env=TYYT_VENDOR_YT_SRC={}", yt_src.display());
    }

    // --- mpv ---
    let mpv_bin = manifest_dir.join("vendor/bin/mpv");
    println!("cargo:rerun-if-changed=vendor/bin/mpv");
    println!("cargo:rerun-if-env-changed=TYYT_MPV");

    if mpv_bin.is_file() {
        println!("cargo:rustc-env=TYYT_VENDOR_MPV_BIN={}", mpv_bin.display());
    }
}
