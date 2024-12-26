
use std::{default, ops::RangeInclusive, sync::{Arc, Mutex}, time::Instant};

use mesh::Mesh;
use tobj;

use camera::Camera;
use eframe::{egui, egui_glow, glow::{self, HasContext, RIGHT}};
use egui::{mutex, Margin, Style};
use nalgebra::{Vector2, Vector3};

mod shader;
use shader::ShaderProgram;

mod mesh;


mod camera;


fn main() -> eframe::Result{
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([420.0, 600.0]).with_position([100.0, 100.0]),
        multisampling: 4,
        renderer: eframe::Renderer::Glow,
        depth_buffer: 16,
        ..Default::default()
    };
    eframe::run_native(
        "MeshView",
        options,
        Box::new(|cc| Ok(Box::new(App::new(cc)))),
    )
}


// Main App UI

struct App {
    mesh: Arc<Mutex<Mesh>>,
    camera: Arc<Mutex<Camera>>,
    shader_program: Arc<Mutex<ShaderProgram>>,
    value: f32,
    angle: (f32, f32, f32),
    speed: f32,
    sphere_pos: Vector3<f32>,
    start_time: Instant
}

impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::TopBottomPanel::top("Top Panel")
            .frame(egui::Frame { inner_margin: 
                Margin { 
                    left: (10.0), right: (10.0), top: (8.0), bottom: (8.0) 
                }, 
                ..egui::Frame::default()
            })
            .show(ctx, |_| ());

        

        egui::TopBottomPanel::bottom("Bottom Panel")
            .frame(egui::Frame { inner_margin: 
                Margin { 
                    left: (10.0), right: (10.0), top: (8.0), bottom: (8.0) 
                }, 
                ..egui::Frame::default()
            })
            .show(ctx, |ui|  {
                ui.collapsing("Camera Controls", |ui| {
                    ui.label("Position");
                    ui.horizontal(|ui| {
                        ui.add(egui::DragValue::new(&mut self.camera.lock().unwrap().pos.x));
                        ui.add(egui::DragValue::new(&mut self.camera.lock().unwrap().pos.y));
                        ui.add(egui::DragValue::new(&mut self.camera.lock().unwrap().pos.z));
                    });
                    ui.label("Rotation");
                    ui.horizontal(|ui| {
                        ui.add(egui::DragValue::new(&mut self.angle.0));
                        ui.add(egui::DragValue::new(&mut self.angle.1));
                        ui.add(egui::DragValue::new(&mut self.angle.2));
                    });
                    ui.label("Speed");
                    ui.horizontal(|ui| {
                        ui.add(egui::Slider::new(&mut self.speed, RangeInclusive::new(0.0, 20.0)));
                    });
                });

                ui.label("Sphere Position");
                ui.horizontal(|ui| {
                    ui.add(egui::DragValue::new(&mut self.sphere_pos.x));
                    ui.add(egui::DragValue::new(&mut self.sphere_pos.y));
                    ui.add(egui::DragValue::new(&mut self.sphere_pos.z));
                });
            });

        egui::CentralPanel::default().show(ctx, |ui| {
            egui::Frame::canvas(ui.style()).show(ui, |ui| {
                self.custom_painting(ui);
            });
        });


        // update logic
        let rot = nalgebra::Rotation3::from_euler_angles(
            self.angle.0.to_radians(), 
            self.angle.1.to_radians(), 
            self.angle.2.to_radians()
        );

        // MOVEMENT HANDLER 
        {
            if ctx.input(|i| i.key_down(egui::Key::W)) {
                let mut cam = self.camera.lock().unwrap();
                let look = cam.look;
                cam.pos += look * 0.01 * self.speed;
            }
            if ctx.input(|i| i.key_down(egui::Key::S)) {
                let mut cam = self.camera.lock().unwrap();
                let look = cam.look;
                cam.pos += look * -0.01 * self.speed;
            }
    
            if ctx.input(|i| i.key_down(egui::Key::A)) {
                let mut cam = self.camera.lock().unwrap();
                let right = cam.right;
                cam.pos += right * -0.01 * self.speed;
            }
    
            if ctx.input(|i| i.key_down(egui::Key::D)) {
                let mut cam = self.camera.lock().unwrap();
                let right = cam.right;
                cam.pos += right * 0.01 * self.speed;
            }
    
            if ctx.input(|i| i.key_down(egui::Key::Q)) {
                let mut cam = self.camera.lock().unwrap();
                let up = cam.get_up_vec() ;
                cam.pos += up * -0.01 * self.speed;
            }
            
            if ctx.input(|i| i.key_down(egui::Key::E)) {
                let mut cam = self.camera.lock().unwrap();
                let up = cam.get_up_vec() ;
                cam.pos += up * 0.01 * self.speed;
            }
    
        }

        let look = rot * Vector3::new(0.0, 0.0, -1.0);
        let right = rot * Vector3::new(1.0, 0.0, 0.0);
        self.camera.lock().unwrap().right = right;
        self.camera.lock().unwrap().look = look;
        
        ctx.request_repaint();
    }
}


impl App {
    fn new(cc: &eframe::CreationContext<'_>) -> Self {
        let gl = cc
            .gl
            .as_ref()
            .expect("You need to run eframe with the glow backend");

        let mesh = Mesh::new(&gl, 
            [
                Vector3::new(-1.0, -1.0, 0.0), 
                Vector3::new(-1.0, 1.0, 0.0),
                Vector3::new(1.0, -1.0, 0.0),
                Vector3::new(1.0, 1.0, 0.0)
            ].to_vec(), 
        [0, 1, 2, 1, 2, 3].to_vec(),
            (0..6).map(|_| Vector2::new(0.0, 0.0)).collect::<Vec<Vector2<f32>>>().to_vec(),
            false
        );

        let shader_program = ShaderProgram::new(gl, "src/main.vert.glsl", "src/main.frag.glsl");
        
        let camera = Camera::default();
        
        Self { 
            mesh: Arc::new(Mutex::new(mesh)), 
            shader_program: Arc::new(Mutex::new(shader_program)),
            camera: Arc::new(Mutex::new(camera)),
            value: 0.0,
            angle: (0.0, 0.0, 0.0),
            speed: 1.0,
            sphere_pos: Vector3::new(0.0, 0.0, 0.0),
            start_time: Instant::now()
        }
    }

    fn custom_painting(&mut self, ui : &mut egui::Ui) {
        let w = ui.available_width();
        let h = ui.available_height();

        let (rect, response) =
            ui.allocate_exact_size(egui::vec2(w, h) , egui::Sense::drag());

        self.camera.lock().unwrap().aspect_ratio = w/h;

        let elapsed = self.start_time.elapsed();


        let shader_program = self.shader_program.clone();
        let mesh = self.mesh.clone();
        let camera = self.camera.clone();

        self.angle.0 += response.drag_motion().y * -0.1;
        self.angle.1 += response.drag_motion().x * -0.1;

        let value = self.value;

        let sphere_pos = self.sphere_pos;
        let time = self.start_time.elapsed().as_secs_f32() / 4.00 + 0.0;

        let callback = egui::PaintCallback {
            rect,
            callback: std::sync::Arc::new(egui_glow::CallbackFn::new(move |_info, painter| {
                shader_program.lock().unwrap().paint(painter.gl(), &mesh.lock().unwrap(), &camera.lock().unwrap(), |gl, program| {
                    unsafe {
                        gl.uniform_3_f32(
                            gl.get_uniform_location(program, "u_SpherePos").as_ref(), sphere_pos.x, sphere_pos.y, sphere_pos.z
                        );

                        gl.uniform_1_f32(
                            gl.get_uniform_location(program, "u_Time").as_ref(),
                            time
                        );
                    }
                });
            })),
        };
        ui.painter().add(callback);
    }
}