HELIUM_DISCONNECTED = (
    "Helium not connected; open Helium and wait for the Grok DevTools extension to attach.\n"
    "If Helium is already open, restart it so --load-extension picks up ~/.local/share/helium-devtools/extension."
)


class HeliumDisconnectedError(Exception):
    def __init__(self) -> None:
        super().__init__(HELIUM_DISCONNECTED)
