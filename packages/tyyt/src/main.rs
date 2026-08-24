mod adblock;
mod app;
mod config;
mod player;
mod tray;
mod ui;
mod youtube;

use tracing_subscriber::EnvFilter;

fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("tyyt=info")),
        )
        .init();

    libadwaita::init().expect("failed to initialize libadwaita");

    let app = app::TyytApplication::new();
    app.run();
}
