-- Only h4nr-craft tables are read or written. Snapshots bind retries to admitted terms.
Craft.Db = {}
local D = Craft.Db
function D.Migrate()
    DB.awaitReady(30000)
    DB.exec([[CREATE TABLE IF NOT EXISTS h4nr_craft_orders (
        id CHAR(36) NOT NULL PRIMARY KEY,
        character_id CHAR(36) NOT NULL,
        request_id VARCHAR(80) NOT NULL,
        location_id VARCHAR(50) NOT NULL,
        snapshot LONGTEXT NOT NULL,
        state VARCHAR(20) NOT NULL DEFAULT 'preparing',
        ready_at BIGINT NOT NULL DEFAULT 0,
        reward_xp INT UNSIGNED NOT NULL DEFAULT 0,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        collected_at TIMESTAMP NULL,
        UNIQUE KEY request_identity (character_id, request_id),
        KEY queue (character_id, state)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin]])
end
function D.Uuid()
    return DB.value('SELECT UUID()')
end
local function decode(row)
    if row then
        row.snapshot = json.decode(row.snapshot)
    end
    return row
end
function D.Request(characterId, requestId)
    return decode(
        DB.one('SELECT * FROM h4nr_craft_orders WHERE character_id=? AND request_id=?', characterId, requestId)
    )
end
function D.Order(characterId, id)
    return decode(DB.one('SELECT * FROM h4nr_craft_orders WHERE character_id=? AND id=?', characterId, id))
end
function D.List(characterId)
    local rows = DB.query(
        "SELECT * FROM h4nr_craft_orders WHERE character_id=? AND state<>'collected' ORDER BY created_at",
        characterId
    ) or {}
    for _, row in ipairs(rows) do
        decode(row)
    end
    return rows
end
function D.Xp(characterId)
    return tonumber(
        DB.value(
            "SELECT COALESCE(SUM(reward_xp),0) FROM h4nr_craft_orders WHERE character_id=? AND state='collected'",
            characterId
        )
    ) or 0
end
function D.Insert(id, characterId, requestId, locationId, snapshot)
    DB.insert(
        [[INSERT INTO h4nr_craft_orders
        (id,character_id,request_id,location_id,snapshot,reward_xp) VALUES (?,?,?,?,?,?)]],
        id,
        characterId,
        requestId,
        locationId,
        json.encode(snapshot),
        snapshot.Xp
    )
    return D.Order(characterId, id)
end
function D.Queue(order)
    -- Retry never shortens the server clock: the first successful transition wins.
    DB.exec(
        "UPDATE h4nr_craft_orders SET state='queued',ready_at=? WHERE id=? AND state='preparing'",
        os.time() + order.snapshot.Seconds,
        order.id
    )
    return D.Order(order.character_id, order.id)
end
function D.Collected(order)
    DB.exec(
        "UPDATE h4nr_craft_orders SET state='collected',collected_at=CURRENT_TIMESTAMP WHERE id=? AND state='queued'",
        order.id
    )
end
