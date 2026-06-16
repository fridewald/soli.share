import radiate
import soli

pub fn main() {
  let _ =
    radiate.new()
    |> radiate.add_dir("src")
    |> radiate.start()
  soli.main()
}
