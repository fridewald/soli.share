import formal/form.{type Form}
import gleam/float

pub type CreateSpend {
  CreateSpend(name: String, amount_in_cent: Int)
}

pub const name_field_name = "name"

pub const amount_in_cent_field_name = "amount_in_cent"

pub fn create_spend_form() -> Form(CreateSpend) {
  form.new({
    use name <- form.field(name_field_name, {
      form.parse_string |> form.check_not_empty
    })
    use amount <- form.field(amount_in_cent_field_name, {
      form.parse_float |> form.check_float_more_than(0.0)
    })

    let amount_in_cent = float.truncate(amount *. 100.0)

    form.success(CreateSpend(name:, amount_in_cent:))
  })
}
