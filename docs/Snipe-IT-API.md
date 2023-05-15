### Snipe-IT /hardware/byserial/:serial [GET]

This will get the devices information and return it as a JSON object with an option of a 200 OK, with a possibility of a Validation Error, or a 401 Unauthorized.

Sample Returned Object

```json
{
  "total": 1,
  "rows": [
    {
      "id": 647,
      "name": "CNM-STF-JWIN02",
      "asset_tag": "123456",
      "serial": "1XQPGK2",
      "model": {
        "id": 33,
        "name": "Desktop Percision Tower 5810"
      },
      "byod": false,
      "model_number": "5810",
      "eol": null,
      "asset_eol_date": null,
      "status_label": {
        "id": 10,
        "name": "Repurposed (Active Recycled)",
        "status_type": "deployable",
        "status_meta": "deployed"
      },
      "category": {
        "id": 2,
        "name": "Desktop"
      },
      "manufacturer": null,
      "supplier": null,
      "notes": "Windows 11 Desktop Tower. Allows for access to windows environment etc.",
      "order_number": null,
      "company": null,
      "location": {
        "id": 4,
        "name": "Center For New Media"
      },
      "rtd_location": {
        "id": 4,
        "name": "Center For New Media"
      },
      "image": null,
      "qr": "https://stockpile.kvcc.dom/uploads/barcodes/qr-123456-647.png",
      "alt_barcode": null,
      "assigned_to": {
        "id": 1,
        "username": "jwintersbro",
        "name": "Joshua Winters-Brown",
        "first_name": "Joshua",
        "last_name": "Winters-Brown",
        "email": "jwintersbro@kvcc.edu",
        "employee_number": null,
        "type": "user"
      },
      "warranty_months": null,
      "warranty_expires": null,
      "created_at": {
        "datetime": "2023-04-21 16:42:56",
        "formatted": "2023-04-21 04:42 PM"
      },
      "updated_at": {
        "datetime": "2023-04-21 20:21:57",
        "formatted": "2023-04-21 08:21 PM"
      },
      "last_audit_date": null,
      "next_audit_date": null,
      "deleted_at": null,
      "purchase_date": null,
      "age": "",
      "last_checkout": {
        "datetime": "2023-04-21 20:03:38",
        "formatted": "2023-04-21 08:03 PM"
      },
      "expected_checkin": null,
      "purchase_cost": null,
      "checkin_counter": 2,
      "checkout_counter": 3,
      "requests_counter": 0,
      "user_can_checkout": false,
      "custom_fields": {},
      "available_actions": {
        "checkout": true,
        "checkin": true,
        "clone": true,
        "restore": false,
        "update": true,
        "delete": false
      }
    }
  ]
}
```

### Snipe-IT /hardware [POST]

https://snipe-it.readme.io/reference/hardware-create

asset_tag: String,
status_id: int32,
model_id: int32,
name: String,
serial: String,

Can Return either a 200 OK, with a possibility of a Validation Error, or a 401 Unauthorized.