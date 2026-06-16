-- name: GetSession :one
SELECT * FROM session WHERE id = ? LIMIT 1;

-- name: GetSessions :many
SELECT * FROM session;


-- name: CreateSession :one
INSERT INTO session (
 id,
 amount_in_cent,
 name
) VALUES (?, ?, ?) RETURNING *;
