from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database.connection import get_db
from ..api.dependencies import get_current_user
from ..models.db_models import User
from ..services import cricket_data_service

series_router = APIRouter(prefix="/series", tags=["series"])
players_router = APIRouter(prefix="/players", tags=["players"])
rankings_router = APIRouter(prefix="/rankings", tags=["rankings"])


# ── Series ────────────────────────────────────────────────────────────────────

@series_router.get("")
async def get_series(
    status: str = None,
    current_user: User = Depends(get_current_user),
):
    try:
        return await cricket_data_service.get_series_list(status)
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@series_router.get("/{series_id}/matches")
async def get_series_matches(
    series_id: str,
    current_user: User = Depends(get_current_user),
):
    try:
        return await cricket_data_service.get_series_matches(series_id)
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@series_router.get("/{series_id}/points-table")
async def get_points_table(
    series_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Points table is computed from match results stored in DB
    from ..models.db_models import Match, Team
    matches = (
        db.query(Match)
        .filter(Match.series_id == series_id, Match.status == "completed")
        .all()
    )
    table: dict = {}
    for m in matches:
        for tid in [m.team1_id, m.team2_id]:
            if tid not in table:
                team = db.query(Team).filter(Team.id == tid).first()
                table[tid] = {
                    "team_id": tid,
                    "team_name": team.name if team else tid,
                    "logo_url": team.logo_url if team else None,
                    "played": 0, "won": 0, "lost": 0,
                    "tied": 0, "no_result": 0, "points": 0,
                    "net_run_rate": 0.0,
                }
        if m.match_data:
            winner_id = m.match_data.get("winner_team_id")
            for tid in [m.team1_id, m.team2_id]:
                table[tid]["played"] += 1
                if winner_id == tid:
                    table[tid]["won"] += 1
                    table[tid]["points"] += 2
                elif winner_id:
                    table[tid]["lost"] += 1
                else:
                    table[tid]["no_result"] += 1
                    table[tid]["points"] += 1

    return sorted(table.values(), key=lambda x: (-x["points"], -x["net_run_rate"]))


# ── Players ───────────────────────────────────────────────────────────────────

@players_router.get("/search")
async def search_players(
    q: str,
    current_user: User = Depends(get_current_user),
):
    try:
        return await cricket_data_service.search_players(q)
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@players_router.get("/{player_id}")
async def get_player(
    player_id: str,
    current_user: User = Depends(get_current_user),
):
    try:
        return await cricket_data_service.get_player_info(player_id)
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


# ── Rankings ──────────────────────────────────────────────────────────────────

@rankings_router.get("")
async def get_rankings(
    type: str = "batsmen",
    format: str = "T20",
    current_user: User = Depends(get_current_user),
):
    """
    Rankings are fetched from the cricket data provider.
    type: batsmen | bowlers | all-rounders | teams
    format: T20 | ODI | Test
    """
    try:
        # Delegate to cricket data service
        # The actual endpoint depends on your licensed provider
        from ..services.cricket_data_service import _get
        data = await _get("/rankings", params={"type": type, "format": format})
        return data.get("data", [])
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))
