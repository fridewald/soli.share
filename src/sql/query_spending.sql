-- name: GetSpending :one
SELECT * FROM spending WHERE id = ? LIMIT 1;

-- name: GetSpendings :many
SELECT * FROM spending;


-- name: CreateSpending :one
INSERT INTO spending (
 id,
 amount_in_cent,
 name,
 manage_key
) VALUES (?, ?, ?, ?) RETURNING *;

-- name: NewPledge :exec
INSERT INTO participation (
  id ,
  spending_id ,
  amount_in_cent,
  participant_name)
 VALUES (?, ?, ?, ?);


-- name: GetPledges :many
SELECT * FROM participation p  WHERE p.spending_id = ?;
