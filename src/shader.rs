// pub mod Shader {
    use eframe::glow::{self, Context};

    use crate::{camera::Camera, mesh::Mesh};

    
    pub struct ShaderProgram {
        pub program : glow::Program,
        _vert_shader: glow::Shader,
        _frag_shader: glow::Shader
    }


    impl ShaderProgram {
        pub fn new(gl: &glow::Context, vs_path: &str, fs_path: &str) -> Self {
            use glow::HasContext as _;

            unsafe {
                let program = gl.create_program().expect("Cannot create program");

                let (vertex_shader_source, fragment_shader_source) = (
                    std::fs::read_to_string(vs_path).unwrap(),
                    std::fs::read_to_string(fs_path).unwrap(),
                );

                let shader_sources = [
                    (glow::VERTEX_SHADER, vertex_shader_source),
                    (glow::FRAGMENT_SHADER, fragment_shader_source),
                ];

                let shaders: Vec<_> = shader_sources
                .iter()
                .map(|(shader_type, shader_source)| {
                    let shader = gl
                        .create_shader(*shader_type)
                        .expect("Cannot create shader");
                    gl.shader_source(shader, &format!("{shader_source}"));
                    gl.compile_shader(shader);
                    assert!(
                        gl.get_shader_compile_status(shader),
                        "Failed to compile {shader_type}: {}",
                        gl.get_shader_info_log(shader)
                    );
                    gl.attach_shader(program, shader);
                    shader
                })
                .collect();


                // assert status of the shader
                gl.link_program(program);
                assert!(
                    gl.get_program_link_status(program),
                    "{}",
                    gl.get_program_info_log(program)
                );

                for shader in shaders.iter() {
                    gl.detach_shader(program, *shader);
                    gl.delete_shader(*shader);
                }

                Self {
                    program,
                    _vert_shader: shaders[0],
                    _frag_shader: shaders[1]
                }
            }
        }


        pub fn _destroy(&self, gl: &glow::Context) {
            use glow::HasContext as _;
            unsafe {
                gl.delete_program(self.program);
            }
        }

        pub fn paint<F: FnOnce(&Context, glow::Program)>(&self, gl: &glow::Context, mesh: &Mesh, camera: &Camera, set_uniforms: F) 
        {
            use glow::HasContext as _;

            unsafe {
                
                gl.clear(glow::DEPTH_BUFFER_BIT);
                gl.depth_func(glow::LESS);
                gl.enable(glow::DEPTH_TEST);

                gl.use_program(Some(self.program));

                gl.uniform_matrix_4_f32_slice(
                    gl.get_uniform_location(self.program, "u_ViewProj").as_ref(),
                    false, 
                    camera.get_proj_view_mat().as_slice()
                );

                gl.uniform_matrix_4_f32_slice(
                    gl.get_uniform_location(self.program, "u_InvViewProj").as_ref(),
                    false, 
                    camera.get_proj_view_mat().try_inverse().unwrap().as_slice()
                );

                gl.uniform_1_f32(
                    gl.get_uniform_location(self.program, "aspectRatio").as_ref(),
                    camera.aspect_ratio);

                gl.uniform_3_f32(
                    gl.get_uniform_location(self.program, "u_CamPos").as_ref(), 
                    camera.pos.x, camera.pos.y, camera.pos.z
                );

                set_uniforms(gl, self.program);

                gl.bind_vertex_array(Some(mesh.vertex_array));
                gl.draw_elements(if mesh.wireframe {glow::LINES} else {glow::TRIANGLES}, mesh.index_buffer_size as i32, glow::UNSIGNED_INT, 0);
            }
        }
    }

    