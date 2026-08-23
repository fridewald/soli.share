import radiate
import soli

pub fn main() {
  let _ =
    radiate.new()
    |> radiate.add_dir("src")
    |> radiate.start()
  soli.start("http://localhost:8000")
}
