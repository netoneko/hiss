use clap::Parser;
use std::path::PathBuf;

use ratatui::{DefaultTerminal, Frame, layout::Size};
use ratatui_image::{Image, Resize, picker::Picker, protocol::Protocol};

#[derive(Parser, Debug)]
struct Args {
    #[arg(short, long)]
    path: PathBuf,
}

struct App {
    args: Args,
}

fn main() -> color_eyre::Result<(), Box<dyn std::error::Error>> {
    //color_eyre::install()?;

    let args = Args::parse();
    println!("path provided {:?}", args.path);
    let app = App { args: args };

    let app_fn = app_builder(&app);

    ratatui::run(app_fn)?;
    Ok(())
}

fn app_builder(
    app: &App,
) -> fn(terminal: &mut DefaultTerminal) -> Result<(), Box<dyn std::error::Error>> {
    let app_fn = |terminal: &mut DefaultTerminal| -> Result<(), Box<dyn std::error::Error>> {
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
                break;
            }
        }
        Ok(())
    };

    Ok(&app_fn)
}
