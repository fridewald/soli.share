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

-- name: NewParticipation :exec
INSERT INTO participation (
  id ,
  session_id ,
  amount_in_cent,
  participant_name)
 VALUES (?, ?, ?, ?);


-- name: GetParticipation :many
SELECT * FROM participation p  WHERE p.session_id = ?;
