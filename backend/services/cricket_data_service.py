"""
Cricket Data Service — API Adapter Layer

This module abstracts the cricket data provider so it can be swapped
without changing any other part of the application.

Supported providers (configure via CRICKET_API_KEY and CRICKET_API_BASE_URL):
  - CricAPI (https://www.cricapi.com)
  - SportMonks Cricket (https://www.sportmonks.com/cricket-api)
  - RapidAPI Cricket Live Data

Replace the methods below with the actual provider's endpoint structure.
"""

import httpx
from typing import Optional
from ..utils.config import get_settings

settings = get_settings()

_HEADERS = {"apikey": settings.cricket_api_key}


async def _get(path: str, params: Optional[dict] = None) -> dict:
    async with httpx.AsyncClient(base_url=settings.cricket_api_base_url, timeout=10) as client:
        resp = await client.get(path, headers=_HEADERS, params=params or {})
        resp.raise_for_status()
        return resp.json()


async def get_live_matches() -> list:
    data = await _get("/currentMatches")
    return data.get("data", [])


async def get_upcoming_matches() -> list:
    data = await _get("/matches", params={"status": "upcoming"})
    return data.get("data", [])


async def get_completed_matches() -> list:
    data = await _get("/matches", params={"status": "completed"})
    return data.get("data", [])


async def get_match_scorecard(match_id: str) -> dict:
    data = await _get(f"/match_scorecard", params={"id": match_id})
    return data.get("data", {})


async def get_series_list(status: Optional[str] = None) -> list:
    params = {}
    if status:
        params["status"] = status
    data = await _get("/series", params=params)
    return data.get("data", [])


async def get_series_matches(series_id: str) -> list:
    data = await _get("/series_info", params={"id": series_id})
    return data.get("data", {}).get("matchList", [])


async def get_player_info(player_id: str) -> dict:
    data = await _get("/players_info", params={"id": player_id})
    return data.get("data", {})


async def search_players(query: str) -> list:
    data = await _get("/players", params={"search": query})
    return data.get("data", [])
