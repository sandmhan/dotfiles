#!/usr/bin/env python3
"""Wger Fitness Data Exporter for Prometheus.

Polls the Wger REST API for fitness metrics (body weight, workouts,
nutrition, body measurements) and exposes them as Prometheus gauges
at /metrics on port 9101.
"""

import logging
import os
import sys
import time
from datetime import date, datetime, timedelta

import requests
from prometheus_client import Gauge, Counter, start_http_server, REGISTRY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger("wger-exporter")

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
WGER_URL = os.environ.get("WGER_URL", "http://wger:8000")
WGER_API_TOKEN = os.environ.get("WGER_API_TOKEN", "")
POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", "300"))  # seconds
EXPORTER_PORT = int(os.environ.get("EXPORTER_PORT", "9101"))

# ---------------------------------------------------------------------------
# Metrics definitions
# ---------------------------------------------------------------------------

# Body weight
body_weight_lb = Gauge(
    "wger_body_weight_lb",
    "Most recent body weight entry in pounds",
)
body_weight_entries_total = Counter(
    "wger_body_weight_entries_total",
    "Total number of body weight entries",
)

# Workouts
workouts_logged_total = Counter(
    "wger_workouts_logged_total",
    "Total number of workout log entries",
)
workout_sessions_total = Counter(
    "wger_workout_sessions_total",
    "Total number of workout sessions",
)
workout_volume_lb = Gauge(
    "wger_workout_volume_lb_today",
    "Total workout volume (weight x reps) in pounds for today",
)
workout_sessions_week = Gauge(
    "wger_workout_sessions_week",
    "Number of workout sessions in the last 7 days",
)

# Nutrition
nutrition_calories_today = Gauge(
    "wger_nutrition_calories_today",
    "Total calories logged today",
)
nutrition_protein_g_today = Gauge(
    "wger_nutrition_protein_g_today",
    "Protein in grams logged today",
)
nutrition_carbs_g_today = Gauge(
    "wger_nutrition_carbs_g_today",
    "Carbohydrates in grams logged today",
)
nutrition_fat_g_today = Gauge(
    "wger_nutrition_fat_g_today",
    "Fat in grams logged today",
)

# Body measurements
body_measurement_cm = Gauge(
    "wger_body_measurement_cm",
    "Most recent body measurement in centimeters",
    ["category"],
)

# Exporter health
scrape_errors_total = Counter(
    "wger_exporter_scrape_errors_total",
    "Total number of failed API scrapes",
)
last_successful_scrape = Gauge(
    "wger_exporter_last_successful_scrape_timestamp",
    "Unix timestamp of last successful scrape",
)

# ---------------------------------------------------------------------------
# API helpers
# ---------------------------------------------------------------------------

def api_get(path, params=None):
    """Make an authenticated GET request to the Wger API."""
    headers = {"Authorization": f"Token {WGER_API_TOKEN}"}
    url = f"{WGER_URL}/api/v2/{path}"
    resp = requests.get(url, headers=headers, params=params, timeout=30)
    resp.raise_for_status()
    return resp.json()


def api_get_all(path, params=None):
    """Paginate through all results for a Wger API endpoint."""
    if params is None:
        params = {}
    params["format"] = "json"
    params["limit"] = 100
    params["offset"] = 0
    results = []
    while True:
        data = api_get(path, params)
        results.extend(data.get("results", []))
        if not data.get("next"):
            break
        params["offset"] += params["limit"]
    return results


# ---------------------------------------------------------------------------
# Metric collection functions
# ---------------------------------------------------------------------------

def collect_body_weight():
    """Fetch the most recent body weight entry."""
    try:
        entries = api_get("weightentry", {"ordering": "-date", "limit": 1})
        results = entries.get("results", [])
        if results:
            weight = float(results[0]["weight"])
            body_weight_lb.set(weight)
            log.debug("Body weight: %.1f lb", weight)

        # Total count
        all_entries = api_get("weightentry", {"limit": 1})
        body_weight_entries_total._value.set(all_entries.get("count", 0))
    except Exception as e:
        log.warning("Failed to collect body weight: %s", e)
        scrape_errors_total.inc()


def collect_workouts():
    """Fetch workout session and log data."""
    try:
        today = date.today().isoformat()
        week_ago = (date.today() - timedelta(days=7)).isoformat()

        # Workout sessions this week
        sessions = api_get("workoutsession", {
            "date__gte": week_ago,
            "limit": 100,
        })
        session_results = sessions.get("results", [])
        workout_sessions_week.set(len(session_results))

        # Total sessions
        all_sessions = api_get("workoutsession", {"limit": 1})
        workout_sessions_total._value.set(all_sessions.get("count", 0))

        # Today's workout volume (weight * reps)
        logs = api_get("workoutlog", {
            "date": today,
            "limit": 100,
        })
        log_results = logs.get("results", [])
        volume = 0.0
        for entry in log_results:
            weight = float(entry.get("weight", 0) or 0)
            reps = int(entry.get("reps", 0) or 0)
            volume += weight * reps
        workout_volume_lb.set(volume)

        # Total logs
        all_logs = api_get("workoutlog", {"limit": 1})
        workouts_logged_total._value.set(all_logs.get("count", 0))

        log.debug("Workout sessions (week): %d, volume today: %.1f lb",
                  len(session_results), volume)
    except Exception as e:
        log.warning("Failed to collect workouts: %s", e)
        scrape_errors_total.inc()


def collect_nutrition():
    """Fetch today's nutrition diary entries."""
    try:
        today = date.today().isoformat()
        diary = api_get_all("nutritiondiary", {"date": today})

        calories = 0.0
        protein = 0.0
        carbs = 0.0
        fat = 0.0

        for entry in diary:
            calories += float(entry.get("energy", 0) or 0)
            protein += float(entry.get("protein", 0) or 0)
            carbs += float(entry.get("carbohydrates", 0) or 0)
            fat += float(entry.get("fat", 0) or 0)

        nutrition_calories_today.set(calories)
        nutrition_protein_g_today.set(protein)
        nutrition_carbs_g_today.set(carbs)
        nutrition_fat_g_today.set(fat)

        log.debug("Nutrition today: %.0f kcal, %.1fg protein, %.1fg carbs, %.1fg fat",
                  calories, protein, carbs, fat)
    except Exception as e:
        log.warning("Failed to collect nutrition: %s", e)
        scrape_errors_total.inc()


def collect_measurements():
    """Fetch the most recent body measurement for each category."""
    try:
        categories = api_get_all("measurement-category")

        for cat in categories:
            cat_id = cat["id"]
            cat_name = cat["name"].lower().replace(" ", "_")

            measurements = api_get("measurement", {
                "category": cat_id,
                "ordering": "-date",
                "limit": 1,
            })
            results = measurements.get("results", [])
            if results:
                value = float(results[0]["value"])
                body_measurement_cm.labels(category=cat_name).set(value)
                log.debug("Measurement %s: %.1f cm", cat_name, value)
    except Exception as e:
        log.warning("Failed to collect measurements: %s", e)
        scrape_errors_total.inc()


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

def collect_all():
    """Run all metric collectors."""
    log.info("Collecting wger fitness metrics...")
    collect_body_weight()
    collect_workouts()
    collect_nutrition()
    collect_measurements()
    last_successful_scrape.set(time.time())
    log.info("Collection complete.")


def main():
    if not WGER_API_TOKEN:
        log.error("WGER_API_TOKEN environment variable is required")
        sys.exit(1)

    log.info("Starting wger exporter on port %d (poll interval: %ds)", EXPORTER_PORT, POLL_INTERVAL)
    log.info("Wger API URL: %s", WGER_URL)

    start_http_server(EXPORTER_PORT)

    while True:
        try:
            collect_all()
        except Exception as e:
            log.error("Unexpected error during collection: %s", e)
            scrape_errors_total.inc()
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
