use nalgebra::{Matrix4, Orthographic3, Perspective3, Vector3};

pub struct Camera {
    pub pos : Vector3<f32>,
    pub look : Vector3<f32>,
    pub right: Vector3<f32>,
    fov : f32,
    pub aspect_ratio : f32
}   


impl Camera{
    pub fn new(pos : Vector3<f32>, look : Vector3<f32>, right: Vector3<f32>, fov : f32, aspect_ratio : f32) -> Self {
        Self {
            pos,
            look,
            right,
            fov,
            aspect_ratio
        }
    }

    pub fn default() -> Self {
        Self::new(
            Vector3::new(0.0, 0.0, 10.0),
            Vector3::new(0.0, 0.0, -1.0), //forward look vector
            Vector3::new(1.0, 0.0, 0.0), //right look vector
            45.0,
            1.0
        )
    }

    pub fn get_up_vec(& self) -> Vector3<f32> {
        self.right.cross(&self.look).normalize()
    }

    pub fn get_proj_view_mat(&self) -> Matrix4<f32> {
        let persp = Perspective3::new(self.aspect_ratio, self.fov, 1.0, 100.0).to_homogeneous();
        let _ortho = Orthographic3::new(-1.0, 1.0, -1.0, 1.0, 1.0, 100.0).to_homogeneous();

        let up = self.get_up_vec();

        let view_orient = Matrix4::new(
            self.right.x, self.right.y, self.right.z, 0.0, 
            up.x, up.y, up.z, 0.0, 
            -self.look.x, -self.look.y, -self.look.z, 0.0, 
            0.0, 0.0, 0.0, 1.0
        );

        let view_translate = Matrix4::new(
            1.0, 0.0, 0.0, -self.pos.x, 
            0.0, 1.0, 0.0, -self.pos.y, 
            0.0, 0.0, 1.0, -self.pos.z, 
            0.0, 0.0, 0.0, 1.0
        );

        persp * (view_orient * view_translate)
    }
}