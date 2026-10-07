import unittest

from backend.app.main import validate_gtfs


class GtfsValidationTests(unittest.TestCase):
    def base_feed(self):
        return {
            "agency.txt": [{"agency_id": "A", "agency_name": "Agency"}],
            "stops.txt": [{
                "stop_id": "S1", "stop_name": "Stop 1",
                "stop_lat": "14.7000", "stop_lon": "-17.4500"
            }],
            "routes.txt": [{
                "route_id": "R1", "route_type": "3",
                "route_short_name": "1", "route_long_name": "Route 1"
            }],
            "calendar.txt": [{
                "service_id": "WK", "monday": "1", "tuesday": "1",
                "wednesday": "1", "thursday": "1", "friday": "1",
                "saturday": "1", "sunday": "1",
                "start_date": "20260101", "end_date": "20261231"
            }],
            "trips.txt": [{
                "route_id": "R1", "service_id": "WK", "trip_id": "T1"
            }],
            "stop_times.txt": [{
                "trip_id": "T1", "arrival_time": "08:00:00",
                "departure_time": "08:01:00", "stop_id": "S1",
                "stop_sequence": "1"
            }],
        }

    def test_valid_feed_has_no_errors(self):
        self.assertEqual(validate_gtfs(self.base_feed()), [])

    def test_missing_required_file_is_rejected(self):
        feed = self.base_feed()
        del feed["stops.txt"]
        errors = validate_gtfs(feed)
        self.assertTrue(any("missing required files" in e for e in errors))

    def test_invalid_stop_time_is_rejected(self):
        feed = self.base_feed()
        feed["stop_times.txt"][0]["departure_time"] = "08:61:00"
        errors = validate_gtfs(feed)
        self.assertTrue(any("invalid departure_time" in e for e in errors))

    def test_unknown_route_reference_is_rejected(self):
        feed = self.base_feed()
        feed["trips.txt"][0]["route_id"] = "UNKNOWN"
        errors = validate_gtfs(feed)
        self.assertTrue(any("route_id=UNKNOWN" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
