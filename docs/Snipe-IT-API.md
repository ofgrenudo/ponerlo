### Snipe-IT /hardware/byserial/:serial [GET]

This will get the devices information and return it as a JSON object with an option of a 200 OK, with a possibility of a Validation Error, or a 401 Unauthorized.

### Snipe-IT /hardware [POST]

https://snipe-it.readme.io/reference/hardware-create

asset_tag: String,
status_id: int32,
model_id: int32,
name: String,
serial: String,

Can Return either a 200 OK, with a possibility of a Validation Error, or a 401 Unauthorized.