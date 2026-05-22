-- name: GetSession :one
SELECT * FROM session WHERE id = ? LIMIT 1;


-- name: CreateSession :one
INSERT INTO session (
 id,
 amount_in_cent
) VALUES (?, ?) RETURNING *;
