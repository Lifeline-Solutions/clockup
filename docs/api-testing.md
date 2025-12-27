# Clockup API Testing Guide

This short guide shows how to test the Clockup API with Postman or curl.

## Base URL
- Development: `http://localhost:3000`

## Authentication
- Header: `Authorization: Bearer <api_token>` (returned by Login)
- Required for: `POST /api/v1/clock`, `POST /api/v1/logout`

## Endpoints
- Login: `POST /api/v1/login`
- Logout: `POST /api/v1/logout`
- Clock (in/out): `POST /api/v1/clock`

## Request/Response Examples

### Login (get token)
Request:
```bash
curl -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "your-password"
  }'
```
Response:
```json
{ "api_token": "abcdef1234567890..." }
```

### Clock (toggle in/out via QR)
Headers:
- `Authorization: Bearer <api_token>`

Request:
```bash
curl -X POST http://localhost:3000/api/v1/clock \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "qr_token": "ORG_QR_TOKEN",
    "latitude": 1.234567,
    "longitude": 36.789012
  }'
```
Response:
```json
{
  "message": "Clock in successful",
  "event_type": "clock_in",
  "distance": 12,
  "occurred_at": "2025-12-27T16:13:12Z",
  "late": false,
  "early_leave": false
}
```
Notes:
- First call toggles to `clock_in`; next call toggles to `clock_out`.
- `late` is true if clocking in after work start.
- `early_leave` is true if clocking out before work end.
- If organisation is deactivated, response is `403` with `{ "error": "Organisation is deactivated" }`.
- If outside geofence or duplicate event, response is `422` with an error message.
- If QR token is invalid, response is `404`.

### Logout
Headers:
- `Authorization: Bearer <api_token>`

Request:
```bash
curl -X POST http://localhost:3000/api/v1/logout \
  -H "Authorization: Bearer YOUR_TOKEN"
```
Response:
```json
{ "message": "Logged out" }
```

## Finding `qr_token` and Coordinates
- `qr_token`: visible on the organisation show page (masked). Use the actual token value associated with the organisation.
- Coordinates: use the organisation’s latitude/longitude from the show page. For a successful clock, send values within the organisation’s `allowed_radius_meters`.

## Postman Tips
- Create three requests in a collection: Login, Clock, Logout.
- Save the `api_token` from Login into a Postman variable and reference it as `{{api_token}}` in the Authorization header.
