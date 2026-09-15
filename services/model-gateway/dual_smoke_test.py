from __future__ import annotations

from datetime import date, timedelta
import os

from pyfao56_dual_runner import (
    DualKcBasalProfile,
    DualKcInitialState,
    DualKcStation,
    DualKcWeatherDay,
    PyFao56DualKcShadowRequest,
)
from dual_app import run_pyfao56_dual_kc_shadow


def weather_day(day: date, kcb: float = 0.8) -> DualKcWeatherDay:
    return DualKcWeatherDay(
        date=day,
        solar_radiation_mj_m2=20.0,
        tmax_c=30.0,
        tmin_c=16.0,
        dew_point_c=10.0,
        wind_m_s=2.0,
        rain_mm=0.0,
        kcb=kcb,
    )


def main() -> None:
    os.environ["MODEL_GATEWAY_ENV"] = "development"
    os.environ.pop("MODEL_GATEWAY_SHARED_KEY", None)

    start = date(2026, 9, 15)
    payload = PyFao56DualKcShadowRequest(
        field_id="dual-smoke-field",
        station=DualKcStation(
            latitude=37.05,
            elevation_m=850.0,
            wind_height_m=2.0,
        ),
        basal_profile=DualKcBasalProfile(
            initial=0.20,
            mid=0.85,
            end=0.60,
        ),
        state=DualKcInitialState(
            theta_fc=0.30,
            theta_wp=0.12,
            root_depth_m=1.0,
            depletion_fraction_p=0.50,
            ze_m=0.15,
            initial_de_mm=10.0,
            initial_dr_mm=50.0,
            canopy_height_m=2.5,
            canopy_cover_fraction=0.50,
        ),
        rew_values_mm=[8.0, 12.0],
        days=[
            weather_day(start),
            weather_day(start + timedelta(days=1)),
            weather_day(start + timedelta(days=2)),
        ],
    )

    result = run_pyfao56_dual_kc_shadow(payload, None)

    assert result["ok"] is True
    assert result["production_authority"] is False
    assert result["shadow_scope"] == "dual_kc_water_balance_bounded_rew"
    assert result["initial_state_injection"]["enabled"] is True
    assert result["initial_state_injection"]["surface_depletion_mm"] == 10.0
    assert result["initial_state_injection"]["root_depletion_mm"] == 50.0
    assert result["uncertainty"]["scenario_count"] == 2
    assert result["uncertainty"]["rew_values_mm"] == [8.0, 12.0]
    assert len(result["scenarios"]) == 2

    for scenario in result["scenarios"]:
        assert scenario["basal_profile"] == {"initial": 0.2, "mid": 0.85, "end": 0.6}
        assert len(scenario["days"]) == 3
        assert scenario["initial_state"]["surface_depletion_mm"] == 10.0
        assert scenario["initial_state"]["root_depletion_mm"] == 50.0
        assert scenario["days"][0]["reference_et_mm"] is not None
        assert scenario["days"][0]["actual_et_mm"] is not None
        assert scenario["days"][0]["surface_depletion_mm"] is not None
        assert scenario["days"][0]["root_depletion_mm"] is not None

    print(
        "dual-kc smoke ok",
        {
            "engine_version": result.get("engine_version"),
            "scenario_count": result["uncertainty"]["scenario_count"],
            "scope": result["shadow_scope"],
        },
    )


if __name__ == "__main__":
    main()
