use ratatui::{DefaultTerminal, Frame, layout::Size};
use ratatui_image::{Image, picker::Picker, protocol::Protocol, Resize};

fn main() -> color_eyre::Result<(), Box<dyn std::error::Error>> {
   //color_eyre::install()?;
   ratatui::run(app2)?;
   Ok(())
}

fn app2(terminal: &mut DefaultTerminal) -> Result<(), Box<dyn std::error::Error>> {
    let img_name = "./public/onyxia.jpg";
    println!("rendering {}", img_name);

    let dyn_img = image::ImageReader::open(img_name)?.decode()?;
    println!("image {} exists", img_name);
    println!("dimentions {}x{}", dyn_img.width(), dyn_img.height());

    let picker = Picker::from_query_stdio()?;
    let font_size = picker.font_size();
    let size = Size::new(
        dyn_img.width().div_ceil(font_size.width as u32) as u16,
        dyn_img.height().div_ceil(font_size.height as u32) as u16,
    );

    let image = picker.new_protocol(dyn_img, size, Resize::Fit(None))?;

    loop {
      terminal.draw(|f| {
        let image = Image::new(&image);
        f.render_widget(image, f.area());
      });
      if crossterm::event::read()?.is_key_press() {
          break
      }
    }
    Ok(())
}

