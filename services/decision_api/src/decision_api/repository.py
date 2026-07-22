from __future__ import annotations

import json
from decimal import Decimal
from typing import Any

from .errors import ConditionalWriteFailed


class DynamoRepository:
    def __init__(self, table: Any) -> None:
        self._table = table

    def claim_nonce(self, key_id: str, nonce: str, expires_epoch: int) -> None:
        try:
            self._table.put_item(
                Item={"pk": f"AUTH#{key_id}", "sk": f"NONCE#{nonce}", "ttl": expires_epoch},
                ConditionExpression="attribute_not_exists(pk) AND attribute_not_exists(sk)",
            )
        except Exception as exc:
            if getattr(exc, "response", {}).get("Error", {}).get("Code") == "ConditionalCheckFailedException":
                raise ConditionalWriteFailed() from exc
            raise

    def get_decision(self, request_id: str) -> dict[str, Any] | None:
        result = self._table.get_item(Key={"pk": f"REQUEST#{request_id}", "sk": "DECISION"}, ConsistentRead=True)
        item = result.get("Item")
        if not item:
            return None
        return {"body_hash": item["body_hash"], "response": json.loads(item["response_json"])}

    def save_decision(self, request_id: str, body_hash: str, response: dict[str, Any], ttl: int,
                      audit: dict[str, Any] | None = None) -> None:
        item = {
            "pk": f"REQUEST#{request_id}", "sk": "DECISION", "body_hash": body_hash,
            "response_json": json.dumps(response, separators=(",", ":"), ensure_ascii=True),
            "decision": response["decision"], "reason_code": response["reason_code"],
            "idempotency_expires_at": ttl,
        }
        if audit:
            candidate_id = audit.get("trade_candidate_id")
            if isinstance(candidate_id, str):
                item["gsi1pk"] = f"CANDIDATE#{candidate_id}"
                item["gsi1sk"] = f"DECISION#{response['created_at']}#{request_id}"
            item.update({
                f"audit_{key}": Decimal(str(value)) if isinstance(value, float) else value
                for key, value in audit.items()
            })
        try:
            self._table.put_item(
                Item=item,
                ConditionExpression="attribute_not_exists(pk) AND attribute_not_exists(sk)",
            )
        except Exception as exc:
            if getattr(exc, "response", {}).get("Error", {}).get("Code") == "ConditionalCheckFailedException":
                raise ConditionalWriteFailed() from exc
            raise

    def save_trade_event(self, source_id: str, event: dict[str, Any], body_hash: str) -> bool:
        sort_key = f"EVENT#{event['timestamp']}#{event['event_id']}"
        item = {
            "pk": f"SOURCE#{source_id}", "sk": sort_key,
            "gsi1pk": f"CANDIDATE#{event['trade_candidate_id']}", "gsi1sk": sort_key,
            "entity_type": "TRADE_EVENT", "event_id": event["event_id"],
            "trade_candidate_id": event["trade_candidate_id"], "request_id": event["request_id"],
            "ea_id": event["ea_id"], "event_time": event["timestamp"],
            "event_type": event["event_type"], "symbol": event["symbol"],
            "payload_json": json.dumps(event["payload"], separators=(",", ":"), ensure_ascii=True),
            "body_hash": body_hash,
        }
        try:
            self._table.put_item(
                Item=item,
                ConditionExpression="attribute_not_exists(pk) AND attribute_not_exists(sk)",
            )
            return True
        except Exception as exc:
            if getattr(exc, "response", {}).get("Error", {}).get("Code") != "ConditionalCheckFailedException":
                raise
            existing = self._table.get_item(
                Key={"pk": item["pk"], "sk": item["sk"]}, ConsistentRead=True
            ).get("Item")
            if existing and existing.get("body_hash") == body_hash:
                return False
            raise ConditionalWriteFailed() from exc
