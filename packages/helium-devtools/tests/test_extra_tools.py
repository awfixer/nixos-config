import pytest

from helium_devtools.errors import HeliumDisconnectedError
from helium_devtools.ext_hub import ExtHub
from helium_devtools.extra_tools import helium_list_tabs, helium_status


@pytest.mark.asyncio
async def test_status_when_down():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        status = helium_status(hub)
        assert status == {"connected": False, "tabs": 0, "attached": [], "lastError": None}
    finally:
        await hub.stop()


@pytest.mark.asyncio
async def test_list_tabs_when_down_raises():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        with pytest.raises(HeliumDisconnectedError):
            await helium_list_tabs(hub)
    finally:
        await hub.stop()
